import io
import json
import logging
from datetime import date, datetime
from urllib.request import urlopen

from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.encoders import jsonable_encoder
import asyncio
from firebase_admin import firestore
from google.genai import types
from PIL import Image as PILImage, UnidentifiedImageError

from prompts import (
    ANALYZE_TRANSCRIBING_PROMPT,
    FILLIN_PROMPT_TEMPLATE,
    LAYER_1_VISION_EXTRACTION_PROMPT,
    LAYER_2_EVIDENCE_FUSION_PROMPT,
    LAYER_3_SCORING_AND_PLAN_PROMPT,
    HEALING_PROGRESS_PROMPT,
)
from services.genai_client import client, genai_model, safety_config
from services.firebase import upload_case_image_to_firebase, db
from services.notifications import create_doctor_healing_notification


router = APIRouter()
logger = logging.getLogger("foster_ulcer_ai.analysis")
_GEMINI_TIMEOUT_SECONDS = 45


@router.post("/analyze-transcribe")
async def analyze_transcribe(
    case_id: str = Form(...),
    record_id: str = Form(...),
    audio: UploadFile = File(...),
):
    try:
        print(
            f"analyze-transcribe received: case_id={case_id}, record_id={record_id}, "
            f"filename={audio.filename}, content_type={audio.content_type}"
        )

        audio_content = await audio.read()
        if not audio_content:
            raise HTTPException(status_code=400, detail="Audio file is empty")

        content_type = audio.content_type or "audio/mpeg"
        if not content_type.startswith("audio/"):
            raise HTTPException(status_code=400, detail="Invalid audio file")

        prompt = ANALYZE_TRANSCRIBING_PROMPT

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
                            temperature=0.1,
                        ),
                    )
                    if not response.candidates:
                        return {
                            "blocked": True,
                            "reason": str(getattr(response.prompt_feedback, "block_reason", "unknown")),
                        }
                    if not response.text:
                        raise ValueError("Model returned empty response.")
                    return response.text.strip()
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

        audio_part = types.Part.from_bytes(data=audio_content, mime_type=content_type)
        transcript = await call_gemini_text([prompt, audio_part])
        if isinstance(transcript, dict) and transcript.get("blocked"):
            return {"status": "blocked", "reason": transcript.get("reason")}

        return {
            "status": "success",
            "case_id": case_id,
            "record_id": record_id,
            "transcript": transcript,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


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
        request_label = f"case_id={case_id or '-'} record_id={record_id or '-'}"

        logger.info(
            "analyze_wound start %s filename=%s content_type=%s",
            request_label,
            image.filename,
            image.content_type,
        )

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
                logger.warning(
                    "analyze_wound failed to store nurse_reviewed %s error=%s",
                    request_label,
                    e,
                )

        image_content = await image.read()
        if not image_content:
            raise HTTPException(status_code=400, detail="Image file is empty")
        img = PILImage.open(io.BytesIO(image_content))
        img = img.convert("RGB")
        img.thumbnail((1024, 1024), PILImage.LANCZOS)

        def parse_model_json(text: str) -> dict:
            try:
                return json.loads(text)
            except json.JSONDecodeError as e:
                raise ValueError(f"Model did not return valid JSON: {e}\nRaw output: {text}")

        async def call_gemini_json(contents, stage_name: str):
            max_wait_seconds = 60
            delays = [10, 15, 30, 60]
            waited = 0

            for attempt in range(len(delays) + 1):
                try:
                    logger.info(
                        "analyze_wound %s stage=%s attempt=%d gemini_call_start",
                        request_label,
                        stage_name,
                        attempt + 1,
                    )
                    response = await asyncio.wait_for(
                        asyncio.to_thread(
                            client.models.generate_content,
                            model=genai_model,
                            contents=contents,
                            config=types.GenerateContentConfig(
                                safety_settings=safety_config,
                                temperature=0.2,
                                response_mime_type="application/json"
                            ),
                        ),
                        timeout=_GEMINI_TIMEOUT_SECONDS,
                    )
                    logger.info(
                        "analyze_wound %s stage=%s attempt=%d gemini_call_done",
                        request_label,
                        stage_name,
                        attempt + 1,
                    )

                    if not response.candidates:
                        logger.warning(
                            "analyze_wound %s stage=%s blocked reason=%s",
                            request_label,
                            stage_name,
                            getattr(response.prompt_feedback, "block_reason", "unknown"),
                        )
                        return {
                            "blocked": True,
                            "reason": str(getattr(response.prompt_feedback, "block_reason", "unknown"))
                        }

                    if not response.text:
                        raise ValueError("Model returned empty response.")

                    return parse_model_json(response.text)
                except TimeoutError:
                    logger.error(
                        "analyze_wound %s stage=%s timeout_after=%ds",
                        request_label,
                        stage_name,
                        _GEMINI_TIMEOUT_SECONDS,
                    )
                    raise HTTPException(
                        status_code=504,
                        detail=f"Gemini timed out during {stage_name}",
                    )
                except Exception as e:
                    msg = str(e)
                    logger.warning(
                        "analyze_wound %s stage=%s attempt=%d error=%s",
                        request_label,
                        stage_name,
                        attempt + 1,
                        msg,
                    )
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

        layer1_result = await call_gemini_json([layer1_input, img], "layer1_vision")
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

        layer2_result = await call_gemini_json([layer2_input], "layer2_fusion")
        if isinstance(layer2_result, dict) and layer2_result.get("blocked"):
            return {"status": "blocked", "reason": layer2_result.get("reason")}

        layer3_input = f"""
Today is {date.today()}.

{LAYER_3_SCORING_AND_PLAN_PROMPT}

=== INPUT JSON ===
{json.dumps(layer2_result, ensure_ascii=False, indent=2)}
        """.strip()

        layer3_result = await call_gemini_json([layer3_input], "layer3_plan")
        if isinstance(layer3_result, dict) and layer3_result.get("blocked"):
            return {"status": "blocked", "reason": layer3_result.get("reason")}

        if case_id and record_id:
            try:
                analysis_snapshot = layer3_result
                if isinstance(layer3_result, dict) and isinstance(layer3_result.get("AI_analysis"), dict):
                    analysis_snapshot = layer3_result.get("AI_analysis")

                if isinstance(analysis_snapshot, dict):
                    record_ref = db.collection("cases").document(case_id).collection("records").document(record_id)
                    record_ref.set({
                        "analysis": analysis_snapshot,
                        "record_updated_at": firestore.SERVER_TIMESTAMP,
                    }, merge=True)

                    db.collection("cases").document(case_id).set({
                        "current_analysis": analysis_snapshot,
                        "case_updated_at": firestore.SERVER_TIMESTAMP,
                    }, merge=True)
            except Exception as e:
                logger.warning(
                    "analyze_wound failed to store analysis_snapshot %s error=%s",
                    request_label,
                    e,
                )

        logger.info("analyze_wound success %s", request_label)

        return {
            "status": "success",
            "analysis": layer3_result
        }

    except json.JSONDecodeError as e:
        raise HTTPException(status_code=400, detail=f"Invalid payload_data JSON: {str(e)}")
    except Exception as e:
        logger.exception("analyze_wound failed error=%s", e)
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/analyze-healing")
async def analyze_healing(payload: dict):
    try:
        case_id = payload.get("case_id")
        if not case_id:
            raise HTTPException(status_code=400, detail="case_id is required")

        case_ref = db.collection("cases").document(case_id)
        case_snapshot = case_ref.get()
        case_data = case_snapshot.to_dict() if case_snapshot.exists else {}

        records_query = case_ref.collection("records").order_by(
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

        notification_id = None
        try:
            latest_record = records_json[-1]
            latest_record_id = latest_record.get("record_id")
            if latest_record_id:
                record_ref = db.collection("cases").document(case_id).collection("records").document(latest_record_id)
                analysis_id = f"AN-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
                existing_analysis = latest_record.get("analysis")
                analysis_payload = dict(existing_analysis) if isinstance(existing_analysis, dict) else {}
                analysis_payload["healing_progress"] = result

                record_ref.set({
                    "current_healing_progress": result,
                    "status": "DOCTOR_REVIEW",
                    "record_updated_at": firestore.SERVER_TIMESTAMP,
                    "timestamps": {
                        "updated_at": firestore.SERVER_TIMESTAMP,
                        "doctor_review_at": firestore.SERVER_TIMESTAMP,
                    },
                }, merge=True)
                record_ref.collection("analysis_versions").document(analysis_id).set({
                    "analysis_id": analysis_id,
                    "case_id": case_id,
                    "record_id": latest_record_id,
                    "status": "DRAFT",
                    "source": "AI_HEALING",
                    "created_at": firestore.SERVER_TIMESTAMP,
                    "payload": analysis_payload,
                }, merge=True)

            case_ref.set({
                "current_healing_progress": result,
                "status": "DOCTOR_REVIEW",
                "current_record_id": latest_record_id,
                "current_analysis_id": analysis_id if latest_record_id else None,
                "case_updated_at": firestore.SERVER_TIMESTAMP,
            }, merge=True)

            notification_id = None
            if latest_record_id:
                try:
                    patient_id = case_data.get("patient_id")
                    patient_name = None
                    if patient_id:
                        patient_snapshot = db.collection("patients").document(patient_id).get()
                        if patient_snapshot.exists:
                            patient_profile = patient_snapshot.to_dict() or {}
                            patient_name = patient_profile.get("patient_name")

                    urgency_value = case_data.get("urgency")
                    if hasattr(urgency_value, "value"):
                        urgency_value = urgency_value.value

                    notification_id = create_doctor_healing_notification(
                        case_id=case_id,
                        record_id=latest_record_id,
                        patient_id=patient_id,
                        patient_name=patient_name,
                        urgency=urgency_value,
                        assigned_doctor=case_data.get("assigned_doctor"),
                    )
                except Exception as notification_error:
                    print(f"analyze-healing warning: failed to create doctor notification: {notification_error}")
        except Exception as e:
            print(f"analyze-healing warning: failed to store healing_progress: {e}")
        return {
            "status": "success",
            "analysis": result,
            "records": records_json,
            "notification_id": notification_id,
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
