# Foster Ulcer AI Architecture

## 1. System overview

The project is a mobile-assisted wound care workflow system with AI analysis and Firebase-backed clinical record storage.

Primary layers:

- Flutter mobile client
- FastAPI backend
- Firestore document store
- Firebase Storage for images
- Firebase Cloud Messaging for push notifications
- Gemini for AI analysis

## 2. Backend architecture

Primary backend files:

- `app.py`
- `schemas.py`
- `routes/patients.py`
- `routes/cases.py`
- `routes/analysis.py`
- `routes/task.py`
- `routes/notifications.py`
- `services/firebase.py`
- `services/genai_client.py`
- `services/notifications.py`

### Backend responsibilities

`app.py`

- FastAPI app assembly
- CORS setup
- request/response logging
- exception handlers
- dashboard aggregation route

`routes/patients.py`

- patient create
- patient list
- patient patch

`routes/cases.py`

- case lifecycle
- record lifecycle
- send-to-doctor
- doctor review
- appointment
- close request
- case completion

`routes/analysis.py`

- audio transcription
- image prefill analysis
- layered wound analysis
- healing progression analysis

`routes/task.py`

- task list
- task detail
- task update

`routes/notifications.py`

- FCM token registration
- notification feed read APIs

## 3. Frontend architecture

Primary frontend files:

- `lib/main.dart`
- `lib/widgets/foster_ulcer_app.dart`
- `lib/widgets/main_navigation_screen.dart`
- `lib/services/notification_service.dart`

### Key frontend observation

The app is functionally rich but structurally concentrated in one very large stateful controller:

- `lib/widgets/main_navigation_screen.dart`

That file owns:

- app navigation
- API calling
- intake flow
- assessment flow
- tasks flow
- case flow
- notification flow
- camera behavior
- audio behavior

This architecture works for prototyping but creates long-term maintenance and regression risk.

## 4. Data flow

### New case flow

1. Create or find patient.
2. Create case.
3. Upload wound image for prefill.
4. Review and edit clinical assessment.
5. Run wound analysis.
6. Send to doctor.

### Follow-up flow

1. Find patient and existing case.
2. Create follow-up record.
3. Upload new image.
4. Review and update assessment.
5. Run wound analysis.
6. Optionally run healing analysis.
7. Send to doctor if needed.

### Task execution flow

1. Load active plans from current case snapshots.
2. Open current treatment.
3. Update task status and evidence.
4. Persist updates to case snapshot, record snapshot, and plan-version task docs.

## 5. Persistence model

Main collections:

- `patients`
- `cases`
- `notification_devices`
- `all_doctor`
- `all_nurse`
- `metadata`

Nested collections actually used:

- `cases/{case_id}/records/{record_id}`
- `cases/{case_id}/records/{record_id}/analysis_versions/{analysis_id}`
- `cases/{case_id}/records/{record_id}/plan_versions/{plan_id}`
- `cases/{case_id}/records/{record_id}/plan_versions/{plan_id}/tasks/{task_id}`

Design pattern in use:

- current snapshot fields are duplicated on the case document for quick UI access
- historical detail is retained per record and per plan/version subcollection

## 6. Notification design

Current notification model:

- backend writes shared role feeds
- backend broadcasts push by role
- frontend registers one device token to a role

Strength:

- simple broadcast model for nurse-app and doctor-app separation

Weakness:

- not user-specific
- shared read state
- limited audit precision

## 7. Security and operational architecture observations

- No API authentication
- No role authorization
- Open CORS policy
- Firestore credentials are hardcoded for local development path in backend source

These are significant delivery concerns for a clinical product.

## 8. Architecture strengths

- Clear case and record history model
- Good use of current snapshot plus historical versioning
- Push notifications integrated end-to-end
- AI analysis split into image prefill, wound analysis, and healing analysis

## 9. Architecture weaknesses

- Frontend orchestration is too centralized
- Backend route layer directly handles storage concerns with little abstraction
- Contract consistency is weak across routes, docs, and schema
- Status model is inconsistent
- Security model is effectively absent

## 10. Recommended target architecture improvements

- Add authenticated API gateway and role enforcement
- Split mobile app into feature modules and service/repository layers
- Introduce backend repository/service boundaries around Firestore
- Normalize API responses and status vocabulary
- Move secrets and credentials fully into environment-based configuration
