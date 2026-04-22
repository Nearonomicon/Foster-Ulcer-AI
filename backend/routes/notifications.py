from fastapi import APIRouter, HTTPException
from fastapi.encoders import jsonable_encoder
from firebase_admin import firestore

from schemas import (
    NotificationDeviceRegistrationRequest,
    NotificationDeviceUnregisterRequest,
)
from services.firebase import db
from services.notifications import register_device_token, unregister_device_token


router = APIRouter()
NOTIFICATION_COLLECTIONS = {
    "DOCTOR": "all_doctor",
    "NURSE": "all_nurse",
}


def _normalize_limit(limit: int) -> int:
    if limit < 1:
        return 1
    if limit > 200:
        return 200
    return limit


def _list_notifications(collection_name: str, limit: int) -> list[dict]:
    notifications_ref = (
        db.collection(collection_name)
        .order_by("created_at", direction=firestore.Query.DESCENDING)
        .limit(limit)
    )

    notifications = []
    for doc in notifications_ref.stream():
        data = doc.to_dict() or {}
        data["notification_id"] = data.get("notification_id") or doc.id
        notifications.append(data)
    return notifications


def _normalize_notification_role(role: str | None) -> str | None:
    if role is None:
        return None
    normalized = role.strip().upper()
    if normalized in NOTIFICATION_COLLECTIONS:
        return normalized
    raise HTTPException(status_code=400, detail="role must be DOCTOR or NURSE")


def _collections_for_role(role: str | None) -> list[str]:
    normalized_role = _normalize_notification_role(role)
    if normalized_role:
        return [NOTIFICATION_COLLECTIONS[normalized_role]]
    return list(NOTIFICATION_COLLECTIONS.values())


def _read_update_payload() -> dict:
    return {
        "status": "READ",
        "read_at": firestore.SERVER_TIMESTAMP,
    }


@router.post("/notification-devices/register")
async def register_notification_device(payload: NotificationDeviceRegistrationRequest):
    try:
        device_token_id = register_device_token(
            user_id=payload.user_id.strip(),
            role=payload.role.value,
            fcm_token=payload.fcm_token.strip(),
            platform=payload.platform,
            device_id=payload.device_id,
        )
        return {
            "status": "success",
            "message": "Notification device registered",
            "device_token_id": device_token_id,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/notification-devices/unregister")
async def unregister_notification_device(payload: NotificationDeviceUnregisterRequest):
    try:
        device_token_id = unregister_device_token(fcm_token=payload.fcm_token.strip())
        return {
            "status": "success",
            "message": "Notification device unregistered",
            "device_token_id": device_token_id,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/notifications/{notification_id}/read")
async def mark_notification_read(notification_id: str, payload: dict | None = None):
    try:
        role = _normalize_notification_role((payload or {}).get("role"))
        collection_names = _collections_for_role(role)

        for collection_name in collection_names:
            notification_ref = db.collection(collection_name).document(notification_id)
            notification_snapshot = notification_ref.get()
            if not notification_snapshot.exists:
                continue

            notification_ref.set(_read_update_payload(), merge=True)
            return {
                "status": "success",
                "message": "Notification marked read",
                "notification_id": notification_id,
                "collection": collection_name,
            }

        raise HTTPException(status_code=404, detail="Notification not found")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/notifications/mark-all-read")
async def mark_all_notifications_read(payload: dict | None = None):
    try:
        role = _normalize_notification_role((payload or {}).get("role"))
        collection_names = _collections_for_role(role)
        updated_count = 0

        for collection_name in collection_names:
            unread_docs = (
                db.collection(collection_name)
                .where("status", "==", "UNREAD")
                .stream()
            )

            batch = db.batch()
            batch_count = 0
            for doc in unread_docs:
                batch.set(doc.reference, _read_update_payload(), merge=True)
                batch_count += 1
                updated_count += 1
                if batch_count == 500:
                    batch.commit()
                    batch = db.batch()
                    batch_count = 0

            if batch_count:
                batch.commit()

        return {
            "status": "success",
            "message": "Notifications marked read",
            "updated_count": updated_count,
            "role": role or "ALL",
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/doctor-notifications")
async def list_doctor_notifications(limit: int = 50):
    try:
        notifications = _list_notifications("all_doctor", _normalize_limit(limit))
        return {
            "status": "success",
            "notifications": jsonable_encoder(notifications),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/nurse-notifications")
async def list_nurse_notifications(limit: int = 50):
    try:
        notifications = _list_notifications("all_nurse", _normalize_limit(limit))
        return {
            "status": "success",
            "notifications": jsonable_encoder(notifications),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
