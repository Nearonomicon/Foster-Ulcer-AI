# Wound Care AI API Specification Report

## 1. Overview

- Application: `Wound Care AI Analysis API`
- Framework: FastAPI
- Default base URL: `http://127.0.0.1:8000`
- Authentication: none implemented
- CORS: `allow_origins=["*"]`, `allow_methods=["*"]`, `allow_headers=["*"]`
- Content types used:
  - `application/json`
  - `multipart/form-data`

This document summarizes the API as implemented in the backend source, primarily [`app.py`](/backend/app.py), [`routes/patients.py`](/backend/routes/patients.py), [`routes/cases.py`](/backend/routes/cases.py), [`routes/analysis.py`](/backend/routes/analysis.py), [`routes/task.py`](/backend/routes/task.py), and [`schemas.py`](/backend/schemas.py).

## 2. Global Behavior

- Success responses are not fully standardized. Most endpoints return a JSON object with a `status` field.
- Error responses are standardized by FastAPI exception handlers:
  - `HTTPException` -> `{"detail": ...}`
  - validation error -> `{"detail": [...]}` with FastAPI/Pydantic error details
  - unhandled error -> `{"detail": "Internal Server Error"}`
- Several endpoints clamp `limit` values instead of rejecting them.
- Timestamps are a mix of client-supplied strings, Python `datetime`, and Firestore server timestamps.
- Route names are not versioned.

## 3. Enumerations

### Case Status

- `CREATION`
- `AI_PROCESSING`
- `DOCTOR_REVIEW`
- `PLAN_ISSUED`
- `TREATMENT_ACTIVE`
- `APPOINTMENT`
- `COMPLETED`

### Urgency

- `URGENT`
- `MEDIUM`
- `LOW`

### Wound Shape

- `round`
- `oval`
- `irregular`
- `linear`
- `punched_out`

### Depth Category

- `superficial`
- `partial_thickness`
- `full_thickness`
- `deep`
- `very_deep_exposed_bone_tendon`

## 4. Endpoint Summary

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/load-dashboard` | Load dashboard summary |
| `POST` | `/create-patient-profile` | Create a patient profile |
| `GET` | `/patients_list` | List patients |
| `PATCH` | `/patients/{patient_id}` | Partially update patient profile |
| `POST` | `/create-case` | Create a new case and first record |
| `POST` | `/update_cases` | Create a follow-up record for an existing case |
| `POST` | `/cases_list` | List cases |
| `POST` | `/case_detail` | Load one case, its records, and patient profile |
| `POST` | `/send-to-doctor` | Finalize a record for doctor review and create analysis/plan versions |
| `POST` | `/doctor-review` | Save doctor-edited analysis as a doctor-sourced analysis version |
| `POST` | `/notification-devices/register` | Register an app device FCM token for role broadcast |
| `POST` | `/notification-devices/unregister` | Deactivate an app device FCM token |
| `GET` | `/doctor-notifications` | List shared doctor notifications |
| `GET` | `/nurse-notifications` | List shared nurse notifications |
| `POST` | `/notifications/{notification_id}/read` | Mark one doctor/nurse notification as read |
| `POST` | `/notifications/mark-all-read` | Mark all doctor/nurse notifications as read |
| `POST` | `/analyze-fillin` | Upload wound image and return structured fill-in output |
| `POST` | `/analyze-wound` | Run layered AI wound analysis |
| `POST` | `/analyze-healing` | Generate healing-progress summary from records |
| `POST` | `/tasks_list` | List current treatment plans that contain tasks |
| `POST` | `/task_detail` | Load current treatment plan or one selected task |
| `POST` | `/task_update` | Update tasks on current plan |

## 5. Endpoint Specifications

### 5.1 `GET /load-dashboard`

**Purpose**

Returns dashboard summary values and upcoming incomplete tasks.

**Request body**

None.

**Response 200**

```json
{
  "status": "success",
  "today_task_no": 0,
  "upcoming_plan": [
    {
      "patient_name": "John Doe",
      "status": "TREATMENT_ACTIVE",
      "urgency": "URGENT",
      "case_updated_at": "2026-03-24T08:30:00+00:00",
      "task_due": "2026-03-24",
      "patient_photo_url": "https://..."
    }
  ]
}
```

### 5.2 `POST /create-patient-profile`

**Purpose**

Creates a patient document and optionally uploads a profile image.

**Content-Type**

`multipart/form-data`

**Form fields**

| Field | Type | Required | Notes |
|---|---|---|---|
| `patient_data` | string | Yes | JSON string parsed into `PatientSchema` |
| `image` | file | No | Uploaded as `profile_photo.jpg` |

**`patient_data` fields**

| Field | Type | Required |
|---|---|---|
| `nrc_id` | string | No |
| `patient_name` | string | Yes |
| `phone_no` | string | Yes |
| `dob` | string | Yes |
| `gender` | string | Yes |
| `height_cm` | string or number | Yes |
| `weight_kg` | string or number | Yes |
| `medical_history` | string | Yes |
| `diabetes` | object | Yes |
| `diabetes.has_diabetes` | string | Yes |
| `diabetes.years` | string | No |
| `diabetes.risk_history` | string[] | No |
| `diabetes.complications` | string[] | No |
| `created_at` | string | Yes |
| `status` | string | No, default `"Active"` |

**Stored behavior**

- Generates patient ID as `PT-YYMM-#####`
- Casts `height_cm` and `weight_kg` to `float`
- Sets `synced_at` with Firestore server timestamp
- Stores uploaded image URL in `photo_url`

