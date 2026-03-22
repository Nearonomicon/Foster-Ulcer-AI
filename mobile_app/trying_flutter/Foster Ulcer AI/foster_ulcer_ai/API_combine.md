# Combined API Contract

This document combines:
- frontend API usage from `lib/widgets/main_navigation_screen.dart`
- backend implementation from `../backend/app.py`, `../backend/routes/*.py`, and `../backend/schemas.py`

It is meant to answer 4 questions for each route:
- Is the route implemented in backend?
- Is the route used by the current Flutter app?
- What does the frontend send?
- What does the backend validate, store, and return?

## Summary

- Frontend-configured endpoints: `15`
- Frontend-actually-called endpoints: `14`
- Backend explicit endpoints: `15`
- Backend-only explicit endpoints: `2`
  - `POST /load-dashboard`
  - `POST /doctor-review`
- Frontend-configured but not called from the app: `GET /docs`

## Base URLs

- Frontend configured production base URL:
  - `https://foster-ulcer-ai-backend-429230748709.asia-southeast3.run.app`
- Backend local default:
  - `http://127.0.0.1:8000`
- FastAPI also exposes auto-generated docs by default:
  - `GET /docs`
  - `GET /openapi.json`
  - `GET /redoc`

## Endpoint Matrix

| Method | Path | Frontend uses | Backend implements | Notes |
|---|---|---:|---:|---|
| `POST` | `/load-dashboard` | No | Yes | Health/CORS check |
| `POST` | `/create-patient-profile` | Yes | Yes | Multipart |
| `GET` | `/patients_list` | Yes | Yes | Frontend accepts wrapped or bare list; backend returns wrapped list |
| `PATCH` | `/patients/{patient_id}` | Yes | Yes | Partial update |
| `POST` | `/create-case` | Yes | Yes | First record for case |
| `POST` | `/update_cases` | Yes | Yes | Follow-up creates new record |
| `POST` | `/cases_list` | Yes | Yes | Filter optional |
| `POST` | `/case_detail` | Yes | Yes | Includes records and patient profile |
| `POST` | `/send-to-doctor` | Yes | Yes | Backend validates nested clinical sections |
| `POST` | `/doctor-review` | No | Yes | Doctor-edited review save |
| `POST` | `/analyze-fillin` | Yes | Yes | Multipart image upload |
| `POST` | `/analyze-wound` | Yes | Yes | Multipart with JSON string payload |
| `POST` | `/analyze-healing` | Yes | Yes | Backend returns summary text plus records |
| `POST` | `/tasks_list` | Yes | Yes | Backend returns `current_treatment_plan` key |
| `POST` | `/task_detail` | Yes | Yes | Backend returns `current_treatment`; frontend reconstructs `plan_tasks` |
| `POST` | `/task_update` | Yes | Yes | Multipart with repeated `images` |
| `GET` | `/docs` | Configured only | Yes, auto | Not called by current Flutter app |

## Important Frontend/Backend Alignment Notes

### 1. Wrapper differences the frontend already tolerates

- `/patients_list`
  - Backend returns `{ "status": "success", "patients": [...] }`
  - Frontend also tolerates a bare array
- `/cases_list`
  - Backend returns `{ "status": "success", "cases": [...] }`
  - Frontend also tolerates a bare array
- `/analyze-fillin.analysis`
  - Backend returns an object
  - Frontend can parse either object or JSON string
- `/analyze-wound.analysis`
  - Backend returns a JSON string
  - Frontend can parse either string or object
- `/analyze-healing`
  - Backend returns summary text in `analysis`
  - Frontend also tolerates `summary`, `message`, or `result`

### 2. Name translations already happening

- Frontend sends `vitals.blood_sugar` to `/create-case` and `/update_cases`
- Backend stores that as `vital_signs.blood_glucose`

- Frontend sends doctor urgency from UI values:
  - `high_urgent -> URGENT`
  - `medium -> MEDIUM`
  - `routine -> ROUTINE`

### 3. Real mismatch to keep in mind

- `/tasks_list`
  - Frontend first looks for `tasks`
  - Backend actually returns `current_treatment_plan`
  - Current frontend has a fallback, so it still works

