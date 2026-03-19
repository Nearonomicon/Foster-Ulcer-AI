import io
import json
from datetime import date, datetime
from urllib.request import urlopen

from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.encoders import jsonable_encoder
import asyncio
from firebase_admin import firestore
from google.genai import types
from PIL import Image as PILImage, UnidentifiedImageError

from prompts import (
    FILLIN_PROMPT_TEMPLATE,
    LAYER_1_VISION_EXTRACTION_PROMPT,
    LAYER_2_EVIDENCE_FUSION_PROMPT,
    LAYER_3_SCORING_AND_PLAN_PROMPT,
    HEALING_PROGRESS_PROMPT,
)
from services.genai_client import client, genai_model, safety_config
from services.firebase import upload_case_image_to_firebase, db


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
        try:
            record_ref = db.collection("cases").document(case_id).collection("records").document(record_id)
            record_ref.set({
                "image": {"image_folder_url": image_url},
                "record_updated_at": firestore.SERVER_TIMESTAMP,
            }, merge=True)
            case_ref = db.collection("cases").document(case_id)
            case_doc = case_ref.get()
            if case_doc.exists:
                case_data = case_doc.to_dict() or {}
                if case_data.get("current_record_id") == record_id:
                    case_ref.set({
                        "current_image": {"image_folder_url": image_url},
                        "case_updated_at": firestore.SERVER_TIMESTAMP,
                    }, merge=True)
        except Exception as e:
            print(f"analyze-fillin warning: failed to update record image url: {e}")

        full_prompt = f"{FILLIN_PROMPT_TEMPLATE}"
        print("analyze-fillin sending to gemini")

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
                    return response
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

        response = await call_gemini_json([full_prompt, img])

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
    payload_data: str = Form(...),
    image: UploadFile = File(...)
):
    try:
        structured_data = json.loads(payload_data)
        case_ref = structured_data.get("case_ref") or {}
        case_id = case_ref.get("case_id")
        record_id = case_ref.get("record_id")
        patient_id = case_ref.get("patient_id")

        if case_id and record_id:
            try:
                nurse_reviewed = structured_data.get("nurse_reviewed") or {}
                record_update = {
                    "patient_id": patient_id,
                    "status": "ANALYZING",
                    "vital_signs": nurse_reviewed.get("vital_signs"),
                    "wound_detail": nurse_reviewed.get("wound_detail"),
                    "ischemia": nurse_reviewed.get("ischemia"),
                    "infection": nurse_reviewed.get("infection"),
                    "neuropathy": nurse_reviewed.get("neuropathy"),
                    "sinbad": nurse_reviewed.get("sinbad"),
                    "lab_results": nurse_reviewed.get("lab_results"),
                    "vascular": nurse_reviewed.get("vascular"),
                    "gangrene_extent": nurse_reviewed.get("gangrene_extent"),
                    "record_updated_at": firestore.SERVER_TIMESTAMP,
                }

                record_ref = db.collection("cases").document(case_id).collection("records").document(record_id)
                record_ref.set(record_update, merge=True)

                case_update = {
                    "patient_id": patient_id,
                    "status": "ANALYZING",
                    "case_updated_at": firestore.SERVER_TIMESTAMP,
                    "current_record_id": record_id,
                    "current_vital_signs": record_update.get("vital_signs"),
                    "current_wound_detail": record_update.get("wound_detail"),
                    "current_ischemia": record_update.get("ischemia"),
                    "current_infection": record_update.get("infection"),
                    "current_neuropathy": record_update.get("neuropathy"),
                    "current_sinbad": record_update.get("sinbad"),
                    "current_lab_results": record_update.get("lab_results"),
                    "current_vascular": record_update.get("vascular"),
                    "current_gangrene_extent": record_update.get("gangrene_extent"),
                }
                db.collection("cases").document(case_id).set(case_update, merge=True)
            except Exception as e:
                print(f"analyze-wound warning: failed to store nurse_reviewed data: {e}")

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

        if not isinstance(layer3_result, dict):
            raise HTTPException(status_code=500, detail="Model returned unexpected analyze-wound output")

        ai_analysis = layer3_result.get("AI_analysis")
        treatment_plan = layer3_result.get("treatment_plan")

        if case_id and record_id:
            try:
                record_ai_update = {
                    "analysis": ai_analysis if isinstance(ai_analysis, dict) else None,
                    "treatment_plan": treatment_plan if isinstance(treatment_plan, dict) else None,
                    "task_list": (
                        treatment_plan.get("plan_tasks")
                        if isinstance(treatment_plan, dict)
                        else None
                    ),
                    "record_updated_at": firestore.SERVER_TIMESTAMP,
                }
                record_ref = db.collection("cases").document(case_id).collection("records").document(record_id)
                record_ref.set(record_ai_update, merge=True)

                case_ai_update = {
                    "case_updated_at": firestore.SERVER_TIMESTAMP,
                    "current_analysis": ai_analysis if isinstance(ai_analysis, dict) else None,
                    "current_treatment_plan": treatment_plan if isinstance(treatment_plan, dict) else None,
                }
                db.collection("cases").document(case_id).set(case_ai_update, merge=True)
            except Exception as e:
                print(f"analyze-wound warning: failed to store AI analysis data: {e}")

        return layer3_result

    except json.JSONDecodeError as e:
        raise HTTPException(status_code=400, detail=f"Invalid payload_data JSON: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/analyze-healing")