**Response 200**

```json
{
  "status": "success",
  "patient_id": "PT-2603-00001",
  "photo_url": "https://...",
  "message": "Profile created for John Doe"
}
```

**Errors**

- `400` if `patient_data` is invalid JSON or fails schema validation

### 5.3 `GET /patients_list`

**Purpose**

Returns patient documents ordered by `created_at` descending.

**Query parameters**

| Field | Type | Required | Notes |
|---|---|---|---|
| `limit` | integer | No | Default `50`, clamped to `1..200` |

**Response 200**

```json
{
  "status": "success",
  "patients": [
    {
      "patient_id": "PT-2603-00001",
      "patient_name": "John Doe"
    }
  ]
}
```

**Errors**

- `500` on server/database failure

### 5.4 `PATCH /patients/{patient_id}`

**Purpose**

Partially updates a patient document.

**Path parameters**

| Field | Type | Required |
|---|---|---|
| `patient_id` | string | Yes |

**Request body**

JSON object. Any provided field with a non-null value is merged into the patient document.

**Behavior**

- Null values are discarded
- `height_cm` and `weight_kg` are cast to `float` if present
- `synced_at` is always added to the update payload

**Response 200**

```json
{
  "status": "success",
  "patient_id": "PT-2603-00001",
  "updated_fields": ["phone_no", "weight_kg", "synced_at"]
}
```

**Errors**

- `400` if no non-null fields are provided
- `500` on server/database failure

### 5.5 `POST /create-case`

**Purpose**

Creates a case document and its first record.

**Request body**

JSON matching `CreateCaseRequest`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `patient_id` | string | Yes | |
| `status` | string | No | Invalid values fall back to `CREATION` |
| `urgency` | string | No | Invalid values become `null` |
| `created_by_nurse` | string | No | |
| `assigned_doctor` | string | No | |
| `vitals` | object | No | |
| `vitals.temperature` | string | No | |
| `vitals.blood_pressure` | string | No | |
| `vitals.heart_rate` | string | No | |
| `vitals.respiratory_rate` | string | No | |
| `vitals.blood_sugar` | string | No | Stored as `blood_glucose` |
| `meta` | object | No | |
| `meta.sent_at` | string | No | Parsed using `%Y-%m-%d %H:%M:%S`, otherwise current UTC |

**Behavior**

- Generates case ID as `CS-YYMMDD-#####`
- First record ID is always `REC-00001`
- Creates empty default sections for wound detail, ischemia, infection, neuropathy, sinbad, lab results, vascular, and image
- Copies current record snapshot into top-level `current_*` fields on the case

**Response 200**

```json
{
  "status": "Case creation success",
  "patient_id": "PT-2603-00001",
  "case_id": "CS-260318-00001",
  "record_id": "REC-00001"
}
```

**Errors**

- `500` on server/database failure

### 5.6 `POST /update_cases`

**Purpose**

Creates a new follow-up record for an existing case and updates the case snapshot.

**Request body**

JSON matching `UpdateCaseRequest`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `patient_id` | string | Yes | Must match stored case patient if one exists |
| `case_id` | string | Yes | |
| `status` | string | No | Invalid values fall back to `CREATION` |
| `urgency` | string | No | Invalid values become `null` |
| `created_by_nurse` | string | No | |
| `assigned_doctor` | string | No | |
| `vitals` | object | No | Same structure as `/create-case` |
| `meta.sent_at` | string | No | Same parsing behavior as `/create-case` |

**Behavior**

- Computes next record ID from latest record number
- Builds a new record, then merges non-null sections from the latest/current record into:
  - `vital_signs`
  - `wound_detail`
  - `ischemia`
  - `infection`
  - `neuropathy`
  - `sinbad`
  - `lab_results`
  - `vascular`
  - `gangrene_extent`
  - `treatment_plan`
  - `analysis`
