# Foster Ulcer AI API Contract

## Overview

This document describes the backend API contract currently implemented in:

- `backend/app.py`
- `backend/routes/patients.py`
- `backend/routes/cases.py`
- `backend/routes/analysis.py`
- `backend/routes/task.py`
- `backend/routes/notifications.py`
- `backend/schemas.py`

It is implementation-based and structured to follow the delivery template style.

## Base URL

Local backend:

```text
http://10.0.2.2:8080
```

Alternative local machine URL:

```text
http://127.0.0.1:8080
```

## Content Types

- `application/json`
- `multipart/form-data`

## Authentication

No authentication or authorization is currently enforced by the backend.

## Standard Error Shape

Most non-success responses follow:

```json
{
  "detail": "..."
}
```

Validation errors may return:

```json
{
  "detail": [
    {
      "loc": ["body", "..."],
      "msg": "...",
      "type": "..."
    }
  ]
}
```

## Timestamp Rules

- `routes/cases.py` normalizes parsed datetimes to UTC.
- `appointment_at` and `completed_at` should be ISO 8601 datetimes with timezone.
- Some routes still use Firestore server timestamps, especially in `routes/analysis.py`, `routes/task.py`, and `routes/patients.py`.

Recommended client rule:

- always send ISO 8601 with timezone offset, for example `2026-03-23T14:30:00+07:00`

## Core Enums

### Case Status

- `CREATION`
- `AI_PROCESSING`
- `DOCTOR_REVIEW`
- `PLAN_ISSUED`
- `TREATMENT_ACTIVE`
- `APPOINTMENT`
- `REQUEST_CLOSE`
- `COMPLETED`

### Urgency

- `URGENT`
- `MEDIUM`
- `LOW`

## Data Objects

### Patient Object

```json
{
  "patient_id": "PT-2603-00001",
  "nrc_id": "1234567890123",
  "patient_name": "John Doe",
  "phone_no": "0812345678",
  "dob": "19/03/2001",
  "gender": "female",
  "height_cm": 160.0,
  "weight_kg": 55.0,
  "medical_history": "Diabetes mellitus",
  "diabetes": {
    "has_diabetes": "Yes",
    "years": "1-5y",
    "risk_history": ["Past Ulcer"],
    "complications": ["Eyes (Retinopathy)"]
  },
  "status": "Active",
  "created_at": "2026-03-23 14:00:00",
  "synced_at": "timestamp",
  "photo_url": "https://..."
}
```

### Case Object

```json
{
  "case_id": "CS-260323-00001",
  "patient_id": "PT-2603-00001",
  "created_by_nurse": "NURSE-001",
  "assigned_doctor": "DR-001",
  "status": "PLAN_ISSUED",
  "urgency": "MEDIUM",
  "case_created_at": "2026-03-23T07:30:00+00:00",
  "case_updated_at": "2026-03-23T09:00:00+00:00",
  "current_record_id": "REC-00001",
  "current_analysis_id": "AN-20260323100000",
  "current_plan_id": "PL-20260323100000",
  "current_timestamps": {},
  "current_image": {},
  "current_vital_signs": {},
  "current_wound_detail": {},
  "current_ischemia": {},
  "current_infection": {},
  "current_neuropathy": {},
  "current_sinbad": {},
  "current_lab_results": {},
  "current_vascular": {},
  "current_gangrene_extent": null,
  "current_analysis": {},
  "current_treatment_plan": {
    "plan_tasks": []
  },
  "current_healing_progress": null
}
```

### Record Object

```json
{
  "record_id": "REC-00001",
  "case_id": "CS-260323-00001",
  "patient_id": "PT-2603-00001",
  "record_created_by": "NURSE-001",
  "record_created_at": "2026-03-23T07:30:00+00:00",
  "record_updated_at": "2026-03-23T09:00:00+00:00",
  "created_by_nurse": "NURSE-001",
  "assigned_doctor": "DR-001",
  "status": "PLAN_ISSUED",
  "urgency": "MEDIUM",
  "timestamps": {
    "created_at": "2026-03-23T07:30:00+00:00",
    "updated_at": "2026-03-23T09:00:00+00:00",
    "analyze_at": "2026-03-23T08:00:00+00:00",
    "doctor_review_at": "2026-03-23T09:00:00+00:00",
    "plan_issued_at": null,
    "treatment_active_at": null,
    "appointment_at": null,
    "completed_at": null
  },
  "image": {
    "image_folder_url": "https://..."
  },
  "vital_signs": {},
  "wound_detail": {},
  "ischemia": {},
  "infection": {},
  "neuropathy": {},
  "sinbad": {},
  "lab_results": {},
  "vascular": {},
  "gangrene_extent": null,
  "analysis": {},
  "treatment_plan": {
    "plan_tasks": []
  },
  "current_healing_progress": null
}
```

