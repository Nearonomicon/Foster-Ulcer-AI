import json
from datetime import date, datetime, timezone
from uuid import uuid4
from fastapi import APIRouter, HTTPException
from fastapi.encoders import jsonable_encoder
from firebase_admin import firestore
from google.cloud.firestore_v1 import FieldFilter

from schemas import (
    CreateCaseRequest,
    UpdateCaseRequest,
    NoWoundAssessmentRequest,
    ResumeCaseRequest,
    RESUMABLE_STATUSES,
    Status,
    Urgency,
    VitalSigns,
    WoundDetail,
    Size,
    Bed,
    Discharge,
    Ischemia,
    Infection,
    Neuropathy,
    Sinbad,
    LabResults,
    Vascular,
    WoundCaseRecord,
    WoundCaseRecordUpdate,
    Timestamps,
    CaseImage,
)
from services.firebase import db
from services.notifications import (
    create_doctor_request_close_notification,
    create_doctor_review_notification,
    create_nurse_plan_issued_notification,
)
from utils import _model_to_dict


router = APIRouter()


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _normalize_datetime(value: object, *, fallback_to_now: bool = True) -> datetime | None:
    if isinstance(value, datetime):
        parsed = value
    elif isinstance(value, str) and value.strip():
        normalized = value.strip().replace("Z", "+00:00")
        parsed = None
        try:
            parsed = datetime.fromisoformat(normalized)
        except ValueError:
            pass
        if parsed is None:
            for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d"):
                try:
                    parsed = datetime.strptime(normalized, fmt)
                    break
                except ValueError:
                    continue
        if parsed is None:
            if fallback_to_now:
                return _utc_now()
            return None
    else:
        if fallback_to_now:
            return _utc_now()
        return None

    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def _current_record_snapshot(record_data: dict) -> dict:
    analysis = record_data.get("analysis") or {}
    healing_progress = record_data.get("current_healing_progress")
    if healing_progress is None and isinstance(analysis, dict):
        healing_progress = analysis.get("healing_progress")

    return {
        "current_timestamps": record_data.get("timestamps"),
        "current_image": record_data.get("image"),
        "current_vital_signs": record_data.get("vital_signs"),
        "current_wound_detail": record_data.get("wound_detail"),
        "current_ischemia": record_data.get("ischemia"),
        "current_infection": record_data.get("infection"),
        "current_neuropathy": record_data.get("neuropathy"),
        "current_sinbad": record_data.get("sinbad"),
        "current_lab_results": record_data.get("lab_results"),
        "current_vascular": record_data.get("vascular"),
        "current_gangrene_extent": record_data.get("gangrene_extent"),
        "current_analysis": record_data.get("analysis"),
        "current_treatment_plan": record_data.get("treatment_plan"),
        "current_healing_progress": healing_progress,
    }


def _merge_non_null(existing: dict | None, incoming: dict | None) -> dict | None:
    if incoming is None:
        return existing
    if existing is None:
        return incoming
    if not isinstance(existing, dict) or not isinstance(incoming, dict):
        return incoming if incoming is not None else existing
    result = dict(existing)
    for key, value in incoming.items():
        if isinstance(value, dict):
            result[key] = _merge_non_null(existing.get(key, {}), value)
        elif value is not None:
            result[key] = value
    return result


def _merge_sections(existing: dict, incoming: dict, keys: list[str]) -> dict:
    merged = dict(incoming)
    for key in keys:
        merged[key] = _merge_non_null(existing.get(key), incoming.get(key))
    return merged


def _is_all_null(value: object) -> bool:
    if value is None:
        return True
    if isinstance(value, dict):
        return all(_is_all_null(v) for v in value.values())
    if isinstance(value, list):
        return all(_is_all_null(v) for v in value)
    return False


def _normalize_plan_tasks_status(tasks: list[dict], status: str) -> list[dict]:
    tasks = _normalize_plan_tasks(tasks)
    normalized_tasks = []
    for task in tasks:
        task_data = dict(task) if isinstance(task, dict) else {}
        task_data["status"] = status
        normalized_tasks.append(task_data)
    return normalized_tasks


def _generate_task_id() -> str:
    return f"TSK-{uuid4().hex[:8].upper()}"


def _normalize_plan_tasks(tasks: list[dict] | None, *, default_source: str | None = None) -> list[dict]:
    normalized_tasks = []
    for idx, task in enumerate(tasks or [], start=1):
        task_data = dict(task) if isinstance(task, dict) else {}
        if not task_data.get("task_id"):
            task_data["task_id"] = _generate_task_id()
        if "completed_at" not in task_data:
            task_data["completed_at"] = None
        if not str(task_data.get("source") or "").strip() and default_source:
            task_data["source"] = default_source
        incoming_order_index = task_data.get("order_index")
        try:
            task_data["order_index"] = int(incoming_order_index)
        except Exception:
            task_data["order_index"] = idx
        normalized_tasks.append(task_data)

    normalized_tasks.sort(key=lambda item: (int(item.get("order_index") or 0), str(item.get("task_id") or "")))
    for idx, task_data in enumerate(normalized_tasks, start=1):
        task_data["order_index"] = idx
    return normalized_tasks


def _get_plan_tasks(treatment_plan: dict | None, fallback_tasks: list | None = None) -> list:
    if isinstance(treatment_plan, dict) and isinstance(treatment_plan.get("plan_tasks"), list):
        return treatment_plan.get("plan_tasks") or []
    return fallback_tasks or []


def _task_doc_payload(task: dict, *, case_id: str, record_id: str, plan_id: str, timestamp_value: datetime) -> dict:
    return {
        "task_id": task.get("task_id"),
        "case_id": case_id,
        "record_id": record_id,
        "plan_id": plan_id,
        "created_at": timestamp_value,
        "updated_at": timestamp_value,
        "task_text": task.get("task_text"),
        "status": task.get("status"),
        "task_due": task.get("task_due"),
        "completed_at": task.get("completed_at"),
        "task_photo_url": task.get("task_photo_url"),
        "source": task.get("source"),
        "order_index": task.get("order_index"),
    }


def _extract_analysis_from_review_payload(review_payload: dict | None) -> dict | None:
    if not isinstance(review_payload, dict):
        return None

    analysis = review_payload.get("analysis")
    if isinstance(analysis, dict):
        return dict(analysis)

    analysis = review_payload.get("AI_analysis")
    if isinstance(analysis, dict):
        return dict(analysis)

    treatment_plan = review_payload.get("treatment_plan")
    non_analysis_keys = {
        "treatment_plan",
        "ai_result_edit_flag",
        "treatment_plan_edit_flag",
        "signature",
        "signature_base64",
    }
    if treatment_plan is not None or any(key in review_payload for key in non_analysis_keys):
        candidate = {
            key: value
            for key, value in review_payload.items()
            if key not in non_analysis_keys
        }
        return candidate if candidate else None

    return dict(review_payload)