- `/task_detail`
  - Frontend sends `task_index`
  - Backend returns:
    - `task` when a task index is requested
    - `current_treatment` always
    - `plan_tasks` only when no task index is requested
  - Current frontend handles this by falling back to `current_treatment.plan_tasks`

- `/send-to-doctor`
  - Frontend may send `task_list` without `task_id`
  - Backend auto-generates `TSK-0001`, `TSK-0002`, etc.

### 4. Backend-only routes

- `/load-dashboard` is not used by the Flutter app
- `/doctor-review` is not used by the Flutter app yet

## Global Backend Behavior

- Framework: FastAPI
- Auth: none implemented
- CORS: open to all origins/methods/headers
- Standard error shapes:
  - `HTTPException` -> `{ "detail": ... }`
  - validation error -> `{ "detail": [...] }`
  - unhandled error -> `{ "detail": "Internal Server Error" }`

## Shared Enum Notes

- Case status enum in backend:
  - `CREATION`
  - `AI_PROCESSING`
  - `DOCTOR_REVIEW`
  - `PLAN_ISSUED`
  - `TREATMENT_ACTIVE`
  - `APPOINTMENT`
  - `COMPLETED`

- Urgency enum in backend:
  - `URGENT`
  - `MEDIUM`
  - `ROUTINE`

- Valid wound `shape` enum in backend:
  - `round`
  - `oval`
  - `irregular`
  - `linear`
  - `punched_out`

- Valid `depth_category` enum in backend:
  - `superficial`
  - `partial_thickness`
  - `full_thickness`
  - `deep`
  - `very_deep_exposed_bone_tendon`

## Detailed Contracts

## Connectivity And Docs

### `POST /load-dashboard`

- Frontend use: No
- Backend purpose: simple connectivity/CORS check
- Request body: none
- Response:

```json
{
  "message": "CORS is working!"
}
```

### `GET /docs`

- Frontend use: URI configured only, not called
- Backend purpose: FastAPI Swagger UI
- Notes:
  - Not a custom route in code
  - Available because FastAPI docs are enabled

## Patients

### `GET /patients_list`

- Frontend use: patient search page
- Backend input:
  - query param `limit`, default `50`, clamped to `1..200`
- Backend response:

```json
{
  "status": "success",
  "patients": [
    {
      "patient_id": "PT-2603-00001",
      "patient_name": "John Doe",
      "nrc_id": "12/ABC(N)123456",
      "phone_no": "0812345678",
      "dob": "1990-01-01",
      "gender": "male",
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
      "photo_url": "https://..."
    }
  ]
}
```

- Frontend fields actually consumed:
  - `patient_id`, `patient_name`, `nrc_id`, `phone_no`, `dob`, `gender`
  - `height_cm`, `weight_kg`, `medical_history`
  - `diabetes.*`
  - `status`
  - `photo_url` or `patient_photo_url` or `patient_photo`

### `POST /create-patient-profile`

- Frontend use: new patient registration
- Content type: `multipart/form-data`
- Frontend sends:
  - `patient_data` as JSON string
  - `image` optional

```json
{
  "nrc_id": "12/ABC(N)123456",
  "patient_name": "John Doe",
  "phone_no": "0812345678",
  "dob": "22/03/1990",
  "gender": "male",
  "height_cm": "170",
  "weight_kg": "65",
  "medical_history": "DM, HTN",
  "diabetes": {
    "has_diabetes": "Yes",
    "years": "1-5y",
    "risk_history": [],
    "complications": []
  },
  "created_at": "2026-03-22 22:15:33"
}
```

- Backend validation:
  - validates against `PatientSchema`
  - casts `height_cm` and `weight_kg` to float before storing
  - adds `status` default `"Active"` if omitted
  - generates `patient_id` format `PT-YYMM-#####`
  - stores `photo_url` if image uploaded
- Backend response:

```json
{
  "status": "success",
  "patient_id": "PT-2603-00002",
  "photo_url": "https://...",
  "message": "Profile created for John Doe"
}
```

### `PATCH /patients/{patient_id}`