### Analysis Version Object

```json
{
  "analysis_id": "AN-20260323100000",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "status": "SENT",
  "source": "Doctor",
  "created_at": "timestamp",
  "payload": {}
}
```

Observed `source` values:

- `AI`
- `Doctor`
- `AI_HEALING`

Observed `status` values:

- `DRAFT`
- `SENT`

### Plan Version Object

```json
{
  "plan_id": "PL-20260323100000",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "created_at": "timestamp",
  "updated_at": "timestamp",
  "status": "SENT",
  "plan_text": "Perform dressing change, offloading, and follow-up review.",
  "followup_days": 7,
  "source": "Doctor"
}
```

### Task Object

```json
{
  "task_id": "TSK-0001",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "plan_id": "PL-20260323100000",
  "created_at": "timestamp",
  "updated_at": "timestamp",
  "task_text": "Apply dressing",
  "status": "SENT",
  "task_due": "2026-03-24",
  "completed_at": null,
  "task_photo_url": null,
  "source": "Doctor",
  "order_index": 1
}
```

### Doctor Notification Object

```json
{
  "notification_id": "NTF-20260323090000123456",
  "type": "CASE_SENT_TO_DOCTOR",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "patient_id": "PT-2603-00001",
  "patient_name": "John Doe",
  "urgency": "URGENT",
  "status": "UNREAD",
  "title": "New case for review",
  "message": "Case CS-260323-00001 is ready for doctor review.",
  "created_at": "2026-03-23T09:00:00.123456+00:00",
  "read_at": null
}
```

### Nurse Notification Object

```json
{
  "notification_id": "NTF-20260323100000123456",
  "type": "PLAN_ISSUED_TO_NURSE",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "patient_id": "PT-2603-00001",
  "patient_name": "John Doe",
  "urgency": "URGENT",
  "created_by_nurse": "NURSE-001",
  "status": "UNREAD",
  "title": "Plan ready",
  "message": "Doctor review is complete for case CS-260323-00001.",
  "created_at": "2026-03-23T10:00:00.123456+00:00",
  "read_at": null
}
```

## Firestore Layout

```text
patients/{patient_id}

cases/{case_id}
cases/{case_id}/records/{record_id}
cases/{case_id}/records/{record_id}/analysis_versions/{analysis_id}
cases/{case_id}/records/{record_id}/plan_versions/{plan_id}
cases/{case_id}/records/{record_id}/plan_versions/{plan_id}/tasks/{task_id}

all_doctor/{notification_id}
all_nurse/{notification_id}
notification_devices/{sha256_fcm_token}

metadata/counters_{YYMM}
metadata/counters_case_{YYMMDD}
```

## FCM Push Delivery

- Doctor-side notifications broadcast to all active device tokens with `role = "DOCTOR"`.
- Nurse-side notifications broadcast to all active device tokens with `role = "NURSE"`.
- The frontend should register the doctor app and nurse app separately with `/notification-devices/register`.
- `user_id` is stored for debugging/audit but is not used for FCM targeting in the current role-broadcast design.

## Status Propagation Rules

- `case.status` is the high-level lifecycle state.
- `record.status` is the state of the current working record.
- `current_treatment_plan.status` mirrors the current plan snapshot.
- `current_treatment_plan.plan_tasks[*].status` is the case-level task snapshot.
- `records/{record_id}.treatment_plan.plan_tasks[*].status` is the record-level task snapshot.
- `current_task_list` and `task_list` are deprecated snapshots and are deleted on new writes.
- `POST /doctor-review` forces plan and task status to `SENT`.
- `POST /create_appointment` updates case, record, current treatment plan tasks, record treatment plan tasks, and plan-version task documents to `APPOINTMENT`.
- `POST /request_close` only updates case and record to `REQUEST_CLOSE`.
- `POST /complete_case` updates case, record, current treatment plan tasks, record treatment plan tasks, and plan-version task documents to `COMPLETED`.