- If the latest record has a treatment plan, duplicates it with a new `plan_id`
- Task data is carried forward through `treatment_plan.plan_tasks`; deprecated `task_list` and `current_task_list` snapshots are deleted on new writes
- Updates case `current_record_id`, clears `current_analysis_id`, and sets `current_plan_id` to the duplicated plan ID if one was created

**Response 200**

```json
{
  "status": "Case update success",
  "patient_id": "PT-2603-00001",
  "case_id": "CS-260318-00001",
  "record_id": "REC-00002"
}
```

**Errors**

- `400` if `case_id` is missing
- `400` if `patient_id` does not match the case
- `404` if case does not exist
- `500` on server/database failure

### 5.7 `POST /cases_list`

**Purpose**

Lists case documents.

**Request body**

JSON object.

| Field | Type | Required | Notes |
|---|---|---|---|
| `limit` | integer | No | Default `50`, clamped to `1..200` |
| `patient_id` | string | No | Filters by patient |

**Behavior**

- With `patient_id`: filters by patient and does not apply ordering
- Without `patient_id`: orders by `case_updated_at` descending

**Response 200**

```json
{
  "status": "success",
  "cases": [
    {
      "case_id": "CS-260318-00001",
      "patient_id": "PT-2603-00001",
      "current_record_id": "REC-00002"
    }
  ]
}
```

**Errors**

- `500` on server/database failure

### 5.8 `POST /case_detail`

**Purpose**

Returns one case, its records, and its patient profile.

**Request body**

| Field | Type | Required |
|---|---|---|
| `case_id` | string | Yes |

**Behavior**

- Case is loaded from `cases/{case_id}`
- Records are ordered by `record_created_at` ascending
- Patient profile is loaded using the case `patient_id` if present

**Response 200**

```json
{
  "status": "success",
  "case": {},
  "records": [],
  "patient_profile": {}
}
```

**Errors**

- `400` if `case_id` is missing
- `404` if case does not exist
- `500` on server/database failure

### 5.9 `POST /send-to-doctor`

**Purpose**

Validates a completed wound case record payload, merges it into the target record, creates analysis and plan versions, and marks the case as `DOCTOR_REVIEW`.

**Request body**

JSON matching `WoundCaseRecordUpdate`.

**Required top-level fields**

| Field | Type | Required |
|---|---|---|
| `record_id` | string | Yes |
| `case_id` | string | Yes |
| `patient_id` | string | Yes |
| `vital_signs` | object | Yes |
| `wound_detail` | object | Yes |
| `ischemia` | object | Yes |
| `infection` | object | Yes |
| `neuropathy` | object | Yes |
| `sinbad` | object | Yes |
| `lab_results` | object | Yes |
| `vascular` | object | Yes |

Other fields from `WoundCaseRecord` may also be supplied, including `urgency`, `analysis`, `treatment_plan`, deprecated `task_list` fallback input, `timestamps`, and `image`.

**Behavior**

- Merges non-null incoming sections with the existing record
- If `timestamps` is missing, creates one and stamps `updated_at` and `analyze_at`
- Sets `record_updated_at` to Firestore server timestamp
- Generates:
  - `analysis_id` as `AN-YYYYMMDDHHMMSS`
  - `plan_id` as `PL-YYYYMMDDHHMMSS`
- Creates `analysis_versions/{analysis_id}`
- Creates `plan_versions/{plan_id}`
- Builds tasks from `treatment_plan.plan_tasks`; falls back to deprecated `task_list` only for older payload compatibility
- Auto-generates `task_id` values as `TSK-0001`, `TSK-0002`, ... when missing
- Defaults missing task `source` values to `AI`
- Writes tasks to `records/{record_id}.treatment_plan.plan_tasks`, `cases/{case_id}.current_treatment_plan.plan_tasks`, and plan-version task documents
- Deletes deprecated `records/{record_id}.task_list` and `cases/{case_id}.current_task_list`
- Creates a shared doctor notification in `all_doctor/{notification_id}`
- Broadcasts FCM push to active device tokens registered with role `DOCTOR`
- Writes current snapshot back to the case and sets:
  - `status = DOCTOR_REVIEW`
  - `current_record_id`
  - `current_analysis_id`
  - `current_plan_id`

**Response 200**

```json
{
  "status": "success",
  "message": "Case sent for doctor review",
  "case_id": "CS-260318-00001",
  "record_id": "REC-00002",
  "analysis_id": "AN-20260318120000",
  "plan_id": "PL-20260318120000",
  "notification_id": "NTF-20260318120000123456"
}
```

**Errors**

- `422` if required nested sections are missing according to Pydantic validation
- `500` on server/database failure

