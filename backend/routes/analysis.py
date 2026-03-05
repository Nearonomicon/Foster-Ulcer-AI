import io
import json
from datetime import date, datetime

from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from google.genai import types
from PIL import Image as PILImage, UnidentifiedImageError

from prompts import FILLIN_PROMPT_TEMPLATE, ANALYZE_PROMPT_TEMPLATE
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
        print(f"Sending this payload for wound analyzing: {patient_data}")
        image_content = await image.read()
        img = PILImage.open(io.BytesIO(image_content))

        full_prompt = f"Today is {date.today()}\n\n{ANALYZE_PROMPT_TEMPLATE}\n\n===DATA INPUT===\n{patient_data}"

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
            print(response.text)
            return {"status": "success", "analysis": response.text}
        else:
            return {
                "status": "blocked",
                "reason": str(response.prompt_feedback.block_reason)
            }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
