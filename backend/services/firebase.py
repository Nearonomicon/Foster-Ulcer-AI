"""Firebase Admin SDK initialization and storage helpers.

Credential resolution order:

1. Cloud Run / Cloud Functions: when the ``K_SERVICE`` environment variable is
   present we use the runtime's default application credentials.
2. ``GOOGLE_APPLICATION_CREDENTIALS``: standard Google env var pointing at a
   service-account JSON file. Used by all local development and CI environments.
3. ``FIREBASE_CREDENTIALS_PATH``: optional alternate env var for projects that
   already use ``GOOGLE_APPLICATION_CREDENTIALS`` for something else.

There is no hardcoded credential path. If none of the above are set, startup
fails with a clear error so the service never silently runs against the wrong
project.

The storage bucket can be overridden with ``FIREBASE_STORAGE_BUCKET``; it
defaults to the project's app-default bucket so the same image upload code
works across environments without code changes.
"""

from __future__ import annotations

import os
from typing import Optional

import firebase_admin
from firebase_admin import credentials, firestore, storage


_DEFAULT_BUCKET = "foster-ulcer-ai.firebasestorage.app"


def _resolve_credential_path() -> Optional[str]:
    """Return a credential file path if one is configured, else None."""
    for env_var in ("GOOGLE_APPLICATION_CREDENTIALS", "FIREBASE_CREDENTIALS_PATH"):
        value = os.getenv(env_var)
        if value and value.strip():
            return value.strip()
    return None


def _initialize_firebase_app() -> firebase_admin.App:
    """Initialize the Firebase Admin SDK exactly once.

    Idempotent: if the SDK is already initialized (e.g. in tests or when this
    module is reloaded) we return the existing app rather than crashing.
    """
    if firebase_admin._apps:
        return firebase_admin.get_app()

    bucket = os.getenv("FIREBASE_STORAGE_BUCKET", _DEFAULT_BUCKET)
    options = {"storageBucket": bucket}

    # Cloud Run / Cloud Functions: trust the runtime's default credentials.
    if os.getenv("K_SERVICE"):
        return firebase_admin.initialize_app(options=options)

    cred_path = _resolve_credential_path()
    if not cred_path:
        raise RuntimeError(
            "Firebase credentials are not configured. Set "
            "GOOGLE_APPLICATION_CREDENTIALS to the path of a service-account "
            "JSON file, or run inside Cloud Run where K_SERVICE is set. See "
            "backend/.env.example for the local-development template."
        )
    if not os.path.exists(cred_path):
        raise RuntimeError(
            f"Firebase credential file does not exist at: {cred_path}. "
            "Update GOOGLE_APPLICATION_CREDENTIALS to point at a valid "
            "service-account JSON."
        )

    cred = credentials.Certificate(cred_path)
    return firebase_admin.initialize_app(cred, options)


_initialize_firebase_app()

db = firestore.client()
bucket = storage.bucket()


def upload_file_to_firebase(file_content, patient_id, folder, filename, content_type):
    """Upload a patient-scoped asset to Firebase Storage and return its URL."""
    blob_path = f"patients/{patient_id}/{folder}/{filename}"
    blob = bucket.blob(blob_path)
    blob.upload_from_string(file_content, content_type=content_type)
    blob.make_public()
    return blob.public_url


def upload_case_image_to_firebase(file_content, case_id, record_id, filename, content_type):
    """Upload a case-scoped image asset to Firebase Storage and return its URL."""
    blob_path = f"cases/{case_id}/{record_id}/{filename}"
    blob = bucket.blob(blob_path)
    blob.upload_from_string(file_content, content_type=content_type)
    blob.make_public()
    return blob.public_url