### 5.10 `POST /doctor-review`

**Purpose**

Creates a doctor-sourced `analysis_versions/{analysis_id}` entry for an existing record and updates the current analysis snapshot on the record and case.

**Request body**

| Field | Type | Required | Notes |
|---|---|---|---|
| `case_id` | string | Yes | |
| `record_id` | string | Yes | |
| `analysis` | object | Yes | Preferred doctor-edited analysis payload |
| `analysis_id` | string | No | Source analysis version to copy `SINBAD` from; falls back to case `current_analysis_id` |
| `treatment_plan` | object | No | Doctor-reviewed treatment plan snapshot |
| `ai_result_edit_flag` | boolean | No | Optional UI flag stored inside the saved review payload |
| `treatment_plan_edit_flag` | boolean | No | Optional UI flag stored inside the saved review payload |
| `signature` | string or object | No | Added into the stored review payload |
| `signature_base64` | string | No | Stored on record and inside the saved review payload |
| `payload` | object | No | Legacy wrapper accepted for backward compatibility; prefer top-level `analysis` and `treatment_plan` |

Any incoming `analysis_id`, `status`, `source`, or `created_at` values are not used. The backend generates and stores:

- `analysis_id`
- `status = "SENT"`
- `source = "Doctor"`
- `created_at = Firestore server timestamp`

**Stored analysis version format**

```json
{
  "analysis_id": "AN-YYYYMMDDHHMMSS",
  "case_id": "CS-...",
  "record_id": "REC-...",
  "status": "SENT",
  "source": "Doctor",
  "created_at": "Firestore server timestamp",
  "payload": {
    "analysis": {
      "...": "doctor-edited analysis",
      "healing_progress": "..."
    },
    "treatment_plan": {
      "plan_text": "...",
      "plan_tasks": []
    },
    "ai_result_edit_flag": true,
    "treatment_plan_edit_flag": true
  }
}
```

**Behavior**

- Validates that the case and record exist
- Accepts doctor analysis from top-level `analysis`
- Also accepts legacy `payload.analysis`, `payload.AI_analysis`, or `payload` directly for backward compatibility
- Creates a new doctor-sourced analysis version under the record
- Creates a new `plan_versions/{plan_id}` and task documents when a treatment plan is provided
- Copies `analysis.classifications.SINBAD` from the previous analysis version so the doctor cannot overwrite it
- If `signature` is provided, stores it inside the saved analysis payload
- If `signature_base64` is provided, stores it on the record and inside the saved analysis payload
- If `treatment_plan` is provided, updates:
  - `records/{record_id}.treatment_plan`
  - `cases/{case_id}.current_treatment_plan`
  - `cases/{case_id}.current_plan_id`
- Forces doctor plan tasks to `status = "SENT"`
- Preserves explicit task `order_index` values from the frontend and normalizes ordering before saving
- Defaults missing task `source` values to `Doctor` and preserves explicit task source values from the frontend
- Deletes deprecated `records/{record_id}.task_list` and `cases/{case_id}.current_task_list`
- Creates a shared nurse notification in `all_nurse/{notification_id}`
- Broadcasts FCM push to active device tokens registered with role `NURSE`
- Updates:
  - `records/{record_id}.analysis`
  - `records/{record_id}.status = PLAN_ISSUED`
  - `records/{record_id}.timestamps.doctor_review_at`
  - `cases/{case_id}.current_analysis`
  - `cases/{case_id}.current_analysis_id`
  - `cases/{case_id}.current_record_id`
  - `cases/{case_id}.status = PLAN_ISSUED`

**Response 200**

```json
{
  "status": "success",
  "message": "Doctor review saved",
  "analysis_id": "AN-YYYYMMDDHHMMSS",
  "plan_id": "PL-YYYYMMDDHHMMSS",
  "case_id": "CS-...",
  "record_id": "REC-...",
  "source": "Doctor",
  "sinbad_copied": true,
  "notification_id": "NTF-20260318123000123456"
}
```

### 5.11 `POST /notification-devices/register`

**Purpose**

Registers an app device FCM token so backend notifications can broadcast to the doctor or nurse app.

**Request body**

