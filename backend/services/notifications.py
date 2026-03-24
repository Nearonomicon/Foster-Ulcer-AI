from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from services.firebase import db


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def create_doctor_review_notification(
    *,
    case_id: str,
    record_id: str,
    patient_id: str | None = None,
    patient_name: str | None = None,
    urgency: str | None = None,
) -> str:
    notification_time = _utc_now()
    notification_id = f"NTF-{notification_time.strftime('%Y%m%d%H%M%S%f')}"

    payload: dict[str, Any] = {
        "notification_id": notification_id,
        "type": "CASE_SENT_TO_DOCTOR",
        "case_id": case_id,
        "record_id": record_id,
        "patient_id": patient_id,
        "patient_name": patient_name,
        "urgency": urgency,
        "status": "UNREAD",
        "title": "New case for review",
        "message": f"Case {case_id} is ready for doctor review.",
        "created_at": notification_time,
        "read_at": None,
    }

    notification_ref = db.collection("all_doctor").document(notification_id)
    notification_ref.set(payload, merge=True)
    return notification_id


def create_nurse_plan_issued_notification(
    *,
    case_id: str,
    record_id: str,
    patient_id: str | None = None,
    patient_name: str | None = None,
    urgency: str | None = None,
    created_by_nurse: str | None = None,
) -> str:
    notification_time = _utc_now()
    notification_id = f"NTF-{notification_time.strftime('%Y%m%d%H%M%S%f')}"

    payload: dict[str, Any] = {
        "notification_id": notification_id,
        "type": "PLAN_ISSUED_TO_NURSE",
        "case_id": case_id,
        "record_id": record_id,
        "patient_id": patient_id,
        "patient_name": patient_name,
        "urgency": urgency,
        "created_by_nurse": created_by_nurse,
        "status": "UNREAD",
        "title": "Plan ready",
        "message": f"Doctor review is complete for case {case_id}.",
        "created_at": notification_time,
        "read_at": None,
    }

    notification_ref = db.collection("all_nurse").document(notification_id)
    notification_ref.set(payload, merge=True)
    return notification_id
