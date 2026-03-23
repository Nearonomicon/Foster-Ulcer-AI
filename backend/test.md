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

## Variables To Save During Testing

Save these values as you go:

- `patient_id`
- `case_id`
- `record_id`
- `analysis_id`
- `plan_id`
- `task_id`

## 1. Create Patient Profile

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

## 2. List Patients

Endpoint:

```http
GET /patients_list?limit=20
```

Expected:

- new patient appears in `patients`

## 3. Create Case

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

## 4. List Cases

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

## 5. Filter Cases By Status

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

## 6. Load Case Detail

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

## 7. Upload Image And Get Fill-In

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

## 8. Run AI Wound Analysis

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

## 9. Send To Doctor

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

## 10. Doctor Review And Issue Plan

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
  "payload": {
    "analysis": {
      "diagnosis": "Doctor reviewed diagnosis",
      "description": "Confirmed infected ulcer",
      "healing_progress": "Baseline assessment completed",
      "classifications": {}
    }
  },
  "treatment_plan": {
    "plan_text": "Perform dressing change, offloading, and follow-up review.",
    "followup_days": 7,
    "plan_tasks": [
      {
        "task_text": "Apply dressing",
        "task_due": "2026-03-24"
      },
      {
        "task_text": "Offloading education",
        "task_due": "2026-03-24"
      },
      {
        "task_text": "Review in clinic",
        "task_due": "2026-03-30"
      }
    ]
  },
  "signature_base64": "data:image/png;base64,TEST_SIGNATURE"
}
```

Expected:

- response contains new `analysis_id`
- response contains new `plan_id`
- case status becomes `PLAN_ISSUED`
- plan status becomes `SENT`
- all task statuses become `SENT`

## 11. Check Case Detail After Doctor Review

Call `/case_detail` again.

Expected:

- `case.status` is `PLAN_ISSUED`
- `case.current_treatment_plan.status` is `SENT`
- `case.current_task_list[*].status` is `SENT`
- `case.current_healing_progress` may be set if included in analysis

Save first task id from:

- `case.current_task_list[0].task_id`

## 12. List Tasks

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

## 13. Get Task Detail

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

## 14. Update Task

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

## 15. Create Appointment

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
- current tasks become `APPOINTMENT`

## 16. Filter Appointment Cases

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

## 17. Request Close

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

## 18. Filter Request Close Cases

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

## 19. Complete Case

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

## 20. Filter Completed Cases

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

## 21. Create Follow-Up Record

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

## 22. Analyze Healing

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
- doctor-review creates plan and tasks
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
- `/create_appointment`, `/request_close`, and `/complete_case` use the case’s `current_record_id`
- some timestamps outside `routes/cases.py` still rely on Firestore server timestamps
- if Firestore composite indexes are missing, some filtered queries may require index creation