```json
{
  "user_id": "doctor-app",
  "role": "DOCTOR",
  "fcm_token": "<FCM_TOKEN>",
  "platform": "android",
  "device_id": "optional-device-id"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `user_id` | string | Yes | Stored for audit/debugging. Role controls broadcast targeting. |
| `role` | string | Yes | `DOCTOR` or `NURSE` |
| `fcm_token` | string | Yes | Firebase Messaging token |
| `platform` | string | No | Use `android` for Android clients |
| `device_id` | string | No | Optional app/device identifier |

**Behavior**

- Stores the token in Firestore `notification_devices`
- Uses a SHA-256 hash of the token as the document ID
- Marks the token active with `is_active = true`
- Broadcast targeting uses `role`, not `user_id`

**Response 200**

```json
{
  "status": "success",
  "message": "Notification device registered",
  "device_token_id": "<sha256-token-id>"
}
```

### 5.12 `POST /notification-devices/unregister`

**Purpose**

Marks an FCM token inactive.

**Request body**

```json
{
  "fcm_token": "<FCM_TOKEN>"
}
```

**Response 200**

```json
{
  "status": "success",
  "message": "Notification device unregistered",
  "device_token_id": "<sha256-token-id>"
}
```

### 5.13 `GET /doctor-notifications`

**Purpose**

Returns the shared doctor notification feed from Firestore `all_doctor`.

**Query params**

| Field | Type | Required | Notes |
|---|---|---|---|
| `limit` | integer | No | Default `50`, min `1`, max `200` |

**Response 200**

```json
{
  "status": "success",
  "notifications": [
    {
      "notification_id": "NTF-20260318120000123456",
      "type": "CASE_SENT_TO_DOCTOR",
      "case_id": "CS-260318-00001",
      "record_id": "REC-00002",
      "patient_id": "PT-2603-00001",
      "patient_name": "John Doe",
      "urgency": "URGENT",
      "status": "UNREAD",
      "title": "New case for review",
      "message": "Case CS-260318-00001 is ready for doctor review.",
      "created_at": "2026-03-18T12:00:00.123456+00:00",
      "read_at": null
    }
  ]
}
```

### 5.14 `GET /nurse-notifications`

**Purpose**

Returns the shared nurse notification feed from Firestore `all_nurse`.

**Query params**

| Field | Type | Required | Notes |
|---|---|---|---|
| `limit` | integer | No | Default `50`, min `1`, max `200` |

**Response 200**

```json
{
  "status": "success",
  "notifications": [
    {
      "notification_id": "NTF-20260318123000123456",
      "type": "PLAN_ISSUED_TO_NURSE",
      "case_id": "CS-260318-00001",
      "record_id": "REC-00002",
      "patient_id": "PT-2603-00001",
      "patient_name": "John Doe",
      "urgency": "URGENT",
      "created_by_nurse": "NURSE-001",
      "status": "UNREAD",
      "title": "Plan ready",
      "message": "Doctor review is complete for case CS-260318-00001.",
      "created_at": "2026-03-18T12:30:00.123456+00:00",
      "read_at": null
    }
  ]
}
```

### 5.15 `POST /notifications/{notification_id}/read`

**Purpose**

Marks a single notification as read.

**Request body**

Optional JSON object.

```json
{
  "role": "DOCTOR"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `role` | string | No | `DOCTOR` or `NURSE`. If omitted, backend searches both shared feeds. |

**Behavior**

- Finds `{notification_id}` in `all_doctor` and/or `all_nurse`
- Updates `status = "READ"`
- Updates `read_at` to Firestore server timestamp

**Response 200**

```json
{
  "status": "success",
  "message": "Notification marked read",
  "notification_id": "NTF-20260422120000123456",
  "collection": "all_doctor"
}
```

**Errors**

- `400` if role is not `DOCTOR` or `NURSE`
- `404` if the notification ID is not found
- `500` on server/database failure

### 5.16 `POST /notifications/mark-all-read`

**Purpose**

Marks all unread notifications as read for one role feed, or both feeds if no role is provided.

**Request body**

Optional JSON object.

```json
{
  "role": "NURSE"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `role` | string | No | `DOCTOR` or `NURSE`. If omitted, marks both shared feeds. |

**Behavior**

- Queries unread notifications with `status = "UNREAD"`
- Updates each matched notification to `status = "READ"`
- Updates `read_at` to Firestore server timestamp
- Commits in batches of 500 writes

**Response 200**

```json
{
  "status": "success",
  "message": "Notifications marked read",
  "updated_count": 12,
  "role": "NURSE"
}
```

**Errors**

- `400` if role is not `DOCTOR` or `NURSE`
- `500` on server/database failure

### Notification Flow

- `POST /send-to-doctor` writes a shared doctor notification to `all_doctor`
- `POST /doctor-review` writes a shared nurse notification to `all_nurse`
- Doctor-side FCM broadcasts to all active `notification_devices` with `role = "DOCTOR"`
- Nurse-side FCM broadcasts to all active `notification_devices` with `role = "NURSE"`
- Both feeds are public shared queues for now, not user-specific inboxes
- Frontend reads them with `GET /doctor-notifications` and `GET /nurse-notifications`
- Frontend registers app tokens with `/notification-devices/register`; doctor app must use `DOCTOR`, nurse app must use `NURSE`

### Notification Delivery Options

| Option | How it works | Pros | Cons | Fit for current design |
|---|---|---|---|---|
| API polling | Mobile app calls notification APIs periodically | Simple, uses current REST backend, easy to debug | Delayed updates, extra battery/network use, more backend load, weak for backgrounded app | Current implementation |
| Firestore realtime listener | Mobile app listens directly to `all_doctor` or `all_nurse` | Near real-time, no polling loop, good while app is open | Requires Firebase client integration and careful security rules, weak for terminated app alerts | Good next step for live in-app bell updates |
| FCM push | Backend sends push notifications to device tokens | Best for background/closed app alerts, native OS notifications, efficient delivery | Requires token management, more setup, should not be sole source of truth | Good add-on when true push is needed |
| Firestore + FCM | Store notification in Firestore and also send FCM | Best overall design, reliable history plus instant alerting, app can recover missed pushes | More moving parts and implementation work | Recommended long term |
| WebSocket / SSE | Mobile app keeps a live connection to backend | Real-time without polling | More infra complexity, weaker mobile background behavior, more connection handling work | Usually not worth it here |

### Current Conclusion

| Question | Conclusion |
|---|---|
| What are we doing now? | Firestore notification history plus role-wide FCM broadcast |
| Why is it acceptable now? | Doctor and nurse are separate apps, so role-based broadcast maps directly to app type |
| Main limitation | Notification feeds are still shared role queues, not per-user inboxes |
| Recommended upgrade path | Add per-user unread tracking only if individual clinician inbox semantics become required |

**Errors**

- `400` if `case_id`, `record_id`, or `payload` is missing/invalid
- `404` if the case or record does not exist
- `500` on server/database failure

### 5.17 `POST /analyze-fillin`

**Purpose**

Uploads a wound image, stores its URL, and requests a structured AI fill-in result.

**Content-Type**

`multipart/form-data`

**Form fields**

| Field | Type | Required |
|---|---|---|
| `case_id` | string | Yes |
| `record_id` | string | Yes |
| `image` | file | Yes |

**Behavior**

- Validates the file with Pillow
- Uploads to Firebase storage using generated filename `{case_id}-{record_id}-{timestamp}.jpg`
- Updates record `image.image_folder_url`
- If the record is the case current record, also updates `case.current_image.image_folder_url`
- Calls the configured Gemini model with JSON response mode

**Response 200**

```json
{
  "status": "success",
  "case_id": "CS-260318-00001",
  "record_id": "REC-00002",
  "analysis": {},
  "image_id": "CS-260318-00001-REC-00002-20260318120000.jpg",
  "image_url": "https://..."
}
```

**Alternative response**

```json
{
  "status": "blocked",
  "reason": "..."
}
```

**Errors**

- `400` if the uploaded file is not a valid image
- `500` on AI/storage/server failure

### 5.12 `POST /analyze-wound`

**Purpose**

Runs three-layer AI wound analysis using uploaded image and structured clinical payload.

**Content-Type**

`multipart/form-data`

**Form fields**

| Field | Type | Required | Notes |
|---|---|---|---|
| `payload_data` | string | Yes | JSON string |
| `image` | file | Yes | Image is resized client-side in memory for model use |

**`payload_data` minimum contract**

| Field | Type | Required |
|---|---|---|
| `case_ref` | object | Yes |
| `case_ref.patient_id` | string | Yes |
| `case_ref.case_id` | string | Yes |
| `case_ref.record_id` | string | Yes |

Optional fields include `patient_profile`, `nurse_reviewed`, and `ai_prefill`.

**Behavior**

- If `case_id` and `record_id` exist in payload:
  - updates the record with `status = "ANALYZING"` and `nurse_reviewed` sections
  - updates the case with `status = "ANALYZING"` and `current_*` section snapshots
- Runs three Gemini calls:
  - layer 1: image extraction
  - layer 2: evidence fusion
  - layer 3: scoring and plan
- If AI analysis is returned successfully, stores an analysis snapshot into:
  - `records/{record_id}.analysis`
  - `cases/{case_id}.current_analysis`
- Final `analysis` value is returned as a JSON string, not a nested object

**Response 200**

```json
{
  "status": "success",
  "analysis": "{\"creator\":\"...\"}"
}
```

**Alternative response**

```json
{
  "status": "blocked",
  "reason": "..."
}
```

**Errors**

- `400` if `payload_data` is invalid JSON
- `500` on AI/server failure

### 5.13 `POST /analyze-healing`

**Purpose**

Builds a chronological healing summary from stored records and any record image URLs.

**Request body**

| Field | Type | Required |
|---|---|---|
| `case_id` | string | Yes |

**Behavior**

- Loads all records ordered by `record_created_at` ascending
- Appends each record JSON to the model prompt
- Attempts to fetch each record image via URL and attach it to the prompt
- Stores the result into:
  - latest record `current_healing_progress`
  - case `current_healing_progress`
- On success, also updates:
  - latest record `status = DOCTOR_REVIEW`
  - latest record `timestamps.doctor_review_at`
  - latest record `analysis_versions/{analysis_id}` with `payload.healing_progress`
  - case `status = DOCTOR_REVIEW`
  - case `current_record_id` to the latest record
  - case `current_analysis_id` to the new healing analysis version

**Response 200**

```json
{
  "status": "success",
  "analysis": "Overall trend: improving",
  "records": []
}
```

**Alternative response**

```json
{
  "status": "blocked",
  "reason": "...",
  "records": []
}
```

**Errors**

- `400` if `case_id` is missing
- `404` if no records exist for the case
- `500` on AI/server failure

### 5.14 `POST /tasks_list`

**Purpose**

Returns cases whose current treatment plan contains tasks.

**Request body**

Optional JSON object.

| Field | Type | Required | Notes |
|---|---|---|---|
| `limit` | integer | No | Default `200`, clamped to `1..500` |

**Behavior**

- Reads cases ordered by `case_updated_at` descending
- Loads patient names in batch
- Includes only cases whose `current_treatment_plan.plan_tasks` is a non-empty list

**Response 200**

```json
{
  "status": "success",
  "current_treatment_plan": [
    {
      "case_id": "CS-260318-00001",
      "patient_id": "PT-2603-00001",
      "patient_name": "John Doe",
      "current_record_id": "REC-00002",
      "current_plan_id": "PL-20260318120000",
      "current_treatment": {
        "plan_tasks": []
      }
    }
  ]
}
```

**Implementation note**

The response key is `current_treatment_plan`, not `tasks`.

**Errors**

- `500` on server/database failure

### 5.21 `POST /task_detail`

**Purpose**

Returns the current treatment plan for a case and either the full task list or a single indexed task.

**Request body**

Optional JSON object.

| Field | Type | Required | Notes |
|---|---|---|---|
| `case_id` | string | Yes | |
| `task_index` | integer | No | Zero-based index |

**Behavior**

- Loads patient name if case `patient_id` exists
- If `task_index` is omitted, returns `plan_tasks`
- If `task_index` is provided, returns `task`

**Response 200**

```json
{
  "status": "success",
  "case_id": "CS-260318-00001",
  "patient_id": "PT-2603-00001",
  "patient_name": "John Doe",
  "current_treatment": {},
  "plan_tasks": []
}
```

**Errors**

- `400` if `case_id` is missing
- `400` if `task_index` cannot be parsed as integer
- `404` if case does not exist
- `404` if `task_index` is out of range
- `500` on server/database failure

### 5.22 `POST /task_update`

**Purpose**

Updates tasks in the current treatment plan and in the current plan version task documents.

**Content-Type**

`multipart/form-data`

**Form fields**

| Field | Type | Required | Notes |
|---|---|---|---|
| `case_id` | string | Yes | |
| `plan_id` | string | No | If provided, must match case `current_plan_id` |
| `updates` | string | Yes | JSON string list |
| `images` | file[] | No | If present, count must equal update count |

**`updates` item format**

```json
[
  {
    "task_id": "TSK-0001",
    "updates": {
      "status": "COMPLETED",
      "task_due": "2026-03-20",
      "completed_at": "2026-03-18T12:00:00Z",
      "task_photo_url": "https://...",
      "task_text": "Updated task text",
      "source": "Doctor"
    }
  }
]
```

Only these fields are accepted inside each `updates` object:

- `status`
- `task_due`
- `completed_at`
- `task_photo_url`
- `task_text`
- `source`

**Behavior**

- Parses `updates` as JSON list
- Uploads each provided image to Firebase and overwrites `task_photo_url`
- Updates `cases/{case_id}.current_treatment_plan.plan_tasks`
- Updates `cases/{case_id}/records/{current_record_id}.treatment_plan.plan_tasks`
- Updates current plan version task documents under the current record
- Deletes deprecated `current_task_list` and `task_list` snapshots on new writes
- Returns the actual `current_plan_id`, not the provided `plan_id`

**Response 200**

```json
{
  "status": "success",
  "case_id": "CS-260318-00001",
  "plan_id": "PL-20260318120000",
  "updated_task_ids": ["TSK-0001"]
}
```

**Errors**

- `400` if `updates` is invalid JSON
- `400` if `updates` is empty or not a list
- `400` if `plan_id` does not match current plan
- `400` if image count does not match update count
- `400` if any update entry is invalid or has no valid fields
- `404` if case does not exist
- `404` if no `plan_tasks` exist
- `404` if any `task_id` is not in current plan
- `404` if current plan/record linkage is missing
- `500` on server/database failure

## 6. Core Data Models

### Patient Profile

```json
{
  "patient_id": "PT-2603-00001",
  "nrc_id": "8757446557345",
  "patient_name": "John Doe",
  "phone_no": "0812345678",
  "dob": "1990-01-01",
  "gender": "Male",
  "height_cm": 170.0,
  "weight_kg": 65.0,
  "medical_history": "DM",
  "diabetes": {
    "has_diabetes": "yes",
    "years": "5",
    "risk_history": [],
    "complications": []
  },
  "status": "Active",
  "created_at": "2026-03-18",
  "synced_at": "server timestamp",
  "photo_url": "https://..."
}
```

### Case Document

```json
{
  "case_id": "CS-260318-00001",
  "patient_id": "PT-2603-00001",
  "created_by_nurse": "NUR-001",
  "assigned_doctor": "DR-001",
  "status": "CREATION",
  "urgency": "MEDIUM",
  "case_created_at": "datetime",
  "case_updated_at": "datetime",
  "current_record_id": "REC-00001",
  "current_analysis_id": null,
  "current_plan_id": null
}
```

The case also stores current snapshot fields such as:

- `current_timestamps`
- `current_image`
- `current_vital_signs`
- `current_wound_detail`
- `current_ischemia`
- `current_infection`
- `current_neuropathy`
- `current_sinbad`
- `current_lab_results`
- `current_vascular`
- `current_analysis`
- `current_treatment_plan`
- `current_gangrene_extent` is additionally used by `/analyze-wound`
- `current_healing_progress` is additionally used by `/analyze-healing`

### Record Document

Record payloads are based on `WoundCaseRecord`.

Important sections:

- identity: `record_id`, `case_id`, `patient_id`
- ownership: `record_created_by`, `created_by_nurse`, `assigned_doctor`
- status: `status`, `urgency`
- timestamps: `record_created_at`, `record_updated_at`, `timestamps`
- clinical sections:
  - `vital_signs`
  - `wound_detail`
  - `ischemia`
  - `infection`
  - `neuropathy`
  - `sinbad`
  - `lab_results`
  - `vascular`
  - `gangrene_extent`
- outputs:
  - `analysis`
  - `treatment_plan`
  - `image`
  - `current_healing_progress`

`task_list` is deprecated. Use `treatment_plan.plan_tasks` on records and `current_treatment_plan.plan_tasks` on cases.

### Treatment Plan

```json
{
  "plan_id": "PL-20260318120000",
  "plan_text": "string or null",
  "followup_days": 7,
  "status": "DRAFT",
  "plan_tasks": [
    {
      "task_id": "TSK-0001",
      "task_text": "Wound care",
      "status": "PENDING",
      "task_due": "2026-03-20",
      "completed_at": null,
      "task_photo_url": "https://...",
      "source": "AI",
      "order_index": 1
    }
  ]
}
```

## 7. Firestore Structure Used by the API

```text
patients/{patient_id}

cases/{case_id}
cases/{case_id}/records/{record_id}
cases/{case_id}/records/{record_id}/analysis_versions/{analysis_id}
cases/{case_id}/records/{record_id}/plan_versions/{plan_id}
cases/{case_id}/records/{record_id}/plan_versions/{plan_id}/tasks/{task_id}

metadata/counters_{YYMM}
metadata/counters_case_{YYMMDD}
```

## 8. Implementation Notes and Gaps

- The API is implementation-first, not OpenAPI-first.
- There is no auth, role enforcement, or PHI protection layer in the API itself.
- Response formats vary by endpoint.
- Several endpoints use `POST` for reads (`/cases_list`, `/case_detail`, `/tasks_list`, `/task_detail`).
- `/analyze-wound` returns the final analysis as a JSON string instead of a nested JSON object.
- `/tasks_list` returns `current_treatment_plan` as the array key, which is slightly misleading.
- Case status written by `/analyze-wound` is `"ANALYZING"`, which is not part of the `Status` enum in [`schemas.py`](/backend/schemas.py).
- No explicit request/response versioning is implemented.

## 9. Recommended Next Step

If you want this to become a formal API report for handoff or frontend alignment, the next practical step is to convert this document into:

1. a strict OpenAPI schema with shared components and examples
2. a normalized error model
3. a short workflow appendix for create-case, follow-up, and task execution