async def analyze_healing(payload: dict):
    try:
        case_id = payload.get("case_id")
        if not case_id:
            raise HTTPException(status_code=400, detail="case_id is required")

        records_query = db.collection("cases").document(case_id).collection("records").order_by(
            "record_created_at", direction=firestore.Query.ASCENDING
        )
        records_docs = records_query.stream()
        records = [doc.to_dict() for doc in records_docs]
        records_json = jsonable_encoder(records)
        # print(records)

        if not records:
            raise HTTPException(status_code=404, detail="No records found for this case")

        def load_image_from_url(image_url: str):
            try:
                with urlopen(image_url, timeout=10) as resp:
                    data = resp.read()
                img = PILImage.open(io.BytesIO(data))
                img = img.convert("RGB")
                img.thumbnail((1024, 1024), PILImage.LANCZOS)
                return img
            except Exception as e:
                print(f"analyze-healing warning: failed to load image {image_url}: {e}")
                return None

        prompt_header = f"""
Today is {date.today()}.

{HEALING_PROGRESS_PROMPT}
        """.strip()

        contents = [prompt_header]
        for idx, rec in enumerate(records_json, start=1):
            record_text = json.dumps(rec, ensure_ascii=False, indent=2)
            contents.append(f"Record {idx} (record_id={rec.get('record_id')}):\n{record_text}")
            image_url = (rec.get("image") or {}).get("image_folder_url")
            if image_url:
                img = load_image_from_url(image_url)
                if img is not None:
                    contents.append(img)

        async def call_gemini_text(contents):
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
                            temperature=0.2
                        )
                    )
                    if not response.candidates:
                        return {
                            "blocked": True,
                            "reason": str(getattr(response.prompt_feedback, "block_reason", "unknown"))
                        }
                    if not response.text:
                        raise ValueError("Model returned empty response.")
                    return response.text
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

        result = await call_gemini_text(contents)
        if isinstance(result, dict) and result.get("blocked"):
            return {"status": "blocked", "reason": result.get("reason"), "records": records_json}

        try:
            latest_record = records_json[-1]
            latest_record_id = latest_record.get("record_id")
            if latest_record_id:
                record_ref = db.collection("cases").document(case_id).collection("records").document(latest_record_id)
                record_ref.set({"healing_progress": result}, merge=True)

            case_ref = db.collection("cases").document(case_id)
            case_ref.set({"current_healing_progress": result}, merge=True)
        except Exception as e:
            print(f"analyze-healing warning: failed to store healing_progress: {e}")

        return {"status": "success", "analysis": result, "records": records_json}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
