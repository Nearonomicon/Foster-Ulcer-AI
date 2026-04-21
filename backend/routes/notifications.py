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
