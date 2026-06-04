# Foster Ulcer AI Manual Test Guide

## Purpose

This document is a step-by-step manual test flow for the current backend API, starting from patient creation and ending at case completion.

It is designed for teammate testing with Postman, Bruno, Insomnia, or `curl`.

## Base URL

Use your local backend base URL:

```text
http://10.0.2.2:8080
```

If you are testing from the same machine outside Android emulator, you may also use:

```text
http://127.0.0.1:8080
```

## Suggested Test Data

Use a unique patient name each run, for example:

- `API Test Patient 2026-03-23 A`

Use ISO datetimes with timezone when possible, for example:

- `2026-03-23T14:30:00+07:00`

## Test Flow Summary

Main flow:

1. Create patient profile
2. Create case
3. Get case list
4. Get case detail
5. Upload image with analyze-fillin
6. Run analyze-wound
7. Send to doctor
8. Doctor review and issue treatment plan
9. List tasks
10. Get task detail
11. Update task
12. Create appointment
13. Request close
14. Complete case

Extra flow:

- Create follow-up record with `/update_cases`
- Filter inbox by status using `/cases_list`
- Patch patient profile with `PATCH /patients/{patient_id}`
- Register app FCM tokens with `/notification-devices/register`
- Check shared notifications with `/doctor-notifications` and `/nurse-notifications`
- Check dashboard aggregation with `GET /load-dashboard`
- Optionally test `/analyze-transcribe`
- Run a small negative-path matrix for 400/404 validation

## Test Case Matrix

| Test ID | Endpoint | Scenario | Type | Expected Result |
| --- | --- | --- | --- | --- |
| TC-001 | `POST /create-patient-profile` | Create patient profile with valid payload | Positive | Returns `status=success` and `patient_id` |
| TC-002 | `GET /patients_list` | List patients after creation | Positive | New patient appears in result |
| TC-003 | `PATCH /patients/{patient_id}` | Patch patient profile fields | Positive | Returns `status=success` and updated fields |
| TC-004 | `POST /create-case` | Create initial case for patient | Positive | Returns `case_id` and first `record_id` |
| TC-005 | `POST /cases_list` | List cases without filters | Positive | New case appears in result |
| TC-006 | `POST /cases_list` | Filter cases by `CREATION` status | Positive | Case appears while still in `CREATION` |
| TC-007 | `POST /cases_list` | Filter cases by `patient_id` | Positive | Only matching patient's case is returned |
| TC-008 | `POST /case_detail` | Load case detail by `case_id` | Positive | Returns case, records, and patient profile |
| TC-009 | `POST /analyze-fillin` | Upload wound image and get fill-in output | Positive | Returns `status=success`, `image_url`, and `analysis` |
| TC-010 | `POST /analyze-wound` | Run wound analysis with image and payload | Positive | Returns `status=success` or `blocked` |
| TC-011 | `POST /analyze-transcribe` | Transcribe audio note | Optional Positive | Returns `status=success` or `blocked` |
| TC-012 | `POST /send-to-doctor` | Save reviewed record and draft plan | Positive | Returns `analysis_id`, `plan_id`, case moves to `DOCTOR_REVIEW` |
| TC-013 | `GET /doctor-notifications` | Verify doctor notification after send-to-doctor | Positive | Matching case notification exists and doctor FCM broadcasts to `DOCTOR` tokens |
| TC-014 | `POST /doctor-review` | Finalize doctor review and issue plan | Positive | Returns new `analysis_id`, `plan_id`, case moves to `PLAN_ISSUED` |
| TC-015 | `GET /nurse-notifications` | Verify nurse notification after doctor-review | Positive | Matching case notification exists and nurse FCM broadcasts to `NURSE` tokens |
| TC-016 | `POST /case_detail` | Verify case snapshot after doctor review | Positive | Plan and tasks are `SENT` |
| TC-017 | `POST /notifications/{notification_id}/read` | Mark one notification read | Positive | Notification becomes `READ` with `read_at` |
| TC-018 | `POST /notifications/mark-all-read` | Mark all role notifications read | Positive | Returns updated count |
| TC-019 | `POST /tasks_list` | List current treatment plans | Positive | Case appears in task list |
| TC-020 | `POST /task_detail` | Get task detail by index | Positive | Selected task is returned |
| TC-021 | `POST /task_detail` | Get full task list without index | Positive | `plan_tasks` is returned |
| TC-022 | `POST /task_update` | Update task status/details | Positive | Updated task id is returned and reflected in case |
| TC-023 | `GET /load-dashboard` | Check dashboard aggregates | Positive | Returns `today_task_no`, `total_active_patient`, `upcoming_plan` |
| TC-024 | `POST /create_appointment` | Move case to appointment state | Positive | Case, record, plan, and tasks become `APPOINTMENT` |
| TC-025 | `POST /cases_list` | Filter cases by `APPOINTMENT` | Positive | Case appears in result |
| TC-026 | `POST /request_close` | Request close for current case | Positive | Case and record become `REQUEST_CLOSE` |
| TC-027 | `GET /doctor-notifications` | Verify doctor notification after request close | Positive | Matching close-request notification exists |
| TC-028 | `POST /cases_list` | Filter cases by `REQUEST_CLOSE` | Positive | Case appears in result |
| TC-029 | `POST /complete_case` | Complete the case | Positive | Case, record, plan, and tasks become `COMPLETED` |
| TC-030 | `POST /cases_list` | Filter cases by `COMPLETED` | Positive | Case appears in result |
| TC-031 | `POST /update_cases` | Create follow-up record | Optional Positive | New `record_id` is created and current record moves |
| TC-032 | `POST /analyze-healing` | Run healing analysis | Optional Positive | Returns healing summary and may update current healing snapshot |
| TC-033 | `POST /notification-devices/register` | Register doctor or nurse app token | Optional Positive | Token is stored active for role broadcast |
| TC-034 | `POST /notification-devices/unregister` | Unregister app token | Optional Positive | Token is marked inactive |
| TC-035 | `POST /case_detail` | Missing `case_id` validation | Negative | Returns `400` |
| TC-036 | `POST /task_update` | Wrong `plan_id` validation | Negative | Returns `400` |
| TC-037 | `POST /create_appointment` | Invalid datetime validation | Negative | Returns `400` |
| TC-038 | `POST /request_close` | Missing `case_id` validation | Negative | Returns `400` |
| TC-039 | `POST /complete_case` | Missing `case_id` validation | Negative | Returns `400` |
| TC-036 | `POST /update_cases` | Mismatched `patient_id` validation | Negative | Returns `400` |

