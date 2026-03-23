# Foster Ulcer AI API Contract

## Overview

This document describes the backend API contract currently implemented in:

- `backend/app.py`
- `backend/routes/patients.py`
- `backend/routes/cases.py`
- `backend/routes/analysis.py`
- `backend/routes/task.py`
- `backend/schemas.py`

It also reflects the active Flutter integration found mainly in:

- `mobile_app/Ahm_flutter/flutter_application/lib/features/auth/services/case_service.dart`

This is an implementation-based contract, not a generated OpenAPI spec.

## Base URL

Backend local base URL:

```text
http://10.0.2.2:8080
```

Most implemented endpoints are mounted directly at the root, for example:

```text
POST /cases_list
POST /doctor-review
POST /complete_case
```

## Content Types

- `application/json`
- `multipart/form-data`

## Authentication

No authentication or authorization is currently enforced by the backend.

## Standard Error Shape

FastAPI error responses are generally returned as:

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

Current backend behavior:

- In `routes/cases.py`, backend-generated timestamps are normalized to UTC.
- Frontend-provided datetimes are parsed and converted to UTC before storage.
- `appointment_at` and `completed_at` should be sent as ISO 8601 datetimes.
- Some other files still use Firestore server timestamps, especially `routes/analysis.py`, `routes/task.py`, and `routes/patients.py`.

Recommended frontend rule:

- Always send ISO 8601 with timezone offset, for example `2026-03-23T14:30:00+07:00`.

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
- `ROUTINE`

## High-Level Data Model

### Patient

```json
{
  "patient_id": "PT-2603-00001",
  "patient_name": "John Doe",
  "phone_no": "0812345678",
  "dob": "1990-01-01",
  "gender": "female",
  "height_cm": 160.0,
  "weight_kg": 55.0,
  "medical_history": "DM",
  "diabetes": {
    "has_diabetes": "Yes",
    "years": "1-5y",
    "risk_history": [],
    "complications": []
  },
  "photo_url": "https://..."
}
```

### Case

```json
{
  "case_id": "CS-260323-00001",
  "patient_id": "PT-2603-00001",
  "status": "PLAN_ISSUED",
  "urgency": "MEDIUM",
  "current_record_id": "REC-00001",
  "current_analysis_id": "AN-20260323143000",
  "current_plan_id": "PL-20260323143000",
  "case_created_at": "2026-03-23T07:30:00+00:00",
  "case_updated_at": "2026-03-23T09:00:00+00:00"
}
```

The case document also stores current snapshot fields:

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
- `current_gangrene_extent`
- `current_analysis`
- `current_treatment_plan`
- `current_task_list`
- `current_healing_progress`

### Record

Important record sections:

- `record_id`
- `case_id`
- `patient_id`
- `status`
- `urgency`
- `timestamps`
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
- `image`
- `current_healing_progress`

### Vital Signs

Current stored shape:

```json
{
  "temperature": "...",
  "blood_pressure": "120/80",
  "blood_pressure_systolic": "120",
  "blood_pressure_diastolic": "80",
  "blood_glucose": "...",
  "heart_rate": "...",
  "respiratory_rate": "..."
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

metadata/counters_{YYMM}
metadata/counters_case_{YYMMDD}
```