- Frontend use: edit existing patient profile
- Frontend sends: JSON with same fields as create flow
- Backend behavior:
  - removes null fields
  - casts `height_cm` and `weight_kg` to float if present
  - adds `synced_at`
  - merges into existing patient document
- Backend response:

```json
{
  "status": "success",
  "patient_id": "PT-2603-00002",
  "updated_fields": ["phone_no", "weight_kg", "synced_at"]
}
```

## Cases

### `POST /create-case`

- Frontend use: first case creation after vital check
- Frontend sends:

```json
{
  "patient_id": "PT-2603-00002",
  "status": "CREATION",
  "vitals": {
    "temperature": "High",
    "blood_pressure": "Very High",
    "heart_rate": "High",
    "respiratory_rate": "High",
    "blood_sugar": "Very High"
  },
  "meta": {
    "sent_at": "2026-03-22 22:15:33"
  }
}
```

- Backend validation/model:
  - `CreateCaseRequest`
  - invalid `status` falls back to `CREATION`
  - invalid `urgency` becomes `null`
  - `meta.sent_at` parsed with `%Y-%m-%d %H:%M:%S`, otherwise current UTC
  - stores `blood_sugar` as `blood_glucose`
  - creates first record `REC-00001`
  - generates case ID format `CS-YYMMDD-#####`
- Backend response:

```json
{
  "status": "Case creation success",
  "patient_id": "PT-2603-00002",
  "case_id": "CS-260322-00002",
  "record_id": "REC-00001"
}
```

- Frontend requirement:
  - only needs HTTP `200` and the three IDs

### `POST /update_cases`

- Frontend use: follow-up flow
- Frontend sends same shape as create-case plus `case_id`
- Backend validation/model:
  - `UpdateCaseRequest`
  - requires `case_id`
  - confirms `patient_id` matches the case
  - creates a new follow-up `record_id`
  - copies forward latest non-null sections, including:
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
    - `task_list`
    - `analysis`
  - duplicates latest treatment plan with a fresh `plan_id` when present
- Backend response:

```json
{
  "status": "Case update success",
  "patient_id": "PT-2603-00002",
  "case_id": "CS-260322-00002",
  "record_id": "REC-00002"
}
```

### `POST /cases_list`

- Frontend use: cases tab, patient case picker
- Frontend sends:

```json
{
  "limit": 50,
  "patient_id": "PT-2603-00002"
}
```

- Backend behavior:
  - `limit` clamped to `1..200`
  - with `patient_id`, filters only
  - without `patient_id`, orders by `case_updated_at` desc
- Backend response:

```json
{
  "status": "success",
  "cases": [
    {
      "case_id": "CS-260322-00002",
      "patient_id": "PT-2603-00002",
      "status": "DOCTOR_REVIEW",
      "urgency": "URGENT",
      "current_record_id": "REC-00002",
      "current_analysis_id": "AN-20260322112233",
      "current_plan_id": "PL-20260322112233"
    }
  ]
}
```

### `POST /case_detail`

- Frontend use: opening a case detail page
- Frontend sends:

```json
{
  "case_id": "CS-260322-00002"
}
```

- Backend behavior:
  - loads case document
  - loads records ordered by `record_created_at` ascending
  - loads `patient_profile` from patient ID
- Backend response:

```json
{
  "status": "success",
  "case": {},
  "records": [],
  "patient_profile": {}
}
```

- Frontend fields consumed from case/records include:
  - top-level `status`, `urgency`
  - `current_*` snapshot fields
  - per-record `vital_signs`, `wound_detail`, `image.image_folder_url`
  - `analysis.classifications`
  - `treatment_plan.plan_tasks`
  - `task_list`

## Analysis

### `POST /analyze-fillin`

- Frontend use: after camera capture
- Content type: `multipart/form-data`
- Frontend sends:
  - `case_id`
  - `record_id`
  - `image`
- Backend behavior:
  - validates image with PIL
  - uploads image to Firebase Storage
  - stores `image.image_folder_url` on the record
  - invokes Gemini with JSON response mime type
- Backend response:

```json
{
  "status": "success",
  "case_id": "CS-260322-00002",
  "record_id": "REC-00001",
  "analysis": {},
  "image_id": "CS-260322-00002-REC-00001-20260322112233.jpg",
  "image_url": "https://..."
}
```