## Variables To Save During Testing

Save these values as you go:

- `patient_id`
- `case_id`
- `record_id`
- `analysis_id`
- `plan_id`
- `task_id`
- `notification_id`

## TC-001 Create Patient Profile

Endpoint:

```http
POST /create-patient-profile
Content-Type: multipart/form-data
```

Form field `patient_data`:

```json
{
  "nrc_id": "1234567890123",
  "patient_name": "API Test Patient 2026-03-23 A",
  "phone_no": "0812345678",
  "dob": "19/03/2001",
  "gender": "female",
  "height_cm": 160,
  "weight_kg": 55,
  "medical_history": "Diabetes mellitus",
  "diabetes": {
    "has_diabetes": "Yes",
    "years": "1-5y",
    "risk_history": ["Past Ulcer"],
    "complications": ["Eyes (Retinopathy)"]
  },
  "created_at": "2026-03-23 14:00:00",
  "status": "Active"
}
```

Optional:

- attach `image`

Expected:

- response contains `patient_id`
- status is `success`

## TC-002 List Patients

Endpoint:

```http
GET /patients_list?limit=20
```

Expected:

- new patient appears in `patients`

## TC-004 Create Case

Endpoint:

```http
POST /create-case
Content-Type: application/json
```

Body:

```json
{
  "patient_id": "{{patient_id}}",
  "status": "CREATION",
  "urgency": "MEDIUM",
  "created_by_nurse": "NURSE-001",
  "assigned_doctor": "DR-001",
  "vitals": {
    "temperature": "37.0",
    "blood_pressure": "120/80",
    "blood_pressure_systolic": "120",
    "blood_pressure_diastolic": "80",
    "blood_glucose": "145",
    "heart_rate": "76",
    "respiratory_rate": "18"
  },
  "meta": {
    "sent_at": "2026-03-23T14:30:00+07:00"
  }
}
```