## Endpoint Summary

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/load-dashboard` | Connectivity check |
| `POST` | `/create-patient-profile` | Create patient profile |
| `GET` | `/patients_list` | List patients |
| `PATCH` | `/patients/{patient_id}` | Update patient profile |
| `POST` | `/create-case` | Create first case record |
| `POST` | `/update_cases` | Create follow-up record |
| `POST` | `/cases_list` | List cases, optionally filtered by status |
| `POST` | `/case_detail` | Load case, records, patient profile |
| `POST` | `/send-to-doctor` | Save nurse-reviewed record and create AI analysis/plan versions |
| `POST` | `/doctor-review` | Save doctor-reviewed analysis and plan |
| `POST` | `/create_appointment` | Move current case/record/plan/tasks to `APPOINTMENT` |
| `POST` | `/request_close` | Mark case and current record as `REQUEST_CLOSE` |
| `POST` | `/complete_case` | Move current case/record/plan/tasks to `COMPLETED` |
| `POST` | `/analyze-fillin` | Upload image and get fill-in output |
| `POST` | `/analyze-wound` | Run AI wound analysis |
| `POST` | `/analyze-healing` | Generate healing progress |
| `POST` | `/tasks_list` | List current treatment plans with tasks |
| `POST` | `/task_detail` | Load one task or the current plan task list |
| `POST` | `/task_update` | Update current plan tasks |

## Endpoint Contracts

### `POST /create-patient-profile`

Content type: `multipart/form-data`

Fields:

- `patient_data`: JSON string, required
- `image`: file, optional

Success response:

```json
{
  "status": "success",
  "patient_id": "PT-2603-00001",
  "photo_url": "https://...",
  "message": "Profile created for John Doe"
}
```

### `GET /patients_list?limit=50`

Success response:

```json
{
  "status": "success",
  "patients": []
}
```

### `PATCH /patients/{patient_id}`

Body: partial JSON object with non-null fields to merge.

Success response:

```json
{
  "status": "success",
  "patient_id": "PT-2603-00001",
  "updated_fields": ["phone_no", "weight_kg", "synced_at"]
}
```

### `POST /create-case`

Request body:

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

Success response:

```json
{
  "status": "Case creation success",
  "patient_id": "PT-2603-00001",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001"
}
```

### `POST /update_cases`

Request body is the same shape as `/create-case`, plus:

- `case_id`: required

Behavior:

- creates a new follow-up record
- carries forward non-null sections from the latest/current record
- may duplicate the latest treatment plan into a new `plan_id`

### `POST /cases_list`

Request body:

```json
{
  "limit": 50,
  "patient_id": "PT-2603-00001",
  "filter": ["REQUEST_CLOSE", "APPOINTMENT"]
}
```

Notes:

- `filter` is optional
- when present, backend applies `where status in [...]`
- status values are uppercased internally
- Firestore `in` is capped, so the backend trims to at most 10 values

Success response:

```json
{
  "status": "success",
  "cases": []
}
```

### `POST /case_detail`

Request body:

```json
{
  "case_id": "CS-260323-00001"
}
```

Success response:

```json
{
  "status": "success",
  "case": {},
  "records": [],
  "patient_profile": {}
}
```

### `POST /send-to-doctor`

Request body: `WoundCaseRecordUpdate` payload.

Required clinical sections:

- `vital_signs`
- `wound_detail`
- `ischemia`
- `infection`
- `neuropathy`
- `sinbad`
- `lab_results`
- `vascular`

Behavior:

- merges into the existing record
- creates `analysis_versions/{analysis_id}`
- creates `plan_versions/{plan_id}`
- creates plan task documents
- updates case current snapshot

Success response:

```json
{
  "status": "success",
  "message": "Case sent for doctor review",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "analysis_id": "AN-20260323090000",
  "plan_id": "PL-20260323090000"
}
```

### `POST /doctor-review`

Request body:

```json
{
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "analysis_id": "AN-20260323090000",
  "payload": {
    "analysis": {
      "diagnosis": "...",
      "description": "...",
      "healing_progress": "..."
    }
  },
  "treatment_plan": {
    "plan_text": "...",
    "followup_days": 7,
    "plan_tasks": [
      {
        "task_text": "Apply dressing",
        "task_due": "2026-03-30"
      }
    ]
  },
  "signature_base64": "data:image/png;base64,..."
}
```

Behavior:

- creates a new doctor analysis version
- creates a new doctor plan version when `treatment_plan` is provided
- forces plan status to `SENT`
- forces each plan task status to `SENT`
- updates case and record status to `PLAN_ISSUED`
- preserves previous `SINBAD` classification

Success response:

```json
{
  "status": "success",
  "message": "Doctor review saved",
  "analysis_id": "AN-20260323100000",
  "plan_id": "PL-20260323100000",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001",
  "source": "Doctor",
  "sinbad_copied": true
}
```

### `POST /create_appointment`

Request body:

```json
{
  "case_id": "CS-260323-00001",
  "appointment_at": "2026-03-25T10:00:00+07:00"
}
```

Behavior:

- resolves `record_id` from `current_record_id`
- updates case, current record, current plan, and current tasks to `APPOINTMENT`
- writes `timestamps.appointment_at`

Success response:

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

### `POST /request_close`

Request body:

```json
{
  "case_id": "CS-260323-00001"
}
```

Behavior:

- resolves `record_id` from `current_record_id`
- updates only case and current record to `REQUEST_CLOSE`
- does not change plan or task statuses

Success response:

```json
{
  "status": "success",
  "message": "Close request saved",
  "case_id": "CS-260323-00001",
  "record_id": "REC-00001"
}
```

### `POST /complete_case`

Request body:

```json
{
  "case_id": "CS-260323-00001",
  "completed_at": "2026-03-26T16:00:00+07:00"
}
```

`completed_at` is optional. If omitted, backend uses current UTC time.

Behavior:

- resolves `record_id` from `current_record_id`
- updates case, current record, current plan, and current tasks to `COMPLETED`
- writes `timestamps.completed_at`

Success response:

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

### `POST /analyze-fillin`

Content type: `multipart/form-data`

Fields:

- `case_id`: required
- `record_id`: required
- `image`: required

Success response:

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

### `POST /analyze-wound`

Content type: `multipart/form-data`

Fields:

- `payload_data`: JSON string, required
- `image`: required

Expected minimum `payload_data`:

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

Success response:

```json
{
  "status": "success",
  "analysis": "{\"AI_analysis\":{...}}"
}
```

Note: the final `analysis` field is returned as a JSON string, not as a nested object.

### `POST /analyze-healing`

Request body:

```json
{
  "case_id": "CS-260323-00001"
}
```

Success response:

```json
{
  "status": "success",
  "analysis": "Overall wound healing is improving",
  "records": []
}
```

### `POST /tasks_list`

Request body:

```json
{
  "limit": 200
}
```

Success response:

```json
{
  "status": "success",
  "current_treatment_plan": []
}
```

### `POST /task_detail`

Request body:

```json
{
  "case_id": "CS-260323-00001",
  "task_index": 0
}
```

Success response:

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

### `POST /task_update`

Content type: `multipart/form-data`

Fields:

- `case_id`: required
- `plan_id`: optional
- `updates`: JSON string list, required
- `images`: optional file list

Example `updates`:

```json
[
  {
    "task_id": "TSK-0001",
    "updates": {
      "status": "COMPLETED",
      "task_due": "2026-03-30",
      "completed_at": "2026-03-30T09:00:00+00:00",
      "task_text": "Updated task text"
    }
  }
]
```

Success response:

```json
{
  "status": "success",
  "case_id": "CS-260323-00001",
  "plan_id": "PL-20260323100000",
  "updated_task_ids": ["TSK-0001"]
}
```

## Case Workflow

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

## Mobile App Integration Notes

Observed live Flutter usage:

- `case_service.dart` uses `/cases_list`, `/case_detail`, `/task_detail`, `/doctor-review`, and `/complete_case`
- the Flutter app maps `current_*` snapshot fields heavily for detail display
- current mobile code expects direct-root endpoints such as:
  - `/cases_list`
  - `/case_detail`
  - `/doctor-review`
  - `/complete_case`

Some placeholder mobile code still references `/api/v1/...` routes that are not implemented in this backend. Those should be treated as non-live or mock-oriented unless the backend is later versioned to match them.

## Known Gaps

- Response formats are not fully standardized across endpoints.
- Some non-`cases.py` routes still use Firestore server timestamps.
- Some mobile service code still contains mock or legacy `/api/v1/...` references.
- Read operations use `POST` in several places.
- There is no auth layer yet.

## Recommended Next Step

If this document will be shared externally, the next step should be to convert it into:

1. a strict OpenAPI schema
2. a shared error model
3. a versioned API namespace such as `/api/v1`