- Blocked response possible:

```json
{
  "status": "blocked",
  "reason": "..."
}
```

### `POST /analyze-wound`

- Frontend use: submit wound assessment
- Content type: `multipart/form-data`
- Frontend sends:
  - `payload_data` JSON string
  - `image`

- Frontend `payload_data` top-level shape:

```json
{
  "patient_profile": {},
  "nurse_reviewed": {
    "nurse_reviewed_flag": false,
    "vital_signs": {},
    "wound_detail": {},
    "ischemia": {},
    "infection": {},
    "neuropathy": {},
    "sinbad": {},
    "lab_results": {},
    "vascular": {},
    "gangrene_extent": null
  },
  "ai_prefill": {},
  "case_ref": {
    "patient_id": "PT-2603-00002",
    "case_id": "CS-260322-00002",
    "record_id": "REC-00001"
  }
}
```

- Backend behavior:
  - parses `payload_data`
  - stores nurse-reviewed sections into the current record and current case snapshot
  - marks case/record `ANALYZING`
  - runs 3 Gemini layers
  - stores analysis snapshot into record and case
- Backend response:

```json
{
  "status": "success",
  "analysis": "{\"AI_analysis\": {...}, \"treatment_plan\": {...}}"
}
```

- Important:
  - backend returns `analysis` as a JSON string
  - frontend already handles that correctly

### `POST /analyze-healing`

- Frontend use: follow-up flow only, after analyze-wound success
- Frontend sends:

```json
{
  "case_id": "CS-260322-00002"
}
```

- Backend behavior:
  - loads all records for case in ascending time order
  - optionally loads each wound image from storage
  - asks Gemini for a text healing-progress summary
  - stores summary into latest record and case
  - marks latest record/case `DOCTOR_REVIEW`
  - creates new `analysis_versions` entry sourced as `AI_HEALING`
- Backend response:

```json
{
  "status": "success",
  "analysis": "Healing has improved compared with prior record.",
  "records": []
}
```

### `POST /send-to-doctor`

- Frontend use: doctor summary page
- Frontend sends a fully expanded clinical payload with:
  - `record_id`, `case_id`, `patient_id`, `status`, `urgency`
  - `vital_signs`
  - `wound_detail`
  - `ischemia`
  - `infection`
  - `neuropathy`
  - `sinbad`
  - `lab_results`
  - `vascular`
  - `gangrene_extent`
  - `analysis`
  - `treatment_plan`
  - `task_list`

- Backend validation:
  - validates against `WoundCaseRecordUpdate`
  - requires these nested sections to be non-null:
    - `vital_signs`
    - `wound_detail`
    - `ischemia`
    - `infection`
    - `neuropathy`
    - `sinbad`
    - `lab_results`
    - `vascular`

- Backend behavior:
  - merges incoming record sections with existing record
  - creates `analysis_id` and `plan_id`
  - stores `analysis_versions/{analysis_id}`
  - stores `plan_versions/{plan_id}`
  - auto-generates `task_id` values if missing
  - writes current snapshot back to case
  - marks case as `DOCTOR_REVIEW`

- Backend response:

```json
{
  "status": "success",
  "message": "Case sent for doctor review",
  "case_id": "CS-260322-00002",
  "record_id": "REC-00001",
  "analysis_id": "AN-20260322112233",
  "plan_id": "PL-20260322112233"
}
```

- Frontend requirement:
  - only checks HTTP `200`

### `POST /doctor-review`

- Frontend use: No current Flutter caller
- Backend purpose:
  - save a doctor-edited analysis
  - optionally attach doctor-authored treatment plan
  - preserve previous SINBAD from AI analysis when available

- Required request body fields:
  - `case_id`
  - `record_id`
  - `payload` object

- Optional:
  - `analysis_id`
  - `treatment_plan`
  - `signature`
  - `signature_base64`

- Backend response:

```json
{
  "status": "success",
  "message": "Doctor review saved",
  "analysis_id": "AN-20260322113000",
  "plan_id": "PL-20260322113000",
  "case_id": "CS-260322-00002",
  "record_id": "REC-00001",
  "source": "Doctor",
  "sinbad_copied": true
}
```