Expected:

- response contains `case_id`
- response contains first `record_id`
- case status is `CREATION`

## TC-005 List Cases

Endpoint:

```http
POST /cases_list
Content-Type: application/json
```

Body:

```json
{
  "limit": 20
}
```

Expected:

- new case appears in `cases`

## TC-006 Filter Cases By Status

Endpoint:

```http
POST /cases_list
Content-Type: application/json
```

Body:

```json
{
  "filter": ["CREATION"]
}
```

Expected:

- new case appears when it is still in `CREATION`

## TC-008 Load Case Detail

Endpoint:

```http
POST /case_detail
Content-Type: application/json
```

Body:

```json
{
  "case_id": "{{case_id}}"
}
```

Expected:

- `case` is returned
- `records` includes `REC-00001`
- `patient_profile.patient_id` matches

## TC-009 Upload Image And Get Fill-In

Endpoint:

```http
POST /analyze-fillin
Content-Type: multipart/form-data
```

Form fields:

- `case_id` = `{{case_id}}`
- `record_id` = `{{record_id}}`
- `image` = attach test wound image

Expected:

- response contains `image_url`
- response contains `analysis`

## TC-010 Run AI Wound Analysis

Endpoint:

```http
POST /analyze-wound
Content-Type: multipart/form-data
```

Form field `payload_data`:

```json
{
  "case_ref": {
    "patient_id": "{{patient_id}}",
    "case_id": "{{case_id}}",
    "record_id": "{{record_id}}"
  },
  "patient_profile": {
    "patient_id": "{{patient_id}}",
    "patient_name": "API Test Patient 2026-03-23 A"
  },
  "nurse_reviewed": {
    "nurse_reviewed_flag": true,
    "vital_signs": {
      "temperature": "37.0",
      "blood_pressure": "120/80",
      "blood_pressure_systolic": "120",
      "blood_pressure_diastolic": "80",
      "blood_glucose": "145",
      "heart_rate": "76",
      "respiratory_rate": "18"
    },
    "wound_detail": {
      "location_primary": "toe",
      "location_detail": "left great toe",
      "wound_type": "ulcer",
      "shape": "irregular",
      "size": {
        "width_cm": 2.4,
        "length_cm": 3.1
      },
      "depth_category": "full_thickness",
      "bed": {
        "slough_pct": 40,
        "necrotic_pct": 10
      },
      "edge_description": "irregular",
      "periwound_status": "erythematous",
      "discharge": {
        "volume": "moderate",
        "type": "seropurulent (cloudy yellow)"
      },
      "odor_presence": "faint",
      "pain_score": 5,
      "has_infection": true,
      "skin_condition": "dry"
    },
    "ischemia": {
      "points": [1],
      "pulse": "yes",
      "checklist": []
    },
    "infection": {
      "checklist": ["Warmth (hotter than other foot)"],
      "erythema_extent": "gt_0_5_cm",
      "probe_to_bone_test": "negative",
      "has_deep_abscess_or_fasciitis": false
    },
    "neuropathy": {
      "points": [1]
    },
    "sinbad": {
      "site": "Forefoot",
      "ischemia": "No",
      "neuropathy": "Yes",
      "infection": "Yes",
      "area": ">= 1 cm²",
      "depth": "Skin only"
    },
    "lab_results": {
      "wbc_count": "11000",
      "crp": "15",
      "esr": "25",
      "procalcitonin": "0.2"
    },
    "vascular": {
      "abi_value": "1.0",
      "ankle_pressure_mmHg": "120",
      "toe_pressure_mmHg": "90",
      "tcpo2_mmHg": "55"
    },
    "gangrene_extent": "none"
  }
}
```

Also attach `image`.

Expected:

- response status is `success`
- response contains `analysis` as JSON string

## TC-012 Send To Doctor

Endpoint:

```http
POST /send-to-doctor
Content-Type: application/json
```

Body:

```json
{
  "record_id": "{{record_id}}",
  "case_id": "{{case_id}}",
  "patient_id": "{{patient_id}}",
  "created_by_nurse": "NURSE-001",
  "assigned_doctor": "DR-001",
  "status": "DOCTOR_REVIEW",
  "urgency": "MEDIUM",
  "vital_signs": {
    "temperature": "37.0",
    "blood_pressure": "120/80",
    "blood_pressure_systolic": "120",
    "blood_pressure_diastolic": "80",
    "blood_glucose": "145",
    "heart_rate": "76",
    "respiratory_rate": "18"
  },
  "wound_detail": {
    "location_primary": "toe",
    "location_detail": "left great toe",
    "wound_type": "ulcer",
    "shape": "irregular",
    "size": {
      "width_cm": 2.4,
      "length_cm": 3.1
    },
    "depth_category": "full_thickness",
    "bed": {
      "slough_pct": 40,
      "necrotic_pct": 10
    },
    "edge_description": "irregular",
    "periwound_status": "erythematous",
    "discharge": {
      "volume": "moderate",
      "type": "seropurulent (cloudy yellow)"
    },
    "odor_presence": "faint",
    "pain_score": 5,
    "has_infection": true,
    "skin_condition": "dry"
  },
  "ischemia": {
    "points": [1],
    "pulse": "yes",
    "checklist": []
  },
  "infection": {
    "checklist": ["Warmth (hotter than other foot)"],
    "erythema_extent": "gt_0_5_cm",
    "probe_to_bone_test": "negative",
    "has_deep_abscess_or_fasciitis": false
  },
  "neuropathy": {
    "points": [1]
  },
  "sinbad": {
    "site": "Forefoot",
    "ischemia": "No",
    "neuropathy": "Yes",
    "infection": "Yes",
    "area": ">= 1 cm²",
    "depth": "Skin only"
  },
  "lab_results": {
    "wbc_count": "11000",
    "crp": "15",
    "esr": "25",
    "procalcitonin": "0.2"
  },
  "vascular": {
    "abi_value": "1.0",
    "ankle_pressure_mmHg": "120",
    "toe_pressure_mmHg": "90",
    "tcpo2_mmHg": "55"
  },
  "gangrene_extent": "none",
  "analysis": {
    "diagnosis": "Initial AI diagnosis",
    "description": "AI suggested wound review",
    "confidence": 0.8,
    "classifications": {
      "SINBAD": {
        "site": "Forefoot"
      }
    }
  },
  "treatment_plan": {
    "plan_text": "Initial draft plan",
    "followup_days": 7,
    "status": "DRAFT",
    "plan_tasks": [
      {
        "task_text": "Clean wound daily",
        "task_due": "2026-03-24",
        "status": "DRAFT"
      },
      {
        "task_text": "Check glucose level",
        "task_due": "2026-03-25",
        "status": "DRAFT"
      }
    ]
  }
}
```

Expected:

- response contains `analysis_id`
- response contains `plan_id`
- case becomes `DOCTOR_REVIEW`

## TC-014 Doctor Review And Issue Plan

Endpoint:

```http
POST /doctor-review
Content-Type: application/json
```

Body:

```json
{
  "case_id": "{{case_id}}",
  "record_id": "{{record_id}}",
  "analysis_id": "{{analysis_id}}",
  "analysis": {
    "diagnosis": "Doctor reviewed diagnosis",
    "description": "Confirmed infected ulcer",
    "healing_progress": "Baseline assessment completed",
    "classifications": {}
  },
  "treatment_plan": {
    "plan_text": "Perform dressing change, offloading, and follow-up review.",
    "followup_days": 7,
    "plan_tasks": [
      {
        "order_index": 1,
        "task_text": "Apply dressing",
        "task_due": "2026-03-24"
      },
      {
        "order_index": 2,
        "task_text": "Offloading education",
        "task_due": "2026-03-24"
      },
      {
        "order_index": 3,
        "task_text": "Review in clinic",
        "task_due": "2026-03-30"
      }
    ]
  },
  "ai_result_edit_flag": true,
  "treatment_plan_edit_flag": true,
  "signature_base64": "data:image/png;base64,TEST_SIGNATURE"
}
```