## Endpoint Summary

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/load-dashboard` | Return dashboard summary counters and upcoming tasks |
| `POST` | `/create-patient-profile` | Create patient profile |
| `GET` | `/patients_list` | List patients |
| `PATCH` | `/patients/{patient_id}` | Update patient profile |
| `POST` | `/create-case` | Create first case record |
| `POST` | `/update_cases` | Create follow-up record |
| `POST` | `/cases_list` | List cases with optional filters |
| `POST` | `/case_detail` | Load case, records, and patient profile |
| `POST` | `/send-to-doctor` | Save nurse-reviewed record and create analysis/plan versions |
| `POST` | `/no-wound-assessment` | Save a no-wound assessment and complete the case immediately |
| `POST` | `/doctor-review` | Save doctor-reviewed analysis and issue plan |
| `POST` | `/notification-devices/register` | Register FCM token for doctor/nurse app role broadcast |
| `POST` | `/notification-devices/unregister` | Deactivate an FCM token |
| `POST` | `/notifications/{notification_id}/read` | Mark one notification as read |
| `POST` | `/notifications/mark-all-read` | Mark unread notifications as read |
| `POST` | `/create_appointment` | Move current case flow to `APPOINTMENT` |
| `POST` | `/request_close` | Mark case and current record as `REQUEST_CLOSE` |
| `POST` | `/complete_case` | Move current case flow to `COMPLETED` |
| `POST` | `/analyze-transcribe` | Transcribe uploaded audio |
| `POST` | `/analyze-fillin` | Upload image and get fill-in output |
| `POST` | `/analyze-wound` | Run AI wound analysis |
| `POST` | `/analyze-healing` | Generate healing progress summary |
| `GET` | `/doctor-notifications` | List shared doctor notifications |
| `GET` | `/nurse-notifications` | List shared nurse notifications |
| `POST` | `/tasks_list` | List current treatment plans with tasks |
| `POST` | `/task_detail` | Load one task or the current task list |
| `POST` | `/task_update` | Update current plan tasks |

## Endpoint Contracts

### Dashboard

**GET /load-dashboard**

----

Returns dashboard counters and up to 4 upcoming tasks derived from `cases` and `patients`.

* **URL Params**
  None

* **Data Params**
  None

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "today_task_no": 2,
  "total_active_patient": 4,
  "upcoming_plan": [
    {
      "case_id": "CS-260323-00001",
      "patient_id": "PT-2603-00001",
      "patient_name": "John Doe",
      "status": "PLAN_ISSUED",
      "urgency": "MEDIUM",
      "case_updated_at": "2026-03-23T09:00:00+00:00",
      "due_date": "2026-03-24",
      "patient_photo_url": "https://..."
    }
  ]
}
```

* **Error Response:**
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

### Patients

**POST /create-patient-profile**

----

Creates a new patient profile and optionally uploads a profile image.

* **URL Params**
  None

* **Data Params**

```json
{
  "patient_data": "JSON string of patient fields",
  "image": "optional file"
}
```

* **Headers**
  Content-Type: multipart/form-data

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "patient_id": "PT-2603-00001",
  "photo_url": "https://...",
  "message": "Profile created for John Doe"
}
```

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "Data format error: ..." }`

**GET /patients_list**

----

Returns patients ordered by `created_at` descending.

* **URL Params**
  *Optional:* `limit=[integer]`

* **Data Params**
  None

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "patients": [
    { "<patient_object>": "..." }
  ]
}
```

* **Error Response:**
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**PATCH /patients/{patient_id}**

----

Updates non-null fields on the specified patient profile.

* **URL Params**
  *Required:* `patient_id=[string]`

* **Data Params**

```json
{
  "phone_no": "0899999999",
  "weight_kg": 56
}
```

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "patient_id": "PT-2603-00001",
  "updated_fields": ["phone_no", "weight_kg", "synced_at"]
}
```

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "No fields to update" }`
  OR
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

### Cases

**POST /create-case**

----

Creates the initial case document and first record for a patient.

* **URL Params**
  None

* **Data Params**

```json
{
  "patient_id": "PT-2603-00001",
  "status": "CREATION",
  "urgency": "MEDIUM",
  "created_by_nurse": "NURSE-001",
  "assigned_doctor": "DR-001",
  "vitals": {
    "temperature": "37.0",
    "blood_pressure": "120/80",
    "blood_pressure_systolic": "120",
    "blood_pressure_diastolic": "80",
    "blood_glucose": "140",
    "heart_rate": "78",
    "respiratory_rate": "18"
  },
  "meta": {
    "sent_at": "2026-03-23T14:30:00+07:00"
  }
}
```

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "Case creation success",
  "patient_id": "PT-2603-00001",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001"
}
```

