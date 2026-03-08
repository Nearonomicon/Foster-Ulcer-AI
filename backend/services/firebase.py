import firebase_admin
import os
from firebase_admin import credentials, firestore, storage



if os.getenv("K_SERVICE"): # This variable only exists on Cloud Run
    firebase_admin.initialize_app(options={
        'storageBucket': 'foster-ulcer-ai.firebasestorage.app'
    })
else:
    cred = credentials.Certificate("C:/Users/Pawarit/Desktop/foster-ulcer-ai-firebase-adminsdk-fbsvc-6eda7ee8ab.json")
    firebase_admin.initialize_app(cred, {
        "storageBucket": "foster-ulcer-ai.firebasestorage.app"
    })


db = firestore.client()
bucket = storage.bucket()


def upload_file_to_firebase(file_content, patient_id, folder, filename, content_type):
    blob_path = f"patients/{patient_id}/{folder}/{filename}"
    blob = bucket.blob(blob_path)
    blob.upload_from_string(file_content, content_type=content_type)
    blob.make_public()
    return blob.public_url


def upload_case_image_to_firebase(file_content, case_id, record_id, filename, content_type):
    blob_path = f"cases/{case_id}/{record_id}/{filename}"
    blob = bucket.blob(blob_path)
    blob.upload_from_string(file_content, content_type=content_type)
    blob.make_public()
    return blob.public_url
