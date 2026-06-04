from __future__ import annotations

import hashlib
from datetime import datetime, timezone
from typing import Any

from firebase_admin import messaging

from services.firebase import db


DEVICE_COLLECTION = "notification_devices"


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _device_token_doc_id(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def _stringify_data(data: dict[str, Any]) -> dict[str, str]:
    payload: dict[str, str] = {}
    for key, value in data.items():
        if value is None:
            continue
        payload[key] = str(value)
    return payload


def register_device_token(
    *,
    user_id: str,
    role: str,
    fcm_token: str,
    platform: str | None = None,
    device_id: str | None = None,
) -> str:
    timestamp = _utc_now()
    document_id = _device_token_doc_id(fcm_token)
    db.collection(DEVICE_COLLECTION).document(document_id).set(
        {
            "device_token_id": document_id,
            "user_id": user_id,
            "role": role.upper(),
            "fcm_token": fcm_token,
            "platform": platform.lower() if isinstance(platform, str) and platform.strip() else None,
            "device_id": device_id.strip() if isinstance(device_id, str) and device_id.strip() else None,
            "is_active": True,
            "updated_at": timestamp,
            "created_at": timestamp,
            "unregistered_at": None,
        },
        merge=True,
    )
    return document_id


def unregister_device_token(*, fcm_token: str) -> str:
    timestamp = _utc_now()
    document_id = _device_token_doc_id(fcm_token)
    db.collection(DEVICE_COLLECTION).document(document_id).set(
        {
            "device_token_id": document_id,
            "fcm_token": fcm_token,
            "is_active": False,
            "updated_at": timestamp,
            "unregistered_at": timestamp,
        },
        merge=True,
    )
    return document_id


def _get_active_tokens_by_role(*, role: str) -> list[str]:
    query = (
        db.collection(DEVICE_COLLECTION)
        .where("role", "==", role.upper())
        .where("is_active", "==", True)
    )

    tokens: list[str] = []
    seen: set[str] = set()
    for doc in query.stream():
        data = doc.to_dict() or {}
        token = data.get("fcm_token")
        if not isinstance(token, str):
            continue
        normalized = token.strip()
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        tokens.append(normalized)
    return tokens


def _mark_tokens_inactive(tokens: list[str], *, reason: str) -> None:
    if not tokens:
        return

    batch = db.batch()
    timestamp = _utc_now()
    for token in tokens:
        document_id = _device_token_doc_id(token)
        doc_ref = db.collection(DEVICE_COLLECTION).document(document_id)
        batch.set(
            doc_ref,
            {
                "device_token_id": document_id,
                "fcm_token": token,
                "is_active": False,
                "updated_at": timestamp,
                "unregistered_at": timestamp,
                "invalid_reason": reason,
            },
            merge=True,
        )
    batch.commit()


def send_push_to_role(
    *,
    role: str,
    title: str,
    body: str,
    data: dict[str, Any] | None = None,
) -> dict[str, int]:
    tokens = _get_active_tokens_by_role(role=role)
    if not tokens:
        return {
            "tokens_found": 0,
            "success_count": 0,
            "failure_count": 0,
        }

    success_count = 0
    failure_count = 0
    invalid_tokens: list[str] = []
    payload_data = _stringify_data(data or {})

    for start in range(0, len(tokens), 500):
        token_chunk = tokens[start:start + 500]
        response = messaging.send_each_for_multicast(
            messaging.MulticastMessage(
                tokens=token_chunk,
                notification=messaging.Notification(title=title, body=body),
                data=payload_data,
            )
        )
        success_count += response.success_count
        failure_count += response.failure_count

        for idx, send_response in enumerate(response.responses):
            if send_response.success:
                continue
            if isinstance(send_response.exception, messaging.UnregisteredError):
                invalid_tokens.append(token_chunk[idx])

    if invalid_tokens:
        _mark_tokens_inactive(invalid_tokens, reason="UNREGISTERED")

    return {
        "tokens_found": len(tokens),
        "success_count": success_count,
        "failure_count": failure_count,
    }


def _create_notification(
    *,
    collection_name: str,
    payload: dict[str, Any],
    broadcast_role: str | None = None,
) -> str:
    notification_id = str(payload["notification_id"])
    db.collection(collection_name).document(notification_id).set(payload, merge=True)

    if broadcast_role:
        try:
            send_push_to_role(
                role=broadcast_role,
                title=str(payload.get("title") or "Notification"),
                body=str(payload.get("message") or ""),
                data={
                    "notification_id": notification_id,
                    "type": payload.get("type"),
                    "case_id": payload.get("case_id"),
                    "record_id": payload.get("record_id"),
                    "patient_id": payload.get("patient_id"),
                    "target_role": broadcast_role,
                },
            )
        except Exception as push_error:
            print(
                f"Warning: failed to broadcast push notification {notification_id} "
                f"to role {broadcast_role}: {push_error}"
            )
    return notification_id


def create_doctor_review_notification(
    *,
    case_id: str,
    record_id: str,
    patient_id: str | None = None,
    patient_name: str | None = None,
    urgency: str | None = None,
    assigned_doctor: str | None = None,
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

    return _create_notification(
        collection_name="all_doctor",
        payload=payload,
        broadcast_role="DOCTOR",
    )


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

    return _create_notification(
        collection_name="all_nurse",
        payload=payload,
        broadcast_role="NURSE",
    )


def create_doctor_healing_notification(
    *,
    case_id: str,
    record_id: str,
    patient_id: str | None = None,
    patient_name: str | None = None,
    urgency: str | None = None,
    assigned_doctor: str | None = None,
) -> str:
    notification_time = _utc_now()
    notification_id = f"NTF-{notification_time.strftime('%Y%m%d%H%M%S%f')}"

    payload: dict[str, Any] = {
        "notification_id": notification_id,
        "type": "HEALING_ANALYSIS_READY",
        "case_id": case_id,
        "record_id": record_id,
        "patient_id": patient_id,
        "patient_name": patient_name,
        "urgency": urgency,
        "status": "UNREAD",
        "title": "Healing analysis ready",
        "message": f"Healing analysis is ready for case {case_id}.",
        "created_at": notification_time,
        "read_at": None,
    }

    return _create_notification(
        collection_name="all_doctor",
        payload=payload,
        broadcast_role="DOCTOR",
    )


def create_doctor_request_close_notification(
    *,
    case_id: str,
    record_id: str,
    patient_id: str | None = None,
    patient_name: str | None = None,
    urgency: str | None = None,
    assigned_doctor: str | None = None,
) -> str:
    notification_time = _utc_now()
    notification_id = f"NTF-{notification_time.strftime('%Y%m%d%H%M%S%f')}"

    payload: dict[str, Any] = {
        "notification_id": notification_id,
        "type": "REQUEST_CLOSE_TO_DOCTOR",
        "case_id": case_id,
        "record_id": record_id,
        "patient_id": patient_id,
        "patient_name": patient_name,
        "urgency": urgency,
        "status": "UNREAD",
        "title": "Case close requested",
        "message": f"Case {case_id} has been requested for close review.",
        "created_at": notification_time,
        "read_at": None,
    }

    return _create_notification(
        collection_name="all_doctor",
        payload=payload,
        broadcast_role="DOCTOR",
    )