def _update_case_record_plan_and_tasks_status(
    *,
    case_ref,
    record_ref,
    case_data: dict,
    record_data: dict,
    new_status: Status,
    timestamp_field: str,
    timestamp_value: datetime,
    update_task_statuses: bool = True,
):
    current_plan_id = case_data.get("current_plan_id")
    current_treatment_plan = case_data.get("current_treatment_plan") or record_data.get("treatment_plan") or {}
    normalized_treatment_plan = dict(current_treatment_plan) if isinstance(current_treatment_plan, dict) else {}
    base_tasks = _get_plan_tasks(normalized_treatment_plan, record_data.get("task_list") or [])
    if update_task_statuses:
        normalized_tasks = _normalize_plan_tasks_status(base_tasks, new_status.value)
    else:
        normalized_tasks = _normalize_plan_tasks(base_tasks)
    if normalized_treatment_plan:
        normalized_treatment_plan["status"] = new_status.value
        normalized_treatment_plan["plan_tasks"] = normalized_tasks

    record_update = {
        "status": new_status,
        "record_updated_at": timestamp_value,
        "timestamps": {
            "updated_at": timestamp_value,
            timestamp_field: timestamp_value,
        },
    }
    if normalized_treatment_plan:
        record_update["treatment_plan"] = normalized_treatment_plan
        record_update["task_list"] = firestore.DELETE_FIELD

    case_update = {
        "status": new_status,
        "current_record_id": record_data.get("record_id") or case_data.get("current_record_id"),
        "case_updated_at": timestamp_value,
    }

    current_record_snapshot = _merge_sections(
        record_data,
        record_update,
        [
            "timestamps",
            "image",
            "vital_signs",
            "wound_detail",
            "ischemia",
            "infection",
            "neuropathy",
            "sinbad",
            "lab_results",
            "vascular",
            "gangrene_extent",
            "analysis",
            "treatment_plan",
        ],
    )
    case_update.update(_current_record_snapshot(current_record_snapshot))
    case_update["current_task_list"] = firestore.DELETE_FIELD

    batch = db.batch()
    batch.set(record_ref, record_update, merge=True)
    batch.set(case_ref, case_update, merge=True)

    if current_plan_id and normalized_treatment_plan:
        plan_ref = record_ref.collection("plan_versions").document(current_plan_id)
        batch.set(plan_ref, {
            "status": new_status.value,
            "updated_at": timestamp_value,
        }, merge=True)
        if update_task_statuses:
            for task in normalized_tasks:
                task_id = task.get("task_id") or _generate_task_id()
                task_ref = plan_ref.collection("tasks").document(task_id)
                batch.set(task_ref, {
                    "task_id": task_id,
                    "status": new_status.value,
                    "updated_at": timestamp_value,
                    "order_index": task.get("order_index"),
                }, merge=True)

    batch.commit()
    return current_plan_id


@firestore.transactional
def get_next_case_id(transaction):
    current_prefix = date.today().strftime("%y%m%d")
    prefix_label = "CS"
    counter_ref = db.collection("metadata").document(f"counters_case_{current_prefix}")
    snapshot = transaction.get(counter_ref)
    if not hasattr(snapshot, "exists"):
        snapshot = next(iter(snapshot))
    if snapshot.exists:
        last_num = snapshot.get("last_running_num") or 0
        new_num = last_num + 1
    else:
        new_num = 1
    transaction.set(counter_ref, {"last_running_num": new_num}, merge=True)
    return f"{prefix_label}-{current_prefix}-{new_num:05d}"


@firestore.transactional
def create_case_with_first_record(transaction, case_doc_ref, case_doc_data, record_doc_ref, record_doc_data):
    transaction.set(case_doc_ref, case_doc_data)
    transaction.set(record_doc_ref, record_doc_data)