* **Error Response:**
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**POST /update_cases**

----

Creates a follow-up record under an existing case.

* **URL Params**
  None

* **Data Params**
  Same structure as `POST /create-case`, plus:

```json
{
  "case_id": "CS-260323-00001"
}
```

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "Case update success",
  "patient_id": "PT-2603-00001",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00002"
}
```

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "patient_id does not match case" }`
  OR
  * **Code:** 404
  **Content:** `{ "detail": "Case not found" }`
  OR
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**POST /cases_list**

----

Returns case documents with optional `patient_id` and status filtering.

* **URL Params**
  None

* **Data Params**

```json
{
  "limit": 50,
  "patient_id": "PT-2603-00001",
  "filter": ["REQUEST_CLOSE", "APPOINTMENT"]
}
```

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "cases": [
    { "<case_object>": "..." }
  ]
}
```

* **Error Response:**
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**POST /case_detail**

----

Returns the case snapshot, its records, and the linked patient profile.

* **URL Params**
  None

* **Data Params**

```json
{
  "case_id": "CS-260323-00001"
}
```

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "case": { "<case_object>": "..." },
  "records": [
    { "<record_object>": "..." }
  ],
  "patient_profile": { "<patient_object>": "..." }
}
```

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "case_id is required" }`
  OR
  * **Code:** 404
  **Content:** `{ "detail": "Case not found" }`
  OR
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**POST /send-to-doctor**

----

Merges nurse-reviewed data into the record and creates analysis and plan versions.

Tasks should be sent under `treatment_plan.plan_tasks`. Deprecated `task_list` input is accepted only as a compatibility fallback. Missing task `source` defaults to `AI`.

* **URL Params**
  None

* **Data Params**
  `WoundCaseRecordUpdate` JSON payload.

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "message": "Case sent for doctor review",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "analysis_id": "AN-20260323090000",
  "plan_id": "PL-20260323090000",
  "notification_id": "NTF-20260323090000123456"
}
```

* **Error Response:**
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**POST /no-wound-assessment**

----

Saves a dedicated no-wound workflow record without image analysis, wound-detail review, analysis version creation, or plan version creation. The target case and record move directly to `COMPLETED`, `timestamps.completed_at` is set, and the current analysis/plan pointers are cleared.

This endpoint is separate from image-analysis flow. Use it only when there is no wound photo and no wound-detail review.

* **URL Params**
  None

* **Data Params**

```json
{
  "case_id": "CASE-001",
  "patient_id": "PAT-001",
  "record_id": "REC-001",
  "status": "COMPLETED",
  "flow_type": "NO_WOUND_PRESENT",
  "wound_present": false,
  "nurse_reviewed_flag": false,
  "vital_signs": {
    "temperature": 36.8,
    "blood_pressure": "120/80",
    "blood_pressure_systolic": 120,
    "blood_pressure_diastolic": 80,
    "blood_glucose": 110,
    "heart_rate": 72,
    "respiratory_rate": 16
  },
  "wound_detail": null,
  "sinbad": {
    "site": "Forefoot",
    "ischemia": "No",
    "neuropathy": "Yes",
    "infection": "No",
    "area": "< 1 cm²",
    "depth": "Skin only",
    "total": 1
  },
  "ischemia": {
    "points": [],
    "pulse": null,
    "checklist": []
  },
  "infection": {
    "checklist": [],
    "erythema_extent": null,
    "probe_to_bone_test": null,
    "has_deep_abscess_or_fasciitis": null
  },
  "neuropathy": {
    "points": [1, 3]
  },
  "lab_results": {
    "wbc_count": null,
    "crp": null,
    "esr": null,
    "procalcitonin": null
  },
  "vascular": {
    "abi_value": null,
    "ankle_pressure_mmHg": null,
    "toe_pressure_mmHg": null,
    "tcpo2_mmHg": null
  },
  "meta": {
    "submitted_at": "2026-05-07 14:30:00",
    "submitted_by_role": "nurse"
  }
}
```

