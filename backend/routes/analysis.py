import io
import json
from datetime import date, datetime

from fastapi import APIRouter, UploadFile, File, Form, HTTPException
import asyncio
from google.genai import types
from PIL import Image as PILImage, UnidentifiedImageError

from prompts import (
    FILLIN_PROMPT_TEMPLATE,
    LAYER_1_VISION_EXTRACTION_PROMPT,
    LAYER_2_EVIDENCE_FUSION_PROMPT,
    LAYER_3_SCORING_AND_PLAN_PROMPT,
)
from services.genai_client import client, genai_model, safety_config
from services.firebase import upload_case_image_to_firebase


router = APIRouter()


@router.post("/analyze-fillin")
async def fill_in(
    case_id: str = Form(...),
    record_id: str = Form(...),
    image: UploadFile = File(...)
):
    try:
        print(f"analyze-fillin received: case_id={case_id}, record_id={record_id}, filename={image.filename}, content_type={image.content_type}")
        image_content = await image.read()
        print(f"analyze-fillin image bytes: {len(image_content)}")
        try:
            img = PILImage.open(io.BytesIO(image_content))
        except UnidentifiedImageError:
            raise HTTPException(status_code=400, detail="Invalid image file")

        image_id = f"{case_id}-{record_id}-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}.jpg"
        content_type = image.content_type or "image/jpeg"
        print(f"analyze-fillin upload start: image_id={image_id}")
        image_url = upload_case_image_to_firebase(
            file_content=image_content,
            case_id=case_id,
            record_id=record_id,
            filename=image_id,
            content_type=content_type,
        )
        print(f"analyze-fillin upload done: image_url={image_url}")

        full_prompt = f"{FILLIN_PROMPT_TEMPLATE}"
        print("analyze-fillin sending to gemini")

        response = client.models.generate_content(
            model=genai_model,
            contents=[full_prompt, img],
            config=types.GenerateContentConfig(
                safety_settings=safety_config,
                temperature=0.2,
                response_mime_type="application/json"
            )
        )

        if response.candidates:
            data_dict = json.loads(response.text)
            raw_text = response.text.strip().replace("```json", "").replace("```", "")
            data_dict = json.loads(raw_text)
            return {
                "status": "success",
                "case_id": case_id,
                "record_id": record_id,
                "analysis": data_dict,
                "image_id": image_id,
                "image_url": image_url,
            }
        else:
            return {
                "status": "blocked",
                "reason": str(response.prompt_feedback.block_reason)
            }

    except Exception as e:
        import traceback
        print(traceback.format_exc())
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/analyze-wound")
async def analyze_wound(
    patient_data: str = Form(...),
    image: UploadFile = File(...)
):
    try:
        structured_data = json.loads(patient_data)

        image_content = await image.read()
        img = PILImage.open(io.BytesIO(image_content))
        img = img.convert("RGB")
        img.thumbnail((1024, 1024), PILImage.LANCZOS)

        def parse_model_json(text: str) -> dict:
            try:
                return json.loads(text)
            except json.JSONDecodeError as e:
                raise ValueError(f"Model did not return valid JSON: {e}\nRaw output: {text}")

        async def call_gemini_json(contents):
            max_wait_seconds = 60
            delays = [10, 15, 30, 60]
            waited = 0

            for attempt in range(len(delays) + 1):
                try:
                    response = client.models.generate_content(
                        model=genai_model,
                        contents=contents,
                        config=types.GenerateContentConfig(
                            safety_settings=safety_config,
                            temperature=0.2,
                            response_mime_type="application/json"
                        )
                    )

                    if not response.candidates:
                        return {
                            "blocked": True,
                            "reason": str(getattr(response.prompt_feedback, "block_reason", "unknown"))
                        }

                    if not response.text:
                        raise ValueError("Model returned empty response.")

                    return parse_model_json(response.text)
                except Exception as e:
                    msg = str(e)
                    if "RESOURCE_EXHAUSTED" not in msg and "429" not in msg:
                        raise
                    if attempt >= len(delays) or waited >= max_wait_seconds:
                        raise
                    delay = delays[attempt]
                    if waited + delay > max_wait_seconds:
                        delay = max_wait_seconds - waited
                    waited += delay
                    await asyncio.sleep(delay)
            raise HTTPException(status_code=500, detail="Gemini retry exhausted")

        layer1_input = f"""
Today is {date.today()}.

{LAYER_1_VISION_EXTRACTION_PROMPT}
        """.strip()

        layer1_result = await call_gemini_json([layer1_input, img])
        if isinstance(layer1_result, dict) and layer1_result.get("blocked"):
            return {"status": "blocked", "reason": layer1_result.get("reason")}

        layer2_payload = {
            "structured_clinical_data": structured_data,
            "layer1_image_assessment": layer1_result
        }

        layer2_input = f"""
Today is {date.today()}.

{LAYER_2_EVIDENCE_FUSION_PROMPT}

=== INPUT JSON ===
{json.dumps(layer2_payload, ensure_ascii=False, indent=2)}
        """.strip()

        layer2_result = await call_gemini_json([layer2_input])
        if isinstance(layer2_result, dict) and layer2_result.get("blocked"):
            return {"status": "blocked", "reason": layer2_result.get("reason")}

        layer3_input = f"""
Today is {date.today()}.

{LAYER_3_SCORING_AND_PLAN_PROMPT}

=== INPUT JSON ===
{json.dumps(layer2_result, ensure_ascii=False, indent=2)}
        """.strip()

        layer3_result = await call_gemini_json([layer3_input])
        if isinstance(layer3_result, dict) and layer3_result.get("blocked"):
            return {"status": "blocked", "reason": layer3_result.get("reason")}

        return {
            "status": "success",
            "analysis": json.dumps(layer3_result, ensure_ascii=False)
        }

    except json.JSONDecodeError as e:
        raise HTTPException(status_code=400, detail=f"Invalid patient_data JSON: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
