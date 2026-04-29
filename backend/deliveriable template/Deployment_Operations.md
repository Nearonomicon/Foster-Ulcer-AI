# Foster Ulcer AI Deployment and Operations

## 1. Runtime components

Backend dependencies:

- `fastapi`
- `uvicorn`
- `python-multipart`
- `google-genai`
- `python-dotenv`
- `pillow`
- `pandas`
- `firebase-admin`

Frontend dependencies of note:

- `http`
- `image_picker`
- `camera`
- `record`
- `audioplayers`
- `firebase_core`
- `firebase_messaging`
- `flutter_local_notifications`

## 2. Environment dependencies

Backend expects:

- Firestore access
- Firebase Storage access
- Firebase Admin credentials
- Gemini API key

Observed configuration:

- `GEMINI_API_KEY` loaded from environment
- Firebase local credentials referenced by absolute file path in `services/firebase.py`
- Cloud Run path uses `K_SERVICE` detection

## 3. Deployment observations

### Backend

Entry point:

- `main.py` runs Uvicorn on port `8080`

Cloud behavior:

- backend appears prepared for Cloud Run
- storage bucket set to `foster-ulcer-ai.firebasestorage.app`

### Frontend

Observed target platforms:

- Android
- iOS
- Web
- Windows
- Linux
- macOS

Practical production focus from implementation:

- mobile-first, especially Android

## 4. Operational risks

### Risk 1: Hardcoded local credential path

`services/firebase.py` references a machine-specific path for local admin credentials.

Impact:

- non-portable setup
- fragile onboarding
- secret-handling risk

### Risk 2: No auth on medical API

All reviewed endpoints are unauthenticated.

Impact:

- open access to patient data
- open write access to clinical records
- high delivery and compliance risk

### Risk 3: Open CORS

Backend allows all origins, methods, and headers.

Impact:

- broad browser access surface

### Risk 4: Shared notification feeds

Notification feeds are role-based shared queues.

Impact:

- any nurse-app instance can read and mark shared nurse notifications
- any doctor-app instance can read and mark shared doctor notifications

### Risk 5: AI dependency in core workflow

Clinical workflow depends heavily on Gemini availability and response quality.

Impact:

- degraded service if quota, latency, or model errors occur

## 5. Recommended deployment standard

Before production:

- move Firebase credential path to environment configuration
- add API authentication and role-based authorization
- restrict CORS to known client origins
- define staging and production environments separately
- enable structured logging and trace IDs
- add rate limiting and request audit logging

## 6. Monitoring recommendations

Track:

- API response time
- non-200 route rates
- Gemini failure rates
- image upload failures
- notification send failures
- case lifecycle transition counts

## 7. Backup and recovery considerations

Critical stores:

- Firestore case and patient records
- Firebase Storage wound and profile images

Recommended controls:

- regular Firestore export
- storage retention policy
- incident recovery runbook

## 8. Release-readiness summary

Current state is suitable for:

- prototype
- internal demo
- controlled pilot with engineering supervision

Current state is not suitable for:

- broad production use with patient data

without security, testing, and environment hardening.