Expected:

- response contains new `analysis_id`
- response contains new `plan_id`
- case status becomes `PLAN_ISSUED`
- plan status becomes `SENT`
- all task statuses become `SENT`
- task order is saved from `order_index` and normalized to sequential values
- task `source` is preserved when provided, otherwise defaults to `Doctor`

## TC-016 Check Case Detail After Doctor Review

Call `/case_detail` again.

Expected:

- `case.status` is `PLAN_ISSUED`
- `case.current_treatment_plan.status` is `SENT`
- `case.current_treatment_plan.plan_tasks[*].status` is `SENT`
- `case.current_healing_progress` may be set if included in analysis

Save first task id from:

- `case.current_treatment_plan.plan_tasks[0].task_id`

## TC-017 List Tasks

Endpoint:

```http
POST /tasks_list
Content-Type: application/json
```

Body:

```json
{
  "limit": 50
}
```

Expected:

- case appears in `current_treatment_plan`

## TC-018 Get Task Detail

Endpoint:

```http
POST /task_detail
Content-Type: application/json
```

Body:

```json
{
  "case_id": "{{case_id}}",
  "task_index": 0
}
```

Expected:

- task detail is returned

## TC-020 Update Task

Endpoint:

```http
POST /task_update
Content-Type: multipart/form-data
```

Form field `case_id`:

```text
{{case_id}}
```

Form field `plan_id`:

```text
{{plan_id}}
```

Form field `updates`:

```json
[
  {
    "task_id": "{{task_id}}",
    "updates": {
      "status": "COMPLETED",
      "completed_at": "2026-03-24T09:30:00+07:00",
      "task_text": "Apply dressing and document wound"
    }
  }
]
```

Optional:

- attach one image in `images`

Expected:

- response contains `updated_task_ids`
- current treatment plan reflects updated task

## TC-022 Create Appointment

Endpoint:

```http
POST /create_appointment
Content-Type: application/json
```

Body:

```json
{
  "case_id": "{{case_id}}",
  "appointment_at": "2026-03-30T10:00:00+07:00"
}
```

Expected:

- case status becomes `APPOINTMENT`
- current record status becomes `APPOINTMENT`
- current plan status becomes `APPOINTMENT`
- `case.current_treatment_plan.plan_tasks[*].status` becomes `APPOINTMENT`
- `record.treatment_plan.plan_tasks[*].status` becomes `APPOINTMENT`

## TC-023 Filter Appointment Cases

Endpoint:

```http
POST /cases_list
Content-Type: application/json
```

Body:

```json
{
  "filter": ["APPOINTMENT"]
}
```

Expected:

- test case appears in result

## TC-024 Request Close

Endpoint:

```http
POST /request_close
Content-Type: application/json
```

Body:

```json
{
  "case_id": "{{case_id}}"
}
```

Expected:

- case status becomes `REQUEST_CLOSE`
- current record status becomes `REQUEST_CLOSE`
- plan and tasks should remain unchanged

## TC-026 Filter Request Close Cases

Endpoint:

```http
POST /cases_list
Content-Type: application/json
```

Body:

```json
{
  "filter": ["REQUEST_CLOSE"]
}
```

Expected:

- test case appears in result

## TC-027 Complete Case

Endpoint:

```http
POST /complete_case
Content-Type: application/json
```

Body:

```json
{
  "case_id": "{{case_id}}",
  "completed_at": "2026-03-31T16:00:00+07:00"
}
```

Expected:

- case status becomes `COMPLETED`
- record status becomes `COMPLETED`
- plan status becomes `COMPLETED`
- tasks become `COMPLETED`
- `timestamps.completed_at` is written

## TC-028 Filter Completed Cases

Endpoint:

```http
POST /cases_list
Content-Type: application/json
```

Body:

```json
{
  "filter": ["COMPLETED"]
}
```

Expected:

- test case appears in result

## TC-029 Create Follow-Up Record

This is an optional secondary test after the first lifecycle is proven.

Endpoint:

```http
POST /update_cases
Content-Type: application/json
```

Body:

```json
{
  "patient_id": "{{patient_id}}",
  "case_id": "{{case_id}}",
  "status": "CREATION",
  "urgency": "MEDIUM",
  "created_by_nurse": "NURSE-001",
  "assigned_doctor": "DR-001",
  "vitals": {
    "temperature": "36.8",
    "blood_pressure": "118/78",
    "blood_pressure_systolic": "118",
    "blood_pressure_diastolic": "78",
    "blood_glucose": "138",
    "heart_rate": "74",
    "respiratory_rate": "18"
  },
  "meta": {
    "sent_at": "2026-04-01T09:00:00+07:00"
  }
}
```

Expected:

- new `record_id` is created
- latest treatment plan may be duplicated into a new `plan_id`
- `current_record_id` moves to the new record

## TC-030 Analyze Healing

Endpoint:

```http
POST /analyze-healing
Content-Type: application/json
```

Body:

```json
{
  "case_id": "{{case_id}}"
}
```

Expected:

- response contains text summary in `analysis`
- latest record and case may get `current_healing_progress`

## Quick Validation Checklist

- patient can be created
- case can be created
- case list returns case
- case detail returns patient + records
- image upload works
- analyze wound works
- send-to-doctor works
- doctor-review creates plan and tasks from top-level `analysis` and `treatment_plan`
- plan/tasks move to `SENT`
- task update works
- appointment changes case/record/plan/tasks to `APPOINTMENT`
- request close changes case/record to `REQUEST_CLOSE`
- complete case changes case/record/plan/tasks to `COMPLETED`
- status filter in `/cases_list` works for:
  - `CREATION`
  - `APPOINTMENT`
  - `REQUEST_CLOSE`
  - `COMPLETED`

## Notes

- `/doctor-review` still requires explicit `record_id`
- `/doctor-review` prefers top-level `analysis` and `treatment_plan`; legacy `payload` is still accepted
- `/create_appointment`, `/request_close`, and `/complete_case` use the case’s `current_record_id`
- some timestamps outside `routes/cases.py` still rely on Firestore server timestamps
- if Firestore composite indexes are missing, some filtered queries may require index creation

## Missing Coverage Added

The original flow was missing several current routes and several negative-path checks. These cases should also be treated as required coverage.

### TC-003 Update Patient Profile

Endpoint:

```http
PATCH /patients/{patient_id}
Content-Type: application/json
```

Body:

```json
{
  "phone_no": "0899999999",
  "weight_kg": 56
}
```

Expected:

- response status is `success`
- `updated_fields` contains the patched keys
- later `/patients_list` reflects the update

### TC-007 Filter Cases By Patient

Endpoint:

```http
POST /cases_list
Content-Type: application/json
```

Body:

```json
{
  "patient_id": "{{patient_id}}"
}
```

Expected:

- the test case is returned
- every returned case belongs to `{{patient_id}}`

### TC-013 and TC-025 Check Doctor Notifications

Run this immediately after `/send-to-doctor`.

Endpoint:

```http
GET /doctor-notifications?limit=50
```

Expected:

- a notification exists for `{{case_id}}`
- the notification `record_id` matches `{{record_id}}`
- if active Android tokens are registered with `role = "DOCTOR"`, FCM broadcasts to the doctor app

Run this again after `/request_close`.

Expected:

- another doctor-facing notification exists for the same case

### TC-015 Check Nurse Notifications

Run this immediately after `/doctor-review`.

Endpoint:

```http
GET /nurse-notifications?limit=50
```

Expected:

- a notification exists for `{{case_id}}`
- the notification `record_id` matches `{{record_id}}`
- if active Android tokens are registered with `role = "NURSE"`, FCM broadcasts to the nurse app

### TC-017 Mark One Notification Read

Endpoint:

```http
POST /notifications/{{notification_id}}/read
Content-Type: application/json
```

Body:

```json
{
  "role": "DOCTOR"
}
```

Expected:

- response `status` is `success`
- notification `status` becomes `READ`
- notification `read_at` is set

### TC-018 Mark All Notifications Read

Endpoint:

```http
POST /notifications/mark-all-read
Content-Type: application/json
```

Body:

```json
{
  "role": "NURSE"
}
```

Expected:

- response `status` is `success`
- response includes `updated_count`
- unread notifications for that role feed become `READ`

### TC-033 and TC-034 Register / Unregister Notification Device

Register doctor app token:

```http
POST /notification-devices/register
Content-Type: application/json
```

```json
{
  "user_id": "doctor-app",
  "role": "DOCTOR",
  "fcm_token": "{{doctor_fcm_token}}",
  "platform": "android",
  "device_id": "test-doctor-device"
}
```

Register nurse app token by changing `role` to `NURSE` and using the nurse token.

Unregister:

```http
POST /notification-devices/unregister
Content-Type: application/json
```

```json
{
  "fcm_token": "{{doctor_fcm_token}}"
}
```

Expected:

- register returns `status = success` and `device_token_id`
- unregister returns `status = success` and the same token hash id
- role controls FCM broadcast targeting; `user_id` is for audit/debugging

### TC-021 Check Dashboard

Endpoint:

```http
GET /load-dashboard
```

Expected:

- response contains `today_task_no`
- response contains `total_active_patient`
- response contains `upcoming_plan`
- after a plan is issued, the test case may appear in `upcoming_plan`

### TC-019 Task Detail Without Index

Endpoint:

```http
POST /task_detail
Content-Type: application/json
```

Body:

```json
{
  "case_id": "{{case_id}}"
}
```

Expected:

- response includes `plan_tasks`
- full current task list is returned when `task_index` is omitted

### TC-011 Optional Audio Transcription

Endpoint:

```http
POST /analyze-transcribe
Content-Type: multipart/form-data
```

Form fields:

- `case_id` = `{{case_id}}`
- `record_id` = `{{record_id}}`
- `audio` = attach test audio file

Expected:

- response is either:
  - `success` with `transcript`
  - `blocked` with a model block reason

### TC-031 to TC-036 Negative-Path Matrix

These checks cover route guards that the original guide did not verify.

1. `POST /case_detail` with empty body

Expected:

- `400`
- detail mentions `case_id is required`

2. `POST /task_update` with wrong `plan_id`

Expected:

- `400`
- detail mentions plan mismatch

3. `POST /create_appointment` with invalid datetime

Body:

```json
{
  "case_id": "{{case_id}}",
  "appointment_at": "not-a-date"
}
```

Expected:

- `400`
- detail mentions invalid ISO datetime

4. `POST /request_close` with empty body

Expected:

- `400`
- detail mentions `case_id is required`

5. `POST /complete_case` with empty body

Expected:

- `400`
- detail mentions `case_id is required`

6. `POST /update_cases` with mismatched `patient_id`

Expected:

- `400`
- detail mentions `patient_id does not match case`

## Route Coverage Checklist

The guide should be considered complete only if all current routes are accounted for:

- `GET /load-dashboard`
- `POST /create-patient-profile`
- `GET /patients_list`
- `PATCH /patients/{patient_id}`
- `POST /create-case`
- `POST /update_cases`
- `POST /cases_list`
- `POST /case_detail`
- `POST /analyze-transcribe`
- `POST /analyze-fillin`
- `POST /analyze-wound`
- `POST /analyze-healing`
- `POST /send-to-doctor`
- `POST /doctor-review`
- `GET /doctor-notifications`
- `GET /nurse-notifications`
- `POST /tasks_list`
- `POST /task_detail`
- `POST /task_update`
- `POST /create_appointment`
- `POST /request_close`
- `POST /complete_case`

## Test Script

An executable smoke test script has been added:

- `api_test_runner.py`

Example:

```bash
venv\Scripts\python.exe api_test_runner.py --base-url http://127.0.0.1:8080
```

With optional files:

```bash
venv\Scripts\python.exe api_test_runner.py --base-url http://127.0.0.1:8080 --image sample.jpg --audio sample.mp3 --run-followup --run-healing
```

What it covers:

- patient create, list, patch
- case create, list, patient filter, detail
- optional image and audio AI endpoints
- send-to-doctor and doctor-review
- doctor and nurse notifications
- task list, task detail, task update
- dashboard
- appointment, request close, complete
- optional follow-up and healing
- selected negative-path validation checks
