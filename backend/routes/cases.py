import json
from datetime import date, datetime
from fastapi import APIRouter, HTTPException
from firebase_admin import firestore

from schemas import (
    CreateCaseRequest,
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
from utils import _model_to_dict


router = APIRouter()


@firestore.transactional
def get_next_case_id(transaction):
    current_prefix = date.today().strftime("%y%m%d")
    prefix_label = "CS"
    counter_ref = db.collection("metadata").document(f"counters_case_{current_prefix}")
    snapshot = transaction.get(counter_ref)
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
            heart_rate=(payload.vitals.heart_rate if payload.vitals else None),
            respiratory_rate=(
                payload.vitals.respiratory_rate
                if payload.vitals and payload.vitals.respiratory_rate is not None
                else (payload.vitals.repiratory_rate if payload.vitals else None)
            ),
            blood_glucose=(payload.vitals.blood_sugar if payload.vitals else None),
        )

        sent_at_raw = payload.meta.sent_at if payload.meta else None
        created_at = datetime.utcnow()
        if sent_at_raw:
            try:
                created_at = datetime.strptime(sent_at_raw, "%Y-%m-%d %H:%M:%S")
            except ValueError:
                created_at = datetime.utcnow()

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


@router.post("/send-to-doctor")
async def send_to_doctor(payload: WoundCaseRecordUpdate):
    try:
        payload_dict = _model_to_dict(payload)
        print("send-to-doctor received payload:", json.dumps(payload_dict, ensure_ascii=False))

        case_id = payload.case_id
        record_id = payload.record_id

        case_ref = db.collection("cases").document(case_id)
        record_ref = case_ref.collection("records").document(record_id)

        analysis_id = f"AN-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
        plan_id = f"PL-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"

        analysis_ref = record_ref.collection("analysis_versions").document(analysis_id)
        plan_ref = record_ref.collection("plan_versions").document(plan_id)

        record_data = payload_dict
        if record_data.get("timestamps") is None:
            record_data["timestamps"] = {
                "created_at": payload.record_created_at or firestore.SERVER_TIMESTAMP,
                "updated_at": firestore.SERVER_TIMESTAMP,
                "analyze_at": firestore.SERVER_TIMESTAMP,
                "doctor_review_at": None,
                "plan_issued_at": None,
                "treatment_active_at": None,
                "appointment_at": None,
                "completed_at": None,
            }
        if record_data.get("image") is None:
            record_data["image"] = {"image_folder_url": None}
        record_data["record_updated_at"] = firestore.SERVER_TIMESTAMP
        record_data["timestamps"]["updated_at"] = firestore.SERVER_TIMESTAMP
        record_data["timestamps"]["analyze_at"] = firestore.SERVER_TIMESTAMP

        analysis_payload = payload_dict.get("analysis")
        analysis_data = {
            "analysis_id": analysis_id,
            "case_id": case_id,
            "record_id": record_id,
            "status": "DRAFT",
            "source": "AI",
            "created_at": firestore.SERVER_TIMESTAMP,
            "payload": analysis_payload,
        }

        treatment_plan = payload_dict.get("treatment_plan") or {}
        plan_data = {
            "plan_id": plan_id,
            "case_id": case_id,
            "record_id": record_id,
            "created_at": firestore.SERVER_TIMESTAMP,
            "status": treatment_plan.get("status") or "DRAFT",
            "plan_text": treatment_plan.get("plan_text"),
            "followup_days": treatment_plan.get("followup_days"),
        }

        tasks = payload_dict.get("task_list") or treatment_plan.get("plan_tasks") or []

        batch = db.batch()
        batch.set(case_ref, {
            "status": Status.DOCTOR_REVIEW,
            "urgency": payload.urgency,
            "case_updated_at": firestore.SERVER_TIMESTAMP,
            "current_record_id": record_id,
            "current_analysis_id": analysis_id,
            "current_plan_id": plan_id,
        }, merge=True)
        batch.set(record_ref, record_data, merge=True)
        batch.set(analysis_ref, analysis_data, merge=True)
        batch.set(plan_ref, plan_data, merge=True)

        for idx, task in enumerate(tasks, start=1):
            task_id = f"TSK-{idx:04d}"
            task_ref = plan_ref.collection("tasks").document(task_id)
            batch.set(task_ref, {
                "task_id": task_id,
                "case_id": case_id,
                "record_id": record_id,
                "plan_id": plan_id,
                "created_at": firestore.SERVER_TIMESTAMP,
                "task_text": task.get("task_text"),
                "status": task.get("status"),
                "task_due": task.get("task_due"),
            }, merge=True)

        batch.commit()

        return {
            "status": "success",
            "message": "Case sent for doctor review",
            "case_id": case_id,
            "record_id": record_id,
            "analysis_id": analysis_id,
            "plan_id": plan_id,
        }

    except Exception as e:
        print(f"Error sending to doctor: {e}")
        raise HTTPException(status_code=500, detail=str(e))
