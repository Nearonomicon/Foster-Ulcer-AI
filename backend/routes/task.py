import json
from datetime import datetime

from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from fastapi.encoders import jsonable_encoder
from firebase_admin import firestore

from services.firebase import db, upload_case_image_to_firebase


router = APIRouter()


@router.post("/tasks_list")
async def list_tasks(payload: dict | None = None):
    try:
        payload = payload or {}
        limit = payload.get("limit", 200)

        if not isinstance(limit, int):
            try:
                limit = int(limit)
            except Exception:
                limit = 200

        if limit < 1:
            limit = 1
        if limit > 500:
            limit = 500
        #go though cases ondered by case_update_at DESC
        cases_query = db.collection("cases").order_by(
            "case_updated_at", direction=firestore.Query.DESCENDING
        ).limit(limit)
        cases_docs = cases_query.stream()
        #for each cases store data and patient_id
        cases = []
        patient_ids = set()
        for doc in cases_docs:
            data = doc.to_dict() or {}
            data["case_id"] = data.get("case_id") or doc.id
            cases.append(data)
            if data.get("patient_id"):
                patient_ids.add(data["patient_id"])
        #for each patient_id map list of patient_name
        patient_info_map = {}
        if patient_ids:
            refs = [db.collection("patients").document(pid) for pid in patient_ids]
            for snap in db.get_all(refs):
                if snap.exists:
                    pdata = snap.to_dict() or {}
                    patient_info_map[snap.id] = {
                        "patient_name": pdata.get("patient_name"),
                        "photo_url": pdata.get("photo_url"),
                    }
        #For each case get the information of current_treatment_plan 
        tasks = []
        for case in cases:
            current_treatment = case.get("current_treatment_plan") or {}
            task_list = current_treatment.get("plan_tasks") or []
            if not isinstance(task_list, list) or not task_list:
                continue
            patient_id = case.get("patient_id")
            patient_info = patient_info_map.get(patient_id, {})
            tasks.append({
                "case_id": case.get("case_id"),
                "patient_id": patient_id,
                "patient_name": patient_info.get("patient_name"),
                "photo_url": patient_info.get("photo_url"),
                "current_record_id": case.get("current_record_id"),
                "current_plan_id": case.get("current_plan_id"),
                "current_treatment": current_treatment,
            })

        return {"status": "success", "current_treatment_plan": jsonable_encoder(tasks)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/task_detail")
async def task_detail(payload: dict | None = None):
    try:
        payload = payload or {}
        case_id = payload.get("case_id")
        task_index = payload.get("task_index")

        if not case_id:
            raise HTTPException(status_code=400, detail="case_id is required")

        case_ref = db.collection("cases").document(case_id)
        case_snapshot = case_ref.get()
        if not case_snapshot.exists:
            raise HTTPException(status_code=404, detail="Case not found")

        case_data = case_snapshot.to_dict() or {}
        patient_id = case_data.get("patient_id")
        patient_name = None
        if patient_id:
            patient_ref = db.collection("patients").document(patient_id)
            patient_snapshot = patient_ref.get()
            if patient_snapshot.exists:
                patient_data = patient_snapshot.to_dict() or {}
                patient_name = patient_data.get("patient_name")

        current_treatment = case_data.get("current_treatment_plan") or {}
        plan_tasks = current_treatment.get("plan_tasks") or []

        selected_task = None
        if task_index is not None:
            try:
                index = int(task_index)
            except Exception:
                raise HTTPException(status_code=400, detail="task_index must be an integer")
            if index < 0 or index >= len(plan_tasks):
                raise HTTPException(status_code=404, detail="task_index out of range")
            selected_task = plan_tasks[index]

        response = {
            "status": "success",
            "case_id": case_data.get("case_id") or case_id,
            "patient_id": patient_id,
            "patient_name": patient_name,
            "current_treatment": jsonable_encoder(current_treatment),
        }
        if selected_task is not None:
            response["task"] = jsonable_encoder(selected_task)
        else:
            response["plan_tasks"] = jsonable_encoder(plan_tasks)
        return response
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/task_update")
async def task_update(
    case_id: str = Form(...),
    plan_id: str | None = Form(None),
    updates: str = Form(...),
    images: list[UploadFile] | None = File(None),
):
    try:
        try:
            updates_payload = json.loads(updates) if updates else []
        except json.JSONDecodeError as e:
            raise HTTPException(status_code=400, detail=f"Invalid updates JSON: {e}")

        if not isinstance(updates_payload, list) or not updates_payload:
            raise HTTPException(status_code=400, detail="updates must be a non-empty list")

        allowed_fields = {"status", "task_due", "completed_at", "task_photo_url", "task_text"}

        case_ref = db.collection("cases").document(case_id)
        case_snapshot = case_ref.get()
        if not case_snapshot.exists:
            raise HTTPException(status_code=404, detail="Case not found")

        case_data = case_snapshot.to_dict() or {}
        current_plan_id = case_data.get("current_plan_id")
        if plan_id and current_plan_id and plan_id != current_plan_id:
            raise HTTPException(status_code=400, detail="plan_id does not match current plan")

        current_treatment = case_data.get("current_treatment_plan") or {}
        plan_tasks = current_treatment.get("plan_tasks") or []
        if not isinstance(plan_tasks, list) or not plan_tasks:
            raise HTTPException(status_code=404, detail="No plan_tasks found")

        image_list = images or []
        if image_list and len(image_list) not in (0, len(updates_payload)):
            raise HTTPException(status_code=400, detail="images count must match updates count")

        updates_by_id: dict[str, dict] = {}
        for idx, entry in enumerate(updates_payload):
            if not isinstance(entry, dict):
                raise HTTPException(status_code=400, detail="each update must be an object")
            task_id = entry.get("task_id")
            entry_updates = entry.get("updates") if isinstance(entry.get("updates"), dict) else {}
            if not task_id:
                raise HTTPException(status_code=400, detail="task_id is required for each update")
            sanitized = {k: v for k, v in entry_updates.items() if k in allowed_fields}
            if not sanitized:
                continue
            if image_list:
                image = image_list[idx]
                image_content = await image.read()
                if image_content:
                    filename = f"{case_id}-{task_id}-{int(datetime.utcnow().timestamp())}.jpg"
                    content_type = image.content_type or "image/jpeg"
                    image_url = upload_case_image_to_firebase(
                        file_content=image_content,
                        case_id=case_id,
                        record_id=f"tasks/{task_id}",
                        filename=filename,
                        content_type=content_type,
                    )
                    sanitized["task_photo_url"] = image_url
            updates_by_id[task_id] = sanitized

        if not updates_by_id:
            raise HTTPException(status_code=400, detail="No valid fields in updates")

        updated_tasks = []
        updated_task_ids = set()
        for task in plan_tasks:
            task_data = dict(task) if isinstance(task, dict) else {}
            task_id = task_data.get("task_id")
            if task_id and task_id in updates_by_id:
                task_data.update(updates_by_id[task_id])
                updated_task_ids.add(task_id)
            updated_tasks.append(task_data)

        missing = [tid for tid in updates_by_id.keys() if tid not in updated_task_ids]
        if missing:
            raise HTTPException(status_code=404, detail=f"task_id not found in current plan: {missing}")

        current_treatment["plan_tasks"] = updated_tasks
        batch = db.batch()
        batch.set(case_ref, {
            "current_treatment_plan": current_treatment,
            "case_updated_at": firestore.SERVER_TIMESTAMP,
        }, merge=True)

        current_record_id = case_data.get("current_record_id")
        if not current_plan_id or not current_record_id:
            raise HTTPException(status_code=404, detail="Current plan/record not found for case")

        plan_ref = case_ref.collection("records").document(current_record_id).collection("plan_versions").document(current_plan_id)
        for task_id, update_fields in updates_by_id.items():
            task_ref = plan_ref.collection("tasks").document(task_id)
            update_payload = dict(update_fields)
            update_payload["updated_at"] = firestore.SERVER_TIMESTAMP
            batch.set(task_ref, update_payload, merge=True)

        batch.commit()

        return {
            "status": "success",
            "case_id": case_id,
            "plan_id": current_plan_id,
            "updated_task_ids": sorted(updated_task_ids),
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