## Tasks

### `POST /tasks_list`

- Frontend use: tasks tab
- Frontend sends:

```json
{
  "limit": 200
}
```

- Backend behavior:
  - scans cases ordered by `case_updated_at` desc
  - pulls `current_treatment_plan`
  - enriches with patient name
  - only includes cases where `current_treatment_plan.plan_tasks` is non-empty

- Backend response:

```json
{
  "status": "success",
  "current_treatment_plan": [
    {
      "case_id": "CS-260322-00002",
      "patient_id": "PT-2603-00002",
      "patient_name": "John Doe",
      "current_record_id": "REC-00002",
      "current_plan_id": "PL-20260322112233",
      "current_treatment": {
        "plan_id": "PL-20260322112233",
        "status": "ACTIVE",
        "plan_tasks": []
      }
    }
  ]
}
```

- Frontend compatibility note:
  - first checks `tasks`
  - then falls back to `current_treatment_plan`
  - backend currently uses the fallback key

### `POST /task_detail`

- Frontend use: open task detail view
- Frontend sends:

```json
{
  "case_id": "CS-260322-00002",
  "task_index": 0
}
```

- Backend response shape:

```json
{
  "status": "success",
  "case_id": "CS-260322-00002",
  "patient_id": "PT-2603-00002",
  "patient_name": "John Doe",
  "current_treatment": {
    "plan_id": "PL-20260322112233",
    "plan_tasks": []
  },
  "task": {
    "task_id": "TSK-0001",
    "task_text": "Clean wound",
    "task_due": "2026-03-23T09:00:00Z",
    "status": "PENDING"
  }
}
```

- Frontend compatibility note:
  - when `task` is returned, frontend rebuilds the rest of the plan from `current_treatment.plan_tasks`

### `POST /task_update`

- Frontend use: complete one or more tasks with optional evidence photos
- Content type: `multipart/form-data`
- Frontend sends:
  - `case_id`
  - `plan_id` optional
  - `updates` JSON string
  - `images` repeated file field optional

```json
{
  "case_id": "CS-260322-00002",
  "plan_id": "PL-20260322112233",
  "updates": [
    {
      "task_id": "TSK-0001",
      "updates": {
        "status": "COMPLETED",
        "completed_at": "2026-03-22 22:15:33"
      }
    }
  ],
  "images": ["<binary file>"]
}
```

- Backend behavior:
  - `updates` must be a non-empty JSON list
  - allowed update fields only:
    - `status`
    - `task_due`
    - `completed_at`
    - `task_photo_url`
    - `task_text`
  - if images are sent, image count must equal update count
  - uploads each image and overwrites `task_photo_url`
  - updates task inside current case snapshot and inside `plan_versions/{plan_id}/tasks`

- Backend response:

```json
{
  "status": "success",
  "case_id": "CS-260322-00002",
  "plan_id": "PL-20260322112233",
  "updated_task_ids": ["TSK-0001"]
}
```

## Recommended Contract Decisions

- Keep backend response wrappers for `/patients_list` and `/cases_list`; frontend already supports them.
- Keep `/analyze-wound.analysis` as string only if needed for compatibility, but object output would simplify the contract.
- Standardize task list response key to `tasks` or document `current_treatment_plan` as the official key; right now the frontend depends on a fallback.
- If doctor workflow moves into Flutter, `/doctor-review` should get a first-class frontend payload model and documented response examples in the app-side docs too.

## Source Files Used

- Frontend:
  - `lib/widgets/main_navigation_screen.dart`
  - `lib/pages/doctor_summary_page.dart`
  - `lib/pages/case_detail_page.dart`
  - `lib/pages/tasks_page.dart`
  - `lib/pages/task_detail_page.dart`
  - `lib/pages/healing_progress_page.dart`

- Backend:
  - `../backend/app.py`
  - `../backend/routes/patients.py`
  - `../backend/routes/cases.py`
  - `../backend/routes/analysis.py`
  - `../backend/routes/task.py`
  - `../backend/schemas.py`