* **Headers**
  Content-Type: application/json

* **Validation Rules**
  - `status` must be `COMPLETED`
  - `flow_type` must be `NO_WOUND_PRESENT`
  - `wound_present` must be `false`
  - `wound_detail` must be `null`
  - required `sinbad` fields: `site`, `ischemia`, `neuropathy`, `infection`, `area`, `depth`

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "case_id": "CASE-001",
  "record_id": "REC-001",
  "next_status": "COMPLETED"
}
```

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "patient_id does not match case" }`
  OR
  * **Code:** 404
  **Content:** `{ "detail": "Case not found" }`
  OR
  * **Code:** 404
  **Content:** `{ "detail": "Record not found" }`
  OR
  * **Code:** 422
  **Content:** `{ "detail": [...] }`
  OR
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**POST /doctor-review**

----

Creates a doctor analysis version, optionally creates a doctor plan version, and forces plan and tasks to `SENT`.

Doctor plan tasks are stored under `treatment_plan.plan_tasks`. Missing task `source` defaults to `Doctor`; explicit source values are preserved. Preferred clients send top-level `analysis` and `treatment_plan`. Legacy `payload` is still accepted for backward compatibility.

* **URL Params**
  None

* **Data Params**

```json
{
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "analysis_id": "AN-20260323090000",
  "analysis": {
    "diagnosis": "...",
    "description": "...",
    "healing_progress": "..."
  },
  "treatment_plan": {
    "plan_text": "...",
    "followup_days": 7,
    "plan_tasks": [
      {
        "task_id": "TSK-EXAMPLE-0001",
        "order_index": 1,
        "task_text": "Apply dressing",
        "task_due": "2026-03-30",
        "source": "Doctor"
      }
    ]
  },
  "ai_result_edit_flag": true,
  "treatment_plan_edit_flag": true,
  "signature_base64": "data:image/png;base64,..."
}
```

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "message": "Doctor review saved",
  "analysis_id": "AN-20260323100000",
  "plan_id": "PL-20260323100000",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "source": "Doctor",
  "sinbad_copied": true,
  "notification_id": "NTF-20260323100000123456"
}
```

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "case_id is required" }`
  OR
  * **Code:** 404
  **Content:** `{ "detail": "Case not found" }`
  OR
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**POST /notification-devices/register**

----

Registers an FCM token for role-wide doctor or nurse app broadcast.

* **Data Params**

```json
{
  "user_id": "doctor-app",
  "role": "DOCTOR",
  "fcm_token": "<FCM_TOKEN>",
  "platform": "android",
  "device_id": "optional-device-id"
}
```

Use `role = "DOCTOR"` for the doctor app and `role = "NURSE"` for the nurse app. `user_id` is stored for debugging/audit but is not used for current FCM targeting.

* **Success Response:**

```json
{
  "status": "success",
  "message": "Notification device registered",
  "device_token_id": "<sha256-token-id>"
}
```

**POST /notification-devices/unregister**

----

Marks an FCM token inactive.

* **Data Params**

```json
{
  "fcm_token": "<FCM_TOKEN>"
}
```

* **Success Response:**

```json
{
  "status": "success",
  "message": "Notification device unregistered",
  "device_token_id": "<sha256-token-id>"
}
```

**POST /notifications/{notification_id}/read**

----

Marks one notification read in `all_doctor` or `all_nurse`.

* **Data Params**

Optional:

```json
{
  "role": "DOCTOR"
}
```

If `role` is omitted, backend searches both shared feeds. If present, role must be `DOCTOR` or `NURSE`.

* **Success Response:**

```json
{
  "status": "success",
  "message": "Notification marked read",
  "notification_id": "NTF-20260422120000123456",
  "collection": "all_doctor"
}
```

**POST /notifications/mark-all-read**

----

Marks unread notifications read in one role feed, or both feeds if no role is supplied.

* **Data Params**

Optional:

```json
{
  "role": "NURSE"
}
```

* **Success Response:**

```json
{
  "status": "success",
  "message": "Notifications marked read",
  "updated_count": 12,
  "role": "NURSE"
}
```

**POST /create_appointment**

----

Updates case, record, current treatment plan, record treatment plan, and plan-version task documents to `APPOINTMENT`.

* **URL Params**
  None

* **Data Params**

