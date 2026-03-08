import json
import datetime
from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from firebase_admin import firestore

from schemas import PatientSchema
from services.firebase import db, upload_file_to_firebase


router = APIRouter()


@firestore.transactional
def get_next_patient_id(transaction):
    current_prefix = datetime.date.today().strftime("%y%m")
    prefix_label = "PT"
    counter_ref = db.collection("metadata").document(f"counters_{current_prefix}")

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


@router.post("/create-patient-profile")
async def create_patient_profile(
    patient_data: str = Form(...),
    image: UploadFile = File(None)
):
    try:
        print("[create-patient-profile] received request")
        raw_json = json.loads(patient_data)
        print("[create-patient-profile] parsed patient_data json")
        patient_obj = PatientSchema(**raw_json)
        print("[create-patient-profile] validated PatientSchema")

        transaction = db.transaction()
        print("[create-patient-profile] created Firestore transaction")
        new_id = get_next_patient_id(transaction)
        print(f"[create-patient-profile] new patient id: {new_id}")

        photo_url = None
        if image is not None:
            print("[create-patient-profile] image provided, uploading")
            image_content = await image.read()
            content_type = image.content_type
            photo_url = upload_file_to_firebase(
                file_content=image_content,
                patient_id=new_id,
                folder="profile",
                filename="profile_photo.jpg",
                content_type=content_type,
            )
            print("[create-patient-profile] image uploaded")

        doc_data = {
            "patient_name": patient_obj.patient_name,
            "phone_no": patient_obj.phone_no,
            "dob": patient_obj.dob,
            "gender": patient_obj.gender,
            "height_cm": float(patient_obj.height_cm),
            "weight_kg": float(patient_obj.weight_kg),
            "medical_history": patient_obj.medical_history,
            "diabetes": patient_obj.diabetes.dict(),
            "status": patient_obj.status,
            "created_at": patient_obj.created_at,
            "synced_at": firestore.SERVER_TIMESTAMP,
            "photo_url": photo_url,
        }

        db.collection("patients").document(new_id).set(doc_data)
        print("[create-patient-profile] patient document written")

        print(f"Successfully registered: {new_id} for {patient_obj.patient_name}")

        return {
            "status": "success",
            "patient_id": new_id,
            "photo_url": photo_url,
            "message": f"Profile created for {patient_obj.patient_name}"
        }

    except Exception as e:
        import traceback
        print(f"[create-patient-profile ERROR] {e}")
        print(traceback.format_exc())
        raise HTTPException(status_code=400, detail=f"Data format error: {str(e)}")