@router.post("/create-case")
async def create_case(payload: CreateCaseRequest):
    try:
        patient_id = payload.patient_id

        status_str = (payload.status or "CREATION").strip().upper()
        try:
            status = Status(status_str)
        except ValueError:
            status = Status.CREATION
        
        urgency = None
        if payload.urgency:
            try:
                urgency = Urgency(payload.urgency.strip().upper())
            except ValueError:
                urgency = None

        vital_signs = VitalSigns(
            temperature=(payload.vitals.temperature if payload.vitals else None),
            blood_pressure=(payload.vitals.blood_pressure if payload.vitals else None),
            blood_pressure_systolic=(
                payload.vitals.blood_pressure_systolic if payload.vitals else None
            ),
            blood_pressure_diastolic=(
                payload.vitals.blood_pressure_diastolic if payload.vitals else None
            ),
            heart_rate=(payload.vitals.heart_rate if payload.vitals else None),
            respiratory_rate=(
                payload.vitals.respiratory_rate
                if payload.vitals and payload.vitals.respiratory_rate is not None
                else None
            ),
            blood_glucose=(
                payload.vitals.blood_glucose
                if payload.vitals and payload.vitals.blood_glucose is not None
                else (payload.vitals.blood_sugar if payload.vitals else None)
            ),
        )

        sent_at_raw = payload.meta.sent_at if payload.meta else None
        created_at = _normalize_datetime(sent_at_raw, fallback_to_now=True)

        timestamps = Timestamps(
            created_at=created_at,
            updated_at=created_at,
            analyze_at=None,
            doctor_review_at=None,
            plan_issued_at=None,
            treatment_active_at=None,
            appointment_at=None,
            completed_at=None,
        )

        wound_detail = WoundDetail(
            location_primary=None,
            location_detail=None,
            wound_type=None,
            shape=None,
            size=Size(width_cm=None, length_cm=None),
            depth_category=None,
            bed=Bed(slough_pct=None, necrotic_pct=None),
            edge_description=None,
            periwound_status=None,
            discharge=Discharge(volume=None, type=None),
            odor_presence=None,
            pain_score=None,
            has_infection=None,
            skin_condition=None,
        )

        transaction = db.transaction()
        case_id = get_next_case_id(transaction)
        record_id = "REC-00001"

        case_record = WoundCaseRecord(
            record_id=record_id,
            case_id=case_id,
            patient_id=patient_id,
            record_created_by=payload.created_by_nurse,
            record_created_at=created_at,
            record_updated_at=created_at,
            created_by_nurse=payload.created_by_nurse,
            assigned_doctor=payload.assigned_doctor,
            status=status,
            urgency=urgency,
            vital_signs=vital_signs,
            wound_detail=wound_detail,
            ischemia=Ischemia(),
            infection=Infection(),
            neuropathy=Neuropathy(),
            sinbad=Sinbad(),
            lab_results=LabResults(),
            vascular=Vascular(),
            gangrene_extent=None,
            timestamps=timestamps,
            image=CaseImage(image_folder_url=None),
        )

        case_doc_ref = db.collection("cases").document(case_id)
        record_doc_ref = case_doc_ref.collection("records").document(record_id)

        case_doc_data = {
            "case_id": case_id,
            "patient_id": patient_id,
            "created_by_nurse": payload.created_by_nurse,
            "assigned_doctor": payload.assigned_doctor,
            "status": status,
            "urgency": urgency,
            "case_created_at": created_at,
            "case_updated_at": created_at,
            "current_record_id": record_id,
            "current_analysis_id": None,
            "current_plan_id": None,
        }

        record_doc_data = _model_to_dict(case_record)
        case_doc_data.update(_current_record_snapshot(record_doc_data))

        print("create-case payload:", {"case": case_doc_data, "record": record_doc_data})

        create_case_with_first_record(transaction, case_doc_ref, case_doc_data, record_doc_ref, record_doc_data)

        return {
            "status": "Case creation success",
            "patient_id": patient_id,
            "case_id": case_id,
            "record_id": record_id,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/update_cases")
async def update_case(payload: UpdateCaseRequest):
    try:
        patient_id = payload.patient_id
        case_id = payload.case_id
        if not case_id:
            raise HTTPException(status_code=400, detail="case_id is required")

        case_ref = db.collection("cases").document(case_id)
        case_snapshot = case_ref.get()
        if not case_snapshot.exists:
            raise HTTPException(status_code=404, detail="Case not found")

        case_data = case_snapshot.to_dict() or {}
        if case_data.get("patient_id") and case_data.get("patient_id") != patient_id:
            raise HTTPException(status_code=400, detail="patient_id does not match case")

        status_str = (payload.status or "CREATION").strip().upper()
        try:
            status = Status(status_str)
        except ValueError:
            status = Status.CREATION

        urgency = None
        if payload.urgency:
            try:
                urgency = Urgency(payload.urgency.strip().upper())
            except ValueError:
                urgency = None

        vital_signs = VitalSigns(
            temperature=(payload.vitals.temperature if payload.vitals else None),
            blood_pressure=(payload.vitals.blood_pressure if payload.vitals else None),
            blood_pressure_systolic=(
                payload.vitals.blood_pressure_systolic if payload.vitals else None
            ),
            blood_pressure_diastolic=(
                payload.vitals.blood_pressure_diastolic if payload.vitals else None
            ),
            heart_rate=(payload.vitals.heart_rate if payload.vitals else None),
            respiratory_rate=(
                payload.vitals.respiratory_rate
                if payload.vitals and payload.vitals.respiratory_rate is not None
                else None
            ),
            blood_glucose=(
                payload.vitals.blood_glucose
                if payload.vitals and payload.vitals.blood_glucose is not None
                else (payload.vitals.blood_sugar if payload.vitals else None)
            ),
        )

        sent_at_raw = payload.meta.sent_at if payload.meta else None
        created_at = _normalize_datetime(sent_at_raw, fallback_to_now=True)

        timestamps = Timestamps(
            created_at=created_at,
            updated_at=created_at,
            analyze_at=None,
            doctor_review_at=None,
            plan_issued_at=None,
            treatment_active_at=None,
            appointment_at=None,
            completed_at=None,
        )

        wound_detail = WoundDetail(
            location_primary=None,
            location_detail=None,
            wound_type=None,
            shape=None,
            size=Size(width_cm=None, length_cm=None),
            depth_category=None,
            bed=Bed(slough_pct=None, necrotic_pct=None),
            edge_description=None,
            periwound_status=None,
            discharge=Discharge(volume=None, type=None),
            odor_presence=None,
            pain_score=None,
            has_infection=None,
            skin_condition=None,
        )

        # Determine next record id based on latest record
        latest_query = case_ref.collection("records").order_by(
            "record_created_at", direction=firestore.Query.DESCENDING
        ).limit(1)
        latest_docs = list(latest_query.stream())
        if latest_docs:
            last_id = latest_docs[0].to_dict().get("record_id") or latest_docs[0].id
            try:
                last_num = int(last_id.split("-")[-1])
            except Exception:
                last_num = 0
            record_id = f"REC-{last_num + 1:05d}"
        else:
            record_id = "REC-00001"

        case_record = WoundCaseRecord(
            record_id=record_id,
            case_id=case_id,
            patient_id=patient_id,
            record_created_by=payload.created_by_nurse,
            record_created_at=created_at,
            record_updated_at=created_at,
            created_by_nurse=payload.created_by_nurse,
            assigned_doctor=payload.assigned_doctor,
            status=status,
            urgency=urgency,
            vital_signs=vital_signs,
            wound_detail=wound_detail,
            ischemia=Ischemia(),
            infection=Infection(),
            neuropathy=Neuropathy(),
            sinbad=Sinbad(),
            lab_results=LabResults(),
            vascular=Vascular(),
            gangrene_extent=None,
            timestamps=timestamps,
            image=CaseImage(image_folder_url=None),
        )

        record_doc_ref = case_ref.collection("records").document(record_id)
        record_doc_data = _model_to_dict(case_record)

        latest_record_data = {}
        current_record_id = case_data.get("current_record_id")
        if current_record_id:
            current_record_ref = case_ref.collection("records").document(current_record_id)
            current_record_snapshot = current_record_ref.get()
            if current_record_snapshot.exists:
                latest_record_data = current_record_snapshot.to_dict() or {}
        if not latest_record_data:
            latest_query = case_ref.collection("records").order_by(
                "record_created_at", direction=firestore.Query.DESCENDING
            ).limit(1)
            latest_docs = list(latest_query.stream())
            latest_record_data = latest_docs[0].to_dict() if latest_docs else {}
        record_doc_data = _merge_sections(
            latest_record_data,
            record_doc_data,
            [
                "vital_signs",
                "wound_detail",
                "ischemia",
                "infection",
                "neuropathy",
                "sinbad",
                "lab_results",
                "vascular",
                "gangrene_extent",
                "treatment_plan",
                "analysis",
            ],
        )
        if _is_all_null(record_doc_data.get("vital_signs")) and latest_record_data.get("vital_signs"):
            record_doc_data["vital_signs"] = latest_record_data.get("vital_signs")
        # Duplicate latest treatment plan with a new plan_id for this follow-up record
        latest_plan = latest_record_data.get("treatment_plan")
        new_plan_id = None
        duplicated_plan = None
        if latest_plan:
            new_plan_id = f"PL-{_utc_now().strftime('%Y%m%d%H%M%S')}"
            duplicated_plan = dict(latest_plan)
            duplicated_plan["plan_id"] = new_plan_id
            duplicated_plan["plan_tasks"] = _normalize_plan_tasks(
                duplicated_plan.get("plan_tasks"),
            )
            record_doc_data["treatment_plan"] = duplicated_plan
        record_doc_data["task_list"] = firestore.DELETE_FIELD

        batch = db.batch()
        case_update = {
            "status": status,
            "urgency": urgency,
            "case_updated_at": created_at,
            "current_record_id": record_id,
            "current_analysis_id": None,
            "current_plan_id": new_plan_id,
        }
        case_update.update(_current_record_snapshot(record_doc_data))
        case_update["current_task_list"] = firestore.DELETE_FIELD
        batch.set(case_ref, case_update, merge=True)
        batch.set(record_doc_ref, record_doc_data, merge=True)

        if duplicated_plan and new_plan_id:
            plan_created_at = _utc_now()
            plan_ref = record_doc_ref.collection("plan_versions").document(new_plan_id)
            batch.set(plan_ref, {
                "plan_id": new_plan_id,
                "case_id": case_id,
                "record_id": record_id,
                "created_at": plan_created_at,
                "status": duplicated_plan.get("status") or "DRAFT",
                "plan_text": duplicated_plan.get("plan_text"),
                "followup_days": duplicated_plan.get("followup_days"),
            }, merge=True)
            plan_tasks = duplicated_plan.get("plan_tasks") or []
            for task in plan_tasks:
                task_id = task.get("task_id") or _generate_task_id()
                task_ref = plan_ref.collection("tasks").document(task_id)
                batch.set(task_ref, _task_doc_payload(
                    task,
                    case_id=case_id,
                    record_id=record_id,
                    plan_id=new_plan_id,
                    timestamp_value=plan_created_at,
                ), merge=True)
        batch.commit()

        return {
            "status": "Case update success",
            "patient_id": patient_id,
            "case_id": case_id,
            "record_id": record_id,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/resume-case")
async def resume_case(payload: ResumeCaseRequest):
    """Resume an incomplete case that is stuck at CREATION, AI_PROCESSING, or ANALYZING.

    Unlike /update_cases (which always creates a new follow-up record), this endpoint
    patches vitals onto the *existing* current record so the nurse can continue the
    original create-case flow without creating a duplicate record.
    """
    try:
        case_id = payload.case_id
        case_ref = db.collection("cases").document(case_id)
        case_snapshot = case_ref.get()
        if not case_snapshot.exists:
            raise HTTPException(status_code=404, detail="Case not found")

        case_data = case_snapshot.to_dict() or {}
        if case_data.get("patient_id") and case_data.get("patient_id") != payload.patient_id:
            raise HTTPException(status_code=400, detail="patient_id does not match case")

        status = str(case_data.get("status") or "").upper()
        if status not in RESUMABLE_STATUSES:
            raise HTTPException(
                status_code=400,
                detail=f"Case is not resumable (status={status}). Only {sorted(RESUMABLE_STATUSES)} are allowed.",
            )

        record_id = case_data.get("current_record_id")
        if not record_id:
            raise HTTPException(status_code=404, detail="No current record found for case")

        now = _utc_now()

        record_update: dict = {"record_updated_at": now}
        case_update: dict = {"case_updated_at": now}

        if payload.vitals:
            # Build a dict of only the non-null vital fields so we do not wipe
            # values that were already saved on a previous attempt.
            incoming_vitals = {
                "temperature": payload.vitals.temperature,
                "blood_pressure": payload.vitals.blood_pressure,
                "blood_pressure_systolic": payload.vitals.blood_pressure_systolic,
                "blood_pressure_diastolic": payload.vitals.blood_pressure_diastolic,
                "heart_rate": payload.vitals.heart_rate,
                "respiratory_rate": payload.vitals.respiratory_rate,
                "blood_glucose": payload.vitals.blood_glucose or payload.vitals.blood_sugar,
            }
            incoming_vitals = {k: v for k, v in incoming_vitals.items() if v is not None}
            if incoming_vitals:
                record_update["vital_signs"] = incoming_vitals
                case_update["current_vital_signs"] = incoming_vitals

        record_ref = case_ref.collection("records").document(record_id)
        batch = db.batch()
        batch.set(record_ref, record_update, merge=True)
        batch.set(case_ref, case_update, merge=True)
        batch.commit()

        return {
            "status": "success",
            "case_id": case_id,
            "record_id": record_id,
            "patient_id": payload.patient_id,
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/cases_list")
async def list_cases(payload: dict):
    try:
        print(f"[cases_list] payload={payload}")
        limit = payload.get("limit", 50)
        patient_id = payload.get("patient_id")
        status_filter = payload.get("filter")

        if not isinstance(limit, int):
            try:
                limit = int(limit)
            except Exception:
                limit = 50

        if limit < 1:
            limit = 1
        if limit > 200:
            limit = 200

        normalized_status_filter = []
        if isinstance(status_filter, list):
            for value in status_filter:
                if value is None:
                    continue
                status_value = str(value).strip().upper()
                if status_value:
                    normalized_status_filter.append(status_value)
        if len(normalized_status_filter) > 10:
            normalized_status_filter = normalized_status_filter[:10]

        query = db.collection("cases")
        if patient_id:
            query = query.where(filter=FieldFilter("patient_id", "==", patient_id))
        if normalized_status_filter:
            query = query.where(filter=FieldFilter("status", "in", normalized_status_filter))

        if patient_id or normalized_status_filter:
            # Avoid ordering here because filtered queries may require additional composite indexes.
            query = query.limit(limit)
        else:
            query = query.order_by("case_updated_at", direction=firestore.Query.DESCENDING).limit(limit)
        docs = query.stream()

        cases = []
        patient_ids = set()
        for doc in docs:
            data = doc.to_dict() or {}
            data["case_id"] = data.get("case_id") or doc.id
            if data.get("patient_id"):
                patient_ids.add(data["patient_id"])
            cases.append(data)

        patient_map = {}
        if patient_ids:
            refs = [db.collection("patients").document(pid) for pid in patient_ids]
            for snap in db.get_all(refs):
                if snap.exists:
                    patient_map[snap.id] = snap.to_dict() or {}

        for case in cases:
            patient_data = patient_map.get(case.get("patient_id"), {})
            case["patient_name"] = patient_data.get("patient_name")
            case["photo_url"] = patient_data.get("photo_url")

        print(f"[cases_list] returned_cases={len(cases)}")
        return {"status": "success", "cases": cases}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/case_detail")
async def case_detail(payload: dict):
    try:
        case_id = payload.get("case_id")
        if not case_id:
            raise HTTPException(status_code=400, detail="case_id is required")

        case_ref = db.collection("cases").document(case_id)
        case_snapshot = case_ref.get()
        if not case_snapshot.exists:
            raise HTTPException(status_code=404, detail="Case not found")

        case_data = case_snapshot.to_dict() or {}
        case_data["case_id"] = case_data.get("case_id") or case_snapshot.id

        records_query = case_ref.collection("records").order_by(
            "record_created_at", direction=firestore.Query.ASCENDING
        )
        records_docs = records_query.stream()
        records = [doc.to_dict() for doc in records_docs]

        patient_profile = None
        patient_id = case_data.get("patient_id")
        if patient_id:
            patient_ref = db.collection("patients").document(patient_id)
            patient_snapshot = patient_ref.get()
            if patient_snapshot.exists:
                patient_profile = patient_snapshot.to_dict() or {}
                patient_profile["patient_id"] = patient_profile.get("patient_id") or patient_snapshot.id

        return {
            "status": "success",
            "case": jsonable_encoder(case_data),
            "records": jsonable_encoder(records),
            "patient_profile": jsonable_encoder(patient_profile),
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/send-to-doctor")
async def send_to_doctor(payload: WoundCaseRecordUpdate):
    try:
        payload_dict = _model_to_dict(payload)
        print("send-to-doctor received payload:", json.dumps(payload_dict, ensure_ascii=False))
        operation_time = _utc_now()

        case_id = payload.case_id
        record_id = payload.record_id

        case_ref = db.collection("cases").document(case_id)
        record_ref = case_ref.collection("records").document(record_id)
        case_snapshot = case_ref.get()
        case_data = case_snapshot.to_dict() if case_snapshot.exists else {}
        existing_record = record_ref.get()
        existing_record_data = existing_record.to_dict() if existing_record.exists else {}
        assigned_doctor = payload.assigned_doctor or case_data.get("assigned_doctor")
        patient_id = payload.patient_id or case_data.get("patient_id")

        analysis_id = f"AN-{operation_time.strftime('%Y%m%d%H%M%S')}"
        plan_id = f"PL-{operation_time.strftime('%Y%m%d%H%M%S')}"

        analysis_ref = record_ref.collection("analysis_versions").document(analysis_id)
        plan_ref = record_ref.collection("plan_versions").document(plan_id)

        record_data = payload_dict
        record_data = _merge_sections(
            existing_record_data,
            record_data,
            [
                "vital_signs",
                "wound_detail",
                "ischemia",
                "infection",
                "neuropathy",
                "sinbad",
                "lab_results",
                "vascular",
                "gangrene_extent",
                "treatment_plan",
                "analysis",
                "image",
            ],
        )
        if _is_all_null(record_data.get("vital_signs")) and existing_record_data.get("vital_signs"):
            record_data["vital_signs"] = existing_record_data.get("vital_signs")
        if record_data.get("timestamps") is None:
            record_data["timestamps"] = {
                "created_at": _normalize_datetime(payload.record_created_at, fallback_to_now=True),
                "updated_at": operation_time,
                "analyze_at": operation_time,
                "doctor_review_at": None,
                "plan_issued_at": None,
                "treatment_active_at": None,
                "appointment_at": None,
                "completed_at": None,
            }
        if record_data.get("image") is None:
            record_data.pop("image", None)
        record_data["record_updated_at"] = operation_time
        record_data["timestamps"]["updated_at"] = operation_time
        record_data["timestamps"]["analyze_at"] = operation_time

        analysis_payload = payload_dict.get("analysis")
        analysis_data = {
            "analysis_id": analysis_id,
            "case_id": case_id,
            "record_id": record_id,
            "status": "DRAFT",
            "source": "AI",
            "created_at": operation_time,
            "payload": analysis_payload,
        }

        treatment_plan = payload_dict.get("treatment_plan") or {}
        treatment_plan["plan_id"] = plan_id
        plan_data = {
            "plan_id": plan_id,
            "case_id": case_id,
            "record_id": record_id,
            "created_at": operation_time,
            "status": treatment_plan.get("status") or "DRAFT",
            "plan_text": treatment_plan.get("plan_text"),
            "followup_days": treatment_plan.get("followup_days"),
        }

        tasks = _get_plan_tasks(treatment_plan, payload_dict.get("task_list") or [])
        enriched_tasks = _normalize_plan_tasks(tasks, default_source="AI")
        treatment_plan["plan_tasks"] = enriched_tasks
        tasks = enriched_tasks

        record_data["treatment_plan"] = treatment_plan
        record_data["task_list"] = firestore.DELETE_FIELD

        batch = db.batch()
        case_update = {
            "status": Status.DOCTOR_REVIEW,
            "urgency": payload.urgency,
            "case_updated_at": operation_time,
            "current_record_id": record_id,
            "current_analysis_id": analysis_id,
            "current_plan_id": plan_id,
        }
        case_update.update(_current_record_snapshot(record_data))
        case_update["current_task_list"] = firestore.DELETE_FIELD
        batch.set(case_ref, case_update, merge=True)
        batch.set(record_ref, record_data, merge=True)
        batch.set(analysis_ref, analysis_data, merge=True)
        batch.set(plan_ref, plan_data, merge=True)

        for task in tasks:
            task_id = task.get("task_id") or _generate_task_id()
            task_ref = plan_ref.collection("tasks").document(task_id)
            batch.set(task_ref, _task_doc_payload(
                task,
                case_id=case_id,
                record_id=record_id,
                plan_id=plan_id,
                timestamp_value=operation_time,
            ), merge=True)

        batch.commit()

        notification_id = None
        try:
            patient_name = None
            if patient_id:
                patient_snapshot = db.collection("patients").document(patient_id).get()
                if patient_snapshot.exists:
                    patient_profile = patient_snapshot.to_dict() or {}
                    patient_name = patient_profile.get("patient_name")

            notification_id = create_doctor_review_notification(
                case_id=case_id,
                record_id=record_id,
                patient_id=patient_id,
                patient_name=patient_name,
                urgency=payload.urgency.value if payload.urgency else None,
                assigned_doctor=payload.assigned_doctor or case_data.get("assigned_doctor"),
            )
        except Exception as notification_error:
            print(f"Warning: failed to create doctor notification for case {case_id}: {notification_error}")

        return {
            "status": "success",
            "message": "Case sent for doctor review",
            "case_id": case_id,
            "record_id": record_id,
            "analysis_id": analysis_id,
            "plan_id": plan_id,
            "notification_id": notification_id,
        }

    except Exception as e:
        print(f"Error sending to doctor: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/no-wound-assessment")
async def create_no_wound_assessment(payload: NoWoundAssessmentRequest):
    try:
        payload_dict = _model_to_dict(payload)
        print("no-wound-assessment received payload:", json.dumps(payload_dict, ensure_ascii=False))

        case_id = payload.case_id
        case_ref = db.collection("cases").document(case_id)
        case_snapshot = case_ref.get()
        if not case_snapshot.exists:
            raise HTTPException(status_code=404, detail="Case not found")

        case_data = case_snapshot.to_dict() or {}
        if case_data.get("patient_id") and case_data.get("patient_id") != payload.patient_id:
            raise HTTPException(status_code=400, detail="patient_id does not match case")

        record_ref = case_ref.collection("records").document(payload.record_id)
        record_snapshot = record_ref.get()
        if not record_snapshot.exists:
            raise HTTPException(status_code=404, detail="Record not found")

        existing_record_data = record_snapshot.to_dict() or {}
        submitted_at_raw = payload.meta.submitted_at if payload.meta else None
        operation_time = _normalize_datetime(submitted_at_raw, fallback_to_now=True)

        existing_timestamps = existing_record_data.get("timestamps") or {}
        record_created_at = existing_record_data.get("record_created_at")
        created_at = _normalize_datetime(
            existing_timestamps.get("created_at") or record_created_at or operation_time,
            fallback_to_now=True,
        )
        updated_timestamps = dict(existing_timestamps) if isinstance(existing_timestamps, dict) else {}
        updated_timestamps["created_at"] = created_at
        updated_timestamps["updated_at"] = operation_time
        updated_timestamps.setdefault("analyze_at", None)
        updated_timestamps.setdefault("doctor_review_at", None)
        updated_timestamps.setdefault("plan_issued_at", None)
        updated_timestamps.setdefault("treatment_active_at", None)
        updated_timestamps.setdefault("appointment_at", None)
        updated_timestamps["completed_at"] = operation_time

        record_data = {
            "record_id": payload.record_id,
            "case_id": case_id,
            "patient_id": payload.patient_id,
            "record_created_by": existing_record_data.get("record_created_by") or payload.created_by_nurse,
            "record_created_at": created_at,
            "record_updated_at": operation_time,
            "created_by_nurse": payload.created_by_nurse or existing_record_data.get("created_by_nurse") or case_data.get("created_by_nurse"),
            "assigned_doctor": payload.assigned_doctor or existing_record_data.get("assigned_doctor") or case_data.get("assigned_doctor"),
            "status": payload.status,
            "urgency": payload.urgency or existing_record_data.get("urgency") or case_data.get("urgency"),
            "flow_type": payload.flow_type,
            "wound_present": payload.wound_present,
            "nurse_reviewed_flag": payload.nurse_reviewed_flag,
            "vital_signs": payload_dict.get("vital_signs"),
            "wound_detail": None,
            "ischemia": payload_dict.get("ischemia"),
            "infection": payload_dict.get("infection"),
            "neuropathy": payload_dict.get("neuropathy"),
            "sinbad": payload_dict.get("sinbad"),
            "lab_results": payload_dict.get("lab_results"),
            "vascular": payload_dict.get("vascular"),
            "gangrene_extent": existing_record_data.get("gangrene_extent"),
            "timestamps": updated_timestamps,
            "image": {"image_folder_url": None},
            "analysis": None,
            "treatment_plan": None,
            "meta": payload_dict.get("meta"),
            "task_list": firestore.DELETE_FIELD,
        }

        batch = db.batch()
        case_update = {
            "status": payload.status,
            "urgency": record_data.get("urgency"),
            "case_updated_at": operation_time,
            "current_record_id": payload.record_id,
            "current_analysis_id": None,
            "current_plan_id": None,
            "flow_type": payload.flow_type,
            "wound_present": payload.wound_present,
            "nurse_reviewed_flag": payload.nurse_reviewed_flag,
        }
        case_update.update(_current_record_snapshot(record_data))
        case_update["current_task_list"] = firestore.DELETE_FIELD

        batch.set(case_ref, case_update, merge=True)
        batch.set(record_ref, record_data, merge=True)
        batch.commit()

        return {
            "status": "success",
            "case_id": case_id,
            "record_id": payload.record_id,
            "next_status": Status.COMPLETED.value,
        }

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error creating no-wound assessment: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/doctor-review")
async def doctor_review(payload: dict):
    try:
        operation_time = _utc_now()
        incoming_analysis_id = payload.get("analysis_id")
        case_id = payload.get("case_id")
        record_id = payload.get("record_id")
        legacy_review_payload = payload.get("payload")
        top_level_analysis = payload.get("analysis")
        treatment_plan = payload.get("treatment_plan")
        ai_result_edit_flag = payload.get("ai_result_edit_flag")
        treatment_plan_edit_flag = payload.get("treatment_plan_edit_flag")
        signature = payload.get("signature")
        signature_base64 = payload.get("signature_base64")

        if not case_id:
            raise HTTPException(status_code=400, detail="case_id is required")
        if not record_id:
            raise HTTPException(status_code=400, detail="record_id is required")
        if legacy_review_payload is not None and not isinstance(legacy_review_payload, dict):
            raise HTTPException(status_code=400, detail="payload must be an object")
        if top_level_analysis is not None and not isinstance(top_level_analysis, dict):
            raise HTTPException(status_code=400, detail="analysis must be an object")
        if treatment_plan is None and isinstance(legacy_review_payload, dict):
            treatment_plan = legacy_review_payload.get("treatment_plan")
        if treatment_plan is not None and not isinstance(treatment_plan, dict):
            raise HTTPException(status_code=400, detail="treatment_plan must be an object")
        if not isinstance(legacy_review_payload, dict) and not isinstance(top_level_analysis, dict):
            raise HTTPException(status_code=400, detail="analysis is required")

        case_ref = db.collection("cases").document(case_id)
        case_snapshot = case_ref.get()
        if not case_snapshot.exists:
            raise HTTPException(status_code=404, detail="Case not found")
        case_data = case_snapshot.to_dict() or {}

        record_ref = case_ref.collection("records").document(record_id)
        record_snapshot = record_ref.get()
        if not record_snapshot.exists:
            raise HTTPException(status_code=404, detail="Record not found")
        existing_record_data = record_snapshot.to_dict() or {}

        source_analysis_id = incoming_analysis_id or case_data.get("current_analysis_id")
        previous_sinbad = None
        if source_analysis_id:
            source_analysis_snapshot = record_ref.collection("analysis_versions").document(source_analysis_id).get()
            if source_analysis_snapshot.exists:
                source_analysis_data = source_analysis_snapshot.to_dict() or {}
                source_payload = source_analysis_data.get("payload") or {}
                source_analysis = _extract_analysis_from_review_payload(source_payload) or {}
                classifications = source_analysis.get("classifications") or {}
                if isinstance(classifications, dict):
                    previous_sinbad = classifications.get("SINBAD")

        review_payload: dict = {}
        if isinstance(legacy_review_payload, dict):
            review_payload.update(dict(legacy_review_payload))
        if isinstance(top_level_analysis, dict):
            review_payload["analysis"] = dict(top_level_analysis)
        if treatment_plan is not None:
            review_payload["treatment_plan"] = dict(treatment_plan)
        if ai_result_edit_flag is not None:
            review_payload["ai_result_edit_flag"] = ai_result_edit_flag
        if treatment_plan_edit_flag is not None:
            review_payload["treatment_plan_edit_flag"] = treatment_plan_edit_flag

        doctor_analysis = None
        if isinstance(top_level_analysis, dict):
            doctor_analysis = dict(top_level_analysis)
        else:
            doctor_analysis = _extract_analysis_from_review_payload(review_payload)
        if not isinstance(doctor_analysis, dict):
            raise HTTPException(status_code=400, detail="analysis must resolve to an object")

        if previous_sinbad is not None:
            classifications = doctor_analysis.get("classifications")
            if not isinstance(classifications, dict):
                classifications = {}
            classifications["SINBAD"] = previous_sinbad
            doctor_analysis["classifications"] = classifications

        review_payload["analysis"] = doctor_analysis
        review_payload.pop("AI_analysis", None)

        if signature is not None:
            review_payload["signature"] = signature
        if signature_base64 is not None:
            review_payload["signature_base64"] = signature_base64

        analysis_id = f"AN-{operation_time.strftime('%Y%m%d%H%M%S')}"
        plan_id = None
        normalized_treatment_plan = None
        normalized_tasks = []
        if isinstance(treatment_plan, dict):
            plan_id = f"PL-{operation_time.strftime('%Y%m%d%H%M%S')}"
            normalized_treatment_plan = dict(treatment_plan)
            normalized_treatment_plan["plan_id"] = plan_id
            normalized_treatment_plan["status"] = "SENT"
            normalized_tasks = _normalize_plan_tasks(
                normalized_treatment_plan.get("plan_tasks") or [],
                default_source="Doctor",
            )
            for task_data in normalized_tasks:
                task_data["status"] = "SENT"
            normalized_treatment_plan["plan_tasks"] = normalized_tasks
            review_payload["treatment_plan"] = normalized_treatment_plan

        analysis_data = {
            "analysis_id": analysis_id,
            "case_id": case_id,
            "record_id": record_id,
            "status": "SENT",
            "source": "Doctor",
            "created_at": operation_time,
            "payload": review_payload,
        }

        batch = db.batch()
        analysis_ref = record_ref.collection("analysis_versions").document(analysis_id)
        batch.set(analysis_ref, analysis_data, merge=True)
        record_update = {
            "analysis": doctor_analysis,
            "status": Status.PLAN_ISSUED,
            "record_updated_at": operation_time,
            "timestamps": {
                "updated_at": operation_time,
                "doctor_review_at": operation_time,
            },
        }
        case_update = {
            "status": Status.PLAN_ISSUED,
            "current_record_id": record_id,
            "current_analysis_id": analysis_id,
            "current_analysis": doctor_analysis,
            "case_updated_at": operation_time,
        }
        if signature is not None:
            record_update["signature"] = signature
        if signature_base64 is not None:
            record_update["signature_base64"] = signature_base64
        healing_progress = doctor_analysis.get("healing_progress") if isinstance(doctor_analysis, dict) else None
        if healing_progress is not None:
            record_update["current_healing_progress"] = healing_progress
        if normalized_treatment_plan is not None:
            record_update["treatment_plan"] = normalized_treatment_plan
            record_update["task_list"] = firestore.DELETE_FIELD
            case_update["current_plan_id"] = plan_id

        current_record_snapshot = _merge_sections(
            existing_record_data,
            record_update,
            [
                "timestamps",
                "image",
                "vital_signs",
                "wound_detail",
                "ischemia",
                "infection",
                "neuropathy",
                "sinbad",
                "lab_results",
                "vascular",
                "gangrene_extent",
                "analysis",
                "treatment_plan",
            ],
        )
        if record_update.get("current_healing_progress") is not None:
            current_record_snapshot["current_healing_progress"] = record_update.get("current_healing_progress")
        elif existing_record_data.get("current_healing_progress") is not None:
            current_record_snapshot["current_healing_progress"] = existing_record_data.get("current_healing_progress")
        case_update.update(_current_record_snapshot(current_record_snapshot))
        case_update["current_task_list"] = firestore.DELETE_FIELD

        batch.set(record_ref, record_update, merge=True)
        batch.set(case_ref, case_update, merge=True)
        if normalized_treatment_plan is not None and plan_id is not None:
            plan_ref = record_ref.collection("plan_versions").document(plan_id)
            batch.set(plan_ref, {
                "plan_id": plan_id,
                "case_id": case_id,
                "record_id": record_id,
                "created_at": operation_time,
                "status": normalized_treatment_plan.get("status") or "SENT",
                "plan_text": normalized_treatment_plan.get("plan_text"),
                "followup_days": normalized_treatment_plan.get("followup_days"),
                "source": "Doctor",
            }, merge=True)
            for task in normalized_tasks:
                task_id = task.get("task_id")
                task_ref = plan_ref.collection("tasks").document(task_id)
                batch.set(task_ref, _task_doc_payload(
                    task,
                    case_id=case_id,
                    record_id=record_id,
                    plan_id=plan_id,
                    timestamp_value=operation_time,
                ), merge=True)
        batch.commit()

        nurse_notification_id = None
        try:
            patient_id = case_data.get("patient_id") or existing_record_data.get("patient_id")
            patient_name = None
            if patient_id:
                patient_snapshot = db.collection("patients").document(patient_id).get()
                if patient_snapshot.exists:
                    patient_profile = patient_snapshot.to_dict() or {}
                    patient_name = patient_profile.get("patient_name")

            urgency_value = case_data.get("urgency")
            if hasattr(urgency_value, "value"):
                urgency_value = urgency_value.value

            nurse_notification_id = create_nurse_plan_issued_notification(
                case_id=case_id,
                record_id=record_id,
                patient_id=patient_id,
                patient_name=patient_name,
                urgency=urgency_value,
                created_by_nurse=case_data.get("created_by_nurse") or existing_record_data.get("created_by_nurse"),
            )
        except Exception as notification_error:
            print(f"Warning: failed to create nurse notification for case {case_id}: {notification_error}")

        return {
            "status": "success",
            "message": "Doctor review saved",
            "analysis_id": analysis_id,
            "plan_id": plan_id,
            "case_id": case_id,
            "record_id": record_id,
            "source": "Doctor",
            "sinbad_copied": previous_sinbad is not None,
            "notification_id": nurse_notification_id,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/create_appointment")
async def create_appointment(payload: dict):
    try:
        case_id = payload.get("case_id")
        appointment_at = payload.get("appointment_at")

        if not case_id:
            raise HTTPException(status_code=400, detail="case_id is required")
        if appointment_at is None:
            raise HTTPException(status_code=400, detail="appointment_at is required")

        appointment_dt = _normalize_datetime(appointment_at, fallback_to_now=False)
        if appointment_dt is None:
            raise HTTPException(status_code=400, detail="appointment_at must be a valid ISO datetime")

        case_ref = db.collection("cases").document(case_id)
        case_snapshot = case_ref.get()
        if not case_snapshot.exists:
            raise HTTPException(status_code=404, detail="Case not found")
        case_data = case_snapshot.to_dict() or {}
        record_id = case_data.get("current_record_id")
        if not record_id:
            raise HTTPException(status_code=404, detail="Current record not found for case")

        record_ref = case_ref.collection("records").document(record_id)
        record_snapshot = record_ref.get()
        if not record_snapshot.exists:
            raise HTTPException(status_code=404, detail="Record not found")
        record_data = record_snapshot.to_dict() or {}

        plan_id = _update_case_record_plan_and_tasks_status(
            case_ref=case_ref,
            record_ref=record_ref,
            case_data=case_data,
            record_data=record_data,
            new_status=Status.APPOINTMENT,
            timestamp_field="appointment_at",
            timestamp_value=appointment_dt,
            update_task_statuses=False,
        )

        return {
            "status": "success",
            "message": "Appointment created",
            "case_id": case_id,
            "record_id": record_id,
            "plan_id": plan_id,
            "appointment_at": appointment_dt.isoformat(),
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/request_close")
async def request_close(payload: dict):
    try:
        operation_time = _utc_now()
        case_id = payload.get("case_id")

        if not case_id:
            raise HTTPException(status_code=400, detail="case_id is required")

        case_ref = db.collection("cases").document(case_id)
        case_snapshot = case_ref.get()
        if not case_snapshot.exists:
            raise HTTPException(status_code=404, detail="Case not found")
        case_data = case_snapshot.to_dict() or {}
        record_id = case_data.get("current_record_id")
        if not record_id:
            raise HTTPException(status_code=404, detail="Current record not found for case")

        record_ref = case_ref.collection("records").document(record_id)
        record_snapshot = record_ref.get()
        if not record_snapshot.exists:
            raise HTTPException(status_code=404, detail="Record not found")

        batch = db.batch()
        batch.set(case_ref, {
            "status": Status.REQUEST_CLOSE,
            "current_record_id": record_id,
            "case_updated_at": operation_time,
        }, merge=True)
        batch.set(record_ref, {
            "status": Status.REQUEST_CLOSE,
            "record_updated_at": operation_time,
            "timestamps": {
                "updated_at": operation_time,
            },
        }, merge=True)
        batch.commit()

        notification_id = None
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

            notification_id = create_doctor_request_close_notification(
                case_id=case_id,
                record_id=record_id,
                patient_id=patient_id,
                patient_name=patient_name,
                urgency=urgency_value,
                assigned_doctor=case_data.get("assigned_doctor"),
            )
        except Exception as notification_error:
            print(f"Warning: failed to create doctor request-close notification for case {case_id}: {notification_error}")

        return {
            "status": "success",
            "message": "Close request saved",
            "case_id": case_id,
            "record_id": record_id,
            "notification_id": notification_id,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/complete_case")
async def complete_case(payload: dict):
    try:
        case_id = payload.get("case_id")
        completed_at = payload.get("completed_at")

        if not case_id:
            raise HTTPException(status_code=400, detail="case_id is required")

        completed_dt = _normalize_datetime(completed_at, fallback_to_now=True)

        case_ref = db.collection("cases").document(case_id)
        case_snapshot = case_ref.get()
        if not case_snapshot.exists:
            raise HTTPException(status_code=404, detail="Case not found")
        case_data = case_snapshot.to_dict() or {}
        record_id = case_data.get("current_record_id")
        if not record_id:
            raise HTTPException(status_code=404, detail="Current record not found for case")

        record_ref = case_ref.collection("records").document(record_id)
        record_snapshot = record_ref.get()
        if not record_snapshot.exists:
            raise HTTPException(status_code=404, detail="Record not found")
        record_data = record_snapshot.to_dict() or {}

        plan_id = _update_case_record_plan_and_tasks_status(
            case_ref=case_ref,
            record_ref=record_ref,
            case_data=case_data,
            record_data=record_data,
            new_status=Status.COMPLETED,
            timestamp_field="completed_at",
            timestamp_value=completed_dt,
        )

        return {
            "status": "success",
            "message": "Case completed",
            "case_id": case_id,
            "record_id": record_id,
            "plan_id": plan_id,
            "completed_at": completed_dt.isoformat(),
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/complete_case")
async def complete_case(payload: dict):
    try:
        case_id = payload.get("case_id")
        completed_at = payload.get("completed_at")

        if not case_id:
            raise HTTPException(status_code=400, detail="case_id is required")

        completed_dt = _normalize_datetime(completed_at, fallback_to_now=True)

        case_ref = db.collection("cases").document(case_id)
        case_snapshot = case_ref.get()
        if not case_snapshot.exists:
            raise HTTPException(status_code=404, detail="Case not found")
        case_data = case_snapshot.to_dict() or {}
        record_id = case_data.get("current_record_id")
        if not record_id:
            raise HTTPException(status_code=404, detail="Current record not found for case")

        record_ref = case_ref.collection("records").document(record_id)
        record_snapshot = record_ref.get()
        if not record_snapshot.exists:
            raise HTTPException(status_code=404, detail="Record not found")
        record_data = record_snapshot.to_dict() or {}

        plan_id = _update_case_record_plan_and_tasks_status(
            case_ref=case_ref,
            record_ref=record_ref,
            case_data=case_data,
            record_data=record_data,
            new_status=Status.COMPLETED,
            timestamp_field="completed_at",
            timestamp_value=completed_dt,
        )

        return {
            "status": "success",
            "message": "Case completed",
            "case_id": case_id,
            "record_id": record_id,
            "plan_id": plan_id,
            "completed_at": completed_dt.isoformat(),
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