```json
{
  "case_id": "CS-260323-00001",
  "appointment_at": "2026-03-25T10:00:00+07:00"
}
```

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "message": "Appointment created",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "plan_id": "PL-20260323100000",
  "appointment_at": "2026-03-25T03:00:00+00:00"
}
```

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "appointment_at must be a valid ISO datetime" }`
  OR
  * **Code:** 404
  **Content:** `{ "detail": "Case not found" }`
  OR
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**POST /request_close**

----

Updates case and current record to `REQUEST_CLOSE` and creates a doctor notification.

* **URL Params**
  None

* **Data Params**

```json
{
  "case_id": "CS-260323-00001"
}
```

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "message": "Close request saved",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "notification_id": "NTF-20260323120000123456"
}
```

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "case_id is required" }`
  OR
  * **Code:** 404
  **Content:** `{ "detail": "Case not found" }`
  OR
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**POST /complete_case**

----

Updates case, current record, current treatment plan, record treatment plan, and plan-version task documents to `COMPLETED`.

* **URL Params**
  None

* **Data Params**

```json
{
  "case_id": "CS-260323-00001",
  "completed_at": "2026-03-26T16:00:00+07:00"
}
```

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "message": "Case completed",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "plan_id": "PL-20260323100000",
  "completed_at": "2026-03-26T09:00:00+00:00"
}
```

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "case_id is required" }`
  OR
  * **Code:** 404
  **Content:** `{ "detail": "Case not found" }`
  OR
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

### Analysis

**POST /analyze-transcribe**

----

Transcribes uploaded audio using the configured model.

* **URL Params**
  None

* **Data Params**

```json
{
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "audio": "required file"
}
```

* **Headers**
  Content-Type: multipart/form-data

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "transcript": "..."
}
```

* **Alternative Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "blocked",
  "reason": "..."
}
```

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "Audio file is empty" }`
  OR
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**POST /analyze-fillin**

----

Uploads an image to storage, stores the URL, and returns model-produced fill-in data.

* **URL Params**
  None

* **Data Params**

```json
{
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "image": "required file"
}
```

* **Headers**
  Content-Type: multipart/form-data

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "analysis": {},
  "image_id": "CS-260323-00001-REC-00001-20260323120000.jpg",
  "image_url": "https://..."
}
```

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "Invalid image file" }`
  OR
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**POST /analyze-wound**

----

Runs AI wound analysis using structured payload data plus an uploaded image.

* **URL Params**
  None

* **Data Params**

```json
{
  "payload_data": "JSON string",
  "image": "required file"
}
```

Minimum `payload_data` shape:

```json
{
  "case_ref": {
    "patient_id": "PT-2603-00001",
    "case_id": "CS-260323-00001",
    "record_id": "REC-00001"
  },
  "patient_profile": {},
  "nurse_reviewed": {}
}
```

* **Headers**
  Content-Type: multipart/form-data

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "analysis": "{\"AI_analysis\":{...}}"
}
```

* **Alternative Success Response:**
* **Code:** 200
  **Content:** `{ "status": "blocked", "reason": "..." }`

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "Invalid payload_data JSON: ..." }`
  OR
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**POST /analyze-healing**

----

Generates healing progress from the case timeline and may store a doctor-review draft analysis.

* **URL Params**
  None

* **Data Params**

```json
{
  "case_id": "CS-260323-00001"
}
```

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "analysis": "Overall wound healing is improving",
  "records": [],
  "notification_id": "NTF-20260323130000123456"
}
```

* **Alternative Success Response:**
* **Code:** 200
  **Content:** `{ "status": "blocked", "reason": "...", "records": [] }`

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "case_id is required" }`
  OR
  * **Code:** 404
  **Content:** `{ "detail": "No records found for this case" }`
  OR
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

### Notifications

**GET /doctor-notifications**

----

Returns the shared doctor notification feed ordered by `created_at` descending.

* **URL Params**
  *Optional:* `limit=[integer]`

* **Data Params**
  None

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "notifications": [
    { "<doctor_notification_object>": "..." }
  ]
}
```

* **Error Response:**
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**GET /nurse-notifications**

----

Returns the shared nurse notification feed ordered by `created_at` descending.

* **URL Params**
  *Optional:* `limit=[integer]`

* **Data Params**
  None

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "notifications": [
    { "<nurse_notification_object>": "..." }
  ]
}
```

* **Error Response:**
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

### Tasks

**POST /tasks_list**

----

Returns current treatment plans from recent cases, enriched with patient info.

* **URL Params**
  None

* **Data Params**

```json
{
  "limit": 200
}
```

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "current_treatment_plan": [
    {
      "case_id": "CS-260323-00001",
      "patient_id": "PT-2603-00001",
      "patient_name": "John Doe",
      "photo_url": "https://...",
      "current_record_id": "REC-00001",
      "current_plan_id": "PL-20260323100000",
      "current_treatment": {}
    }
  ]
}
```

* **Error Response:**
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**POST /task_detail**

----

Returns one indexed task or the full `plan_tasks` list for a case.

* **URL Params**
  None

* **Data Params**

```json
{
  "case_id": "CS-260323-00001",
  "task_index": 0
}
```

* **Headers**
  Content-Type: application/json

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "case_id": "CS-260323-00001",
  "patient_id": "PT-2603-00001",
  "patient_name": "John Doe",
  "current_treatment": {},
  "task": {}
}
```

If `task_index` is omitted, response returns `plan_tasks` instead of `task`.

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "case_id is required" }`
  OR
  * **Code:** 404
  **Content:** `{ "detail": "Case not found" }`
  OR
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

**POST /task_update**

----

Updates one or more tasks in the current plan and optionally uploads task images.

Task updates are synced to both `cases/{case_id}.current_treatment_plan.plan_tasks` and `records/{record_id}.treatment_plan.plan_tasks`, plus the plan-version task documents.

* **URL Params**
  None

* **Data Params**

```json
{
  "case_id": "CS-260323-00001",
  "plan_id": "PL-20260323100000",
  "updates": [
    {
      "task_id": "TSK-0001",
      "updates": {
        "status": "COMPLETED",
        "task_due": "2026-03-30",
        "completed_at": "2026-03-30T09:00:00+00:00",
        "task_text": "Updated task text",
        "source": "Doctor"
      }
    }
  ],
  "images": ["optional file list"]
}
```

* **Headers**
  Content-Type: multipart/form-data

* **Success Response:**
* **Code:** 200
  **Content:**

```json
{
  "status": "success",
  "case_id": "CS-260323-00001",
  "plan_id": "PL-20260323100000",
  "updated_task_ids": ["TSK-0001"]
}
```

* **Error Response:**
  * **Code:** 400
  **Content:** `{ "detail": "plan_id does not match current plan" }`
  OR
  * **Code:** 404
  **Content:** `{ "detail": "Case not found" }`
  OR
  * **Code:** 500
  **Content:** `{ "detail": "..." }`

## Workflow Summary

Typical happy path:

1. Create patient
2. Create case
3. Upload image and/or run AI analysis
4. Send case to doctor
5. Doctor reviews analysis and issues plan
6. Case becomes `PLAN_ISSUED`
7. Optional appointment sets case to `APPOINTMENT`
8. Optional request-close sets case to `REQUEST_CLOSE`
9. Completion sets case to `COMPLETED`

## Mobile App Notes

Observed Flutter usage includes:

- `/cases_list`
- `/case_detail`
- `/task_detail`
- `/doctor-review`
- `/complete_case`

The mobile app relies heavily on `current_*` snapshot fields on the case document.

## Production Readiness Gaps

- no auth or role-based authorization
- no versioned namespace such as `/api/v1`
- several read operations use `POST` instead of `GET`
- response formats are not fully standardized across endpoints
- timestamps are not fully consistent across all routes
- notifications are shared queues, not per-user inboxes
- no explicit pagination cursors
- public storage URLs are used for uploaded images
- no idempotency strategy for retry-safe writes
- AI endpoints have long-running external dependencies but no job queue or async status model
- no documented rate limiting, request tracing, or audit model

## Recommended Production Improvements

1. Add Firebase Auth or equivalent auth, then enforce nurse/doctor role authorization in every route.
2. Version the API under `/api/v1` and freeze request and response schemas.
3. Standardize envelopes, error codes, and timestamp serialization across all endpoints.
4. Replace shared notification feeds with per-user or per-role scoped inbox design plus proper unread tracking.
5. Stop using public file URLs for clinical images and move to private storage access.
6. Add pagination, filtering contracts, and stable ordering for list endpoints.
7. Move AI-heavy routes to background jobs with persisted job state and retries.
8. Add automated contract tests and OpenAPI generation from code.
