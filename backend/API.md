# Wound Care AI API

Base URL: `http://127.0.0.1:8000`

All endpoints are unauthenticated by default. CORS allows `*`.

---

**Health**

`POST /load-dashboard`

**Title:** Health Check  
**Description:** Simple endpoint to verify the API is reachable and CORS is working.

Response 200
```json
{"message":"CORS is working!"}
```

---

**Patients**

`GET /patients_list`

**Title:** List Patients  
**Description:** Returns a list of patient profiles with optional limit.

**Query Params**
| Field | Type | Required | Description | Example |
|---|---|---|---|---|
| `limit` | integer | No | Max number of patients (default 50, max 200). | `50` |

Response 200
```json
{
  "status": "success",
  "patients": [
    {
      "patient_id": "PT-2603-00001",
      "patient_name": "John Doe",
      "nrc_id": "8757446557345",
      "phone_no": "0812345678",
      "dob": "1990-01-01",
      "gender": "Male",
      "height_cm": 170,
      "weight_kg": 65,
      "medical_history": "DM",
      "diabetes": {
        "has_diabetes": "yes",
        "years": "5",
        "risk_history": [],
        "complications": []
      },
      "status": "Active",
      "created_at": "2026-03-06",
      "synced_at": "2026-03-06T01:22:17Z",
      "photo_url": "https://..."
    }
  ]
}
```

Errors
- 500 server errors

---

`POST /create-patient-profile`

**Title:** Create Patient Profile  
**Description:** Creates a new patient profile and optionally uploads a profile image.

Content-Type: `multipart/form-data`

**Form Fields**
| Field | Type | Required | Description |
|---|---|---|---|
| `patient_data` | string | Yes | JSON string for patient profile. |
| `image` | file | No | Profile image file. |

**`patient_data` Schema**
| Field | Type | Required | Description | Example |
|---|---|---|---|---|
| `patient_name` | string | Yes | Patient full name. | `John Doe` |
| `nrc_id` | string | No | National ID. | `8757446557345` |
| `phone_no` | string | Yes | Phone number. | `0812345678` |
| `dob` | string | Yes | Date of birth. | `1990-01-01` |
| `gender` | string | Yes | Gender. | `Male` |
| `height_cm` | string or number | Yes | Height in cm. | `170` |
| `weight_kg` | string or number | Yes | Weight in kg. | `65` |
| `medical_history` | string | Yes | Medical history. | `DM` |
| `diabetes.has_diabetes` | string | Yes | `yes` or `no`. | `yes` |
| `diabetes.years` | string | No | Years with diabetes. | `5` |
| `diabetes.risk_history` | array | No | Risk history list. | `[]` |
| `diabetes.complications` | array | No | Complications list. | `[]` |
| `created_at` | string | Yes | Created date/time. | `2026-03-06` |
| `status` | string | No | Patient status. | `Active` |

**Example `patient_data`**
```json
{
  "patient_name": "John Doe",
  "nrc_id": "8757446557345",
  "phone_no": "0812345678",
  "dob": "1990-01-01",
  "gender": "Male",
  "height_cm": "170",
  "weight_kg": "65",
  "medical_history": "DM",
  "diabetes": {
    "has_diabetes": "yes",
    "years": "5",
    "risk_history": [],
    "complications": []
  },
  "created_at": "2026-03-06",
  "status": "Active"
}
```

Response 200
```json
{
  "status": "success",
  "patient_id": "PT-2603-00001",
  "photo_url": "https://...",
  "message": "Profile created for John Doe"
}
```

Errors
- 400 validation / format errors

---

`PATCH /patients/{patient_id}`

**Title:** Update Patient Profile  
**Description:** Updates fields for an existing patient profile.

Content-Type: `application/json`

**Request Body**
| Field | Type | Required | Description |
|---|---|---|---|
| Any patient field | various | No | Only provided non-null fields are updated. |

**Example**
```json
{
  "phone_no": "0899999999",
  "weight_kg": 70
}
```

Response 200
```json
{
  "status": "success",
  "patient_id": "PT-2603-00001",
  "updated_fields": ["phone_no", "weight_kg", "synced_at"]
}
```

Errors
- 400 no fields to update
- 500 server errors

---

**Cases**

`POST /cases_list`

**Title:** List Cases  
**Description:** Returns cases, optionally filtered by `patient_id`.

**Request Body**
| Field | Type | Required | Description | Example |
|---|---|---|---|---|
| `patient_id` | string | No | Filter by patient. | `PT-2603-00005` |
| `limit` | integer | No | Max number of cases (default 50, max 200). | `50` |

**Example**
```json
{
  "patient_id": "PT-2603-00005",
  "limit": 50
}
```

Notes
- Request body is optional. If omitted, defaults to `limit=50` and no `patient_id` filter.
- If `patient_id` is provided, results are not ordered (to avoid needing a composite Firestore index).

Response 200
```json
{
  "status": "success",
  "cases": [
    {
      "case_id": "CS-260306-00001",
      "patient_id": "PT-2603-00001",
      "status": "CREATION",
      "urgency": null,
      "case_created_at": "2026-03-06T01:22:17Z",
      "case_updated_at": "2026-03-06T01:22:17Z",
      "current_record_id": "REC-00001",
      "current_analysis_id": null,
      "current_plan_id": null
    }
  ]
}
```

Errors
- 500 server errors

---

`POST /case_detail`

**Title:** Case Detail  
**Description:** Returns case data, all records, and the related patient profile.

**Request Body**
| Field | Type | Required | Description |
|---|---|---|---|
| `case_id` | string | Yes | Case ID to load. |

**Example**
```json
{
  "case_id": "CS-260306-00001"
}
```

Response 200
```json
{
  "status": "success",
  "case": {
    "case_id": "CS-260306-00001",
    "patient_id": "PT-2603-00001",
    "status": "CREATION",
    "urgency": null,
    "case_created_at": "2026-03-06T01:22:17Z",
    "case_updated_at": "2026-03-06T01:22:17Z",
    "current_record_id": "REC-00001",
    "current_analysis_id": null,
    "current_plan_id": null
  },
  "patient_profile": {
    "patient_id": "PT-2603-00001",
    "patient_name": "John Doe",
    "nrc_id": "8757446557345",
    "phone_no": "0812345678",
    "dob": "1990-01-01",
    "gender": "Male"
  },
  "records": [
    {
      "record_id": "REC-00001",
      "case_id": "CS-260306-00001",
      "patient_id": "PT-2603-00001",
      "status": "CREATION",
      "vital_signs": {
        "temperature": "Warm",
        "blood_pressure": "Normal",
        "blood_glucose": "Normal",
        "heart_rate": "Normal",
        "respiratory_rate": "Normal"
      }
    }
  ]
}
```

Errors
- 400 missing `case_id`
- 404 case not found
- 500 server errors

---

`POST /create-case`

**Title:** Create Case  
**Description:** Creates a new case and its first record.

Content-Type: `application/json`

**Request Body**
| Field | Type | Required | Description |
|---|---|---|---|
| `patient_id` | string | Yes | Patient ID. |
| `status` | string | No | Case status. |
| `urgency` | string | No | `URGENT`, `MEDIUM`, or `ROUTINE`. |
| `created_by_nurse` | string | No | Nurse ID. |
| `assigned_doctor` | string | No | Doctor ID. |
| `vitals.temperature` | string | No | Temperature. |
| `vitals.blood_pressure` | string | No | Blood pressure. |
| `vitals.heart_rate` | string | No | Heart rate. |
| `vitals.respiratory_rate` | string | No | Respiratory rate. |
| `vitals.blood_sugar` | string | No | Blood glucose. |
| `meta.sent_at` | string | No | Client timestamp. |

**Example**
```json
{
  "patient_id": "PT-2603-00001",
  "status": "CREATION",
  "urgency": "MEDIUM",
  "created_by_nurse": "NUR-0001",
  "assigned_doctor": "DR-0001",
  "vitals": {
    "temperature": "Warm",
    "blood_pressure": "Normal",
    "heart_rate": "Normal",
    "respiratory_rate": "Normal",
    "blood_sugar": "Normal"
  },
  "meta": {
    "sent_at": "2026-03-06 01:22:17"
  }
}
```

Response 200
```json
{
  "status": "Case creation success",
  "patient_id": "PT-2603-00001",
  "case_id": "CS-260306-00001",
  "record_id": "REC-00001"
}
```

Notes
- If `urgency` is omitted, it is stored as `null`.

Errors
- 500 server errors (see terminal for traceback)

---

`POST /update_cases`

**Title:** Add Follow-Up Record  
**Description:** Updates an existing case and creates a new follow-up record.

Content-Type: `application/json`

**Request Body**
| Field | Type | Required | Description |
|---|---|---|---|
| `case_id` | string | Yes | Case ID to update. |
| `patient_id` | string | Yes | Patient ID. |
| `status` | string | No | Case status. |
| `urgency` | string | No | `URGENT`, `MEDIUM`, or `ROUTINE`. |
| `created_by_nurse` | string | No | Nurse ID. |
| `assigned_doctor` | string | No | Doctor ID. |
| `vitals.temperature` | string | No | Temperature. |
| `vitals.blood_pressure` | string | No | Blood pressure. |
| `vitals.heart_rate` | string | No | Heart rate. |
| `vitals.respiratory_rate` | string | No | Respiratory rate. |
| `vitals.blood_sugar` | string | No | Blood glucose. |
| `meta.sent_at` | string | No | Client timestamp. |

**Example**
```json
{
  "patient_id": "PT-2603-00001",
  "case_id": "CS-260306-00001",
  "status": "CREATION",
  "vitals": {
    "temperature": "Warm",
    "blood_pressure": "Normal",
    "heart_rate": "Normal",
    "respiratory_rate": "Normal",
    "blood_sugar": "Normal"
  },
  "meta": {
    "sent_at": "2026-03-06 01:22:17"
  }
}
```

Response 200
```json
{
  "status": "Case update success",
  "patient_id": "PT-2603-00001",
  "case_id": "CS-260306-00001",
  "record_id": "REC-00002"
}
```

Behavior
- Updates `case_updated_at`
- Creates a new record under `cases/{case_id}/records/{record_id}`
- Sets `current_record_id` to the new record
 - Preserve‑non‑null: if the incoming follow‑up payload has nulls, values are carried over from the latest record

Errors
- 404 if case not found
- 400 if `patient_id` does not match the case
- 500 server errors

---

`POST /send-to-doctor`

**Title:** Send to Doctor  
**Description:** Creates analysis/plan versions and updates case status for review.

Content-Type: `application/json`

**Request Body (Summary)**
| Field | Type | Required | Description |
|---|---|---|---|
| `record_id` | string | Yes | Record ID. |
| `case_id` | string | Yes | Case ID. |
| `patient_id` | string | Yes | Patient ID. |
| `status` | string | Yes | Should be `DOCTOR_REVIEW`. |
| `urgency` | string | No | `URGENT`, `MEDIUM`, or `ROUTINE`. |
| `vital_signs` | object | Yes | Vital signs object. |
| `wound_detail` | object | Yes | Wound detail object. |
| `ischemia` | object | Yes | Ischemia object. |
| `infection` | object | Yes | Infection object. |
| `neuropathy` | object | Yes | Neuropathy object. |
| `sinbad` | object | Yes | SINBAD object. |
| `lab_results` | object | Yes | Lab results object. |
| `vascular` | object | Yes | Vascular object. |

**Example**  
See the full JSON example below (same as current minimal example).

Response 200
```json
{
  "status": "success",
  "message": "Case sent for doctor review",
  "case_id": "CS-260306-00001",
  "record_id": "REC-00001",
  "analysis_id": "AN-20260306012345",
  "plan_id": "PL-20260306012345"
}
```

Errors
- 422 validation errors (missing required sections)
- 500 server errors

Notes
- Preserve-non-null: incoming null fields do not overwrite existing stored values for `vital_signs`, `wound_detail`, `ischemia`, `infection`, `neuropathy`, `sinbad`, `lab_results`, `vascular`, `gangrene_extent`, `treatment_plan`, `task_list`, `analysis`, `image`.
- The server injects `treatment_plan.plan_id` (e.g., `PL-YYYYMMDDHHMMSS`) and `treatment_plan.plan_tasks[*].task_id` into the record and `cases/{case_id}.current_treatment_plan`.




---

**Analysis**

`POST /analyze-fillin`

**Title:** Analyze Fill-In  
**Description:** Uploads a wound image, stores it in Firebase Storage, and returns a structured fill-in analysis.

Content-Type: `multipart/form-data`

**Form Fields**
| Field | Type | Required | Description |
|---|---|---|---|
| `case_id` | string | Yes | Case ID. |
| `record_id` | string | Yes | Record ID. |
| `image` | file | Yes | Wound image. |

Response 200
```json
{
  "status": "success",
  "case_id": "CS-260306-00001",
  "record_id": "REC-00001",
  "analysis": {
    "location_primary": "dorsal_aspect",
    "location_detail": "foot",
    "wound_type": "ulcer",
    "shape": "irregular",
    "size_width_cm": 3.0,
    "size_length_cm": 4.0,
    "depth_category": "full_thickness",
    "bed_slough_pct": 20,
    "bed_necrotic_pct": 10,
    "edge_description": "irregular",
    "periwound_status": "erythematous",
    "discharge_volume": "minimal",
    "discharge_type": "serosanguineous (pink)",
    "odor_presence": "faint",
    "pain_score": 4,
    "has_infection": true,
    "skin_condition": "dry"
  },
  "image_id": "CS-260306-00001-REC-00001-20260306012345.jpg",
  "image_url": "https://..."
}
```

Behavior
- Updates `records/{record_id}.image.image_folder_url`.
- If `case.current_record_id == record_id`, also updates `cases/{case_id}.current_image.image_folder_url`.

Errors
- 400 invalid image
- 500 server errors

---

`POST /analyze-healing`

**Title:** Analyze Healing Progress  
**Description:** Analyzes chronological records and images to generate a healing progress summary.

Content-Type: `application/json`

**Request Body**
| Field | Type | Required | Description |
|---|---|---|---|
| `case_id` | string | Yes | Case ID to analyze. |

**Example**
```json
{
  "case_id": "CS-260306-00001"
}
```

Response 200
```json
{
  "status": "success",
  "analysis": "- Overall trend: improving\n- Key changes: ...\n- Concerns: ...",
  "records": [
    { "record_id": "REC-00001", "status": "CREATION" }
  ]
}
```

Errors
- 400 missing `case_id`
- 404 no records for case
- 500 server errors

---

`POST /analyze-wound`

**Title:** Analyze Wound  
**Description:** Runs multi-stage AI analysis on the wound image and payload data.

Content-Type: `multipart/form-data`

**Form Fields**
| Field | Type | Required | Description |
|---|---|---|---|
| `payload_data` | string | Yes | JSON string used by the prompt. |
| `image` | file | Yes | Wound image. |

**`payload_data` Schema**
| Field | Type | Required | Description |
|---|---|---|---|
| `patient_profile` | object | No | Patient profile snapshot. |
| `nurse_reviewed.nurse_reviewed_flag` | boolean | No | Nurse reviewed flag. |
| `nurse_reviewed.vital_signs` | object | No | Vital signs. |
| `nurse_reviewed.wound_detail` | object | No | Wound details. |
| `nurse_reviewed.ischemia` | object | No | Ischemia assessment. |
| `nurse_reviewed.infection` | object | No | Infection assessment. |
| `nurse_reviewed.neuropathy` | object | No | Neuropathy assessment. |
| `nurse_reviewed.sinbad` | object | No | SINBAD fields. |
| `nurse_reviewed.lab_results` | object | No | Lab results. |
| `nurse_reviewed.vascular` | object | No | Vascular tests. |
| `nurse_reviewed.gangrene_extent` | string | No | Gangrene extent. |
| `ai_prefill` | object | No | AI prefill data. |
| `case_ref.patient_id` | string | Yes | Patient ID. |
| `case_ref.case_id` | string | Yes | Case ID. |
| `case_ref.record_id` | string | Yes | Record ID. |

**Example `payload_data`**
```json
{
  "patient_profile": {
    "patient_id": "PT-2603-00001",
    "patient_name": "John Doe",
    "nrc_id": "8757446557345",
    "phone_no": "0812345678",
    "dob": "1990-01-01",
    "gender": "Male",
    "height_cm": 170,
    "weight_kg": 65,
    "medical_history": "DM",
    "diabetes": { "has_diabetes": "yes", "years": "5", "risk_history": [], "complications": [] }
  },
  "nurse_reviewed": {
    "nurse_reviewed_flag": true,
    "vital_signs": {
      "temperature": "Warm",
      "blood_pressure": "Normal",
      "blood_glucose": "Normal",
      "heart_rate": "Normal",
      "respiratory_rate": "Normal"
    },
    "wound_detail": {
      "location_primary": "dorsal_aspect",
      "location_detail": "foot",
      "wound_type": "ulcer",
      "shape": "irregular",
      "size": { "width_cm": 3.0, "length_cm": 4.0 },
      "depth_category": "full_thickness",
      "bed": { "slough_pct": 20, "necrotic_pct": 10 },
      "edge_description": "irregular",
      "periwound_status": "erythematous",
      "discharge": { "volume": "minimal", "type": "serosanguineous (pink)" },
      "odor_presence": "faint",
      "pain_score": 4,
      "has_infection": true,
      "skin_condition": "dry"
    },
    "ischemia": { "points": [0, 1], "pulse": "yes", "checklist": ["Cold foot"] },
    "infection": { "checklist": ["Warmth"], "erythema_extent": "gt_2_cm", "probe_to_bone_test": "negative", "has_deep_abscess_or_fasciitis": "no" },
    "neuropathy": { "points": [0, 1, 3, 4] },
    "sinbad": { "site": "Forefoot", "ischemia": "Yes", "neuropathy": "Yes", "infection": "Yes", "area": ">= 1 cm²", "depth": "Skin only" },
    "lab_results": { "wbc_count": "6500", "crp": "5", "esr": "30", "procalcitonin": "0.3" },
    "vascular": { "abi_value": "0.9", "ankle_pressure_mmHg": "70", "toe_pressure_mmHg": "45", "tcpo2_mmHg": "30" },
    "gangrene_extent": "digits_only"
  },
  "ai_prefill": {
    "analysis": {
      "creator": "Gemini AI",
      "diagnosis": "Moderate infected neuropathic ulcer",
      "description": "Full-thickness ulcer with erythema and discharge.",
      "confidence": 0.85,
      "red_flag": true
    }
  },
  "case_ref": { "patient_id": "PT-2603-00001", "case_id": "CS-260306-00001", "record_id": "REC-00001" }
}
```

Response 200
```json
{"status":"success","analysis":"..."}
```

Errors
- 500 server errors

---

**Tasks**

`POST /tasks_list`

**Title:** List Current Tasks  
**Description:** Returns all current tasks from cases, with patient name and current treatment plan.

Content-Type: `application/json`

**Request Body**
| Field | Type | Required | Description |
|---|---|---|---|
| `limit` | integer | No | Max number of cases to scan (default 200, max 500). |

Response 200
```json
{
  "status": "success",
  "tasks": [
    {
      "case_id": "CS-260314-00002",
      "patient_id": "PT-2603-00004",
      "patient_name": "Patient A",
      "current_record_id": "REC-00001",
      "current_plan_id": "PL-20260314163734",
      "current_treatment": {
        "followup_days": 7,
        "plan_text": "Wound care, dressing care, offloading...",
        "status": "DRAFT",
        "plan_tasks": [
          { "task_text": "Wound care and dressing changes", "status": "DRAFT", "task_due": null, "task_photo_url": "https://..." }
        ]
      }
    }
  ]
}
```

Errors
- 500 server errors

---

`POST /task_detail`

**Title:** Task Detail  
**Description:** Returns current treatment plan and tasks for a case, with optional task selection by index.

Content-Type: `application/json`

**Request Body**
| Field | Type | Required | Description |
|---|---|---|---|
| `case_id` | string | Yes | Case ID to load tasks from. |
| `task_index` | integer | No | Zero‑based index in `plan_tasks` to return a single task. |

**Example**
```json
{
  "case_id": "CS-260314-00002",
  "task_index": 0
}
```

Response 200
```json
{
  "status": "success",
  "case_id": "CS-260314-00002",
  "patient_id": "PT-2603-00004",
  "patient_name": "Patient A",
  "current_treatment": {
    "followup_days": 7,
    "plan_text": "Wound care, dressing care, offloading...",
    "status": "DRAFT",
    "plan_tasks": [
      { "task_text": "Wound care and dressing changes", "status": "DRAFT", "task_due": null, "task_photo_url": "https://..." }
    ]
  },
  "plan_tasks": [
    { "task_text": "Wound care and dressing changes", "status": "DRAFT", "task_due": null, "task_photo_url": "https://..." }
  ]
}
```

Errors
- 400 missing/invalid `case_id` or `task_index`
- 404 case not found / task_index out of range
- 500 server errors

---

`POST /task_update`

**Title:** Update Active Task  
**Description:** Updates tasks inside `cases/{case_id}.current_treatment_plan.plan_tasks` and the active plan version tasks.

Content-Type: `multipart/form-data`

**Form Fields**
| Field | Type | Required | Description |
|---|---|---|---|
| `case_id` | string | Yes | Case ID containing the active plan. |
| `plan_id` | string | No | Current plan ID (validated if provided). |
| `updates` | string | Yes | JSON string list of task updates. |
| `images` | file[] | No | Task photo files; if provided, count must match `updates` list length (index-matched). |

**`updates` Fields**
| Field | Type | Required | Description |
|---|---|---|---|
| `status` | string | No | Task status. |
| `task_due` | string | No | Due date. |
| `completed_at` | string | No | Completion timestamp. |
| `task_photo_url` | string | No | Photo URL for the task (set automatically if `image` is provided). |
| `task_text` | string | No | Task text. |

**Example `updates`**
```json
[
  {
    "task_id": "TSK-0001",
    "updates": {
      "status": "COMPLETED",
      "completed_at": "2026-03-17T10:00:00Z"
    }
  },
  {
    "task_id": "TSK-0002",
    "updates": {
      "status": "IN_PROGRESS",
      "task_due": "2026-03-20"
    }
  }
]
```

Response 200
```json
{
  "status": "success",
  "case_id": "CS-260314-00002",
  "plan_id": "PL-20260314163734",
  "updated_task_ids": ["TSK-0001", "TSK-0002"]
}
```

Errors
- 400 missing/invalid `case_id` or `updates`, or image count mismatch
- 404 case not found / task_id not found in current plan / current plan version missing
- 500 server errors

---

**Firestore Data Model (Current)**

```
patients
  └── {patient_id}
       patient_name
       phone_no
       dob
       gender
       ...

cases
  └── {case_id}
       patient_id
       created_by_nurse
       assigned_doctor
       status
       urgency
       case_created_at
       case_updated_at

       current_record_id
       current_analysis_id
       current_plan_id

       records
         └── {record_id}
              record_created_by
              record_created_at
              record_updated_at

              timestamps
              image
              vital_signs
              wound_detail
              ischemia
              infection
              neuropathy
              sinbad
              lab_results
              vascular
              gangrene_extent

              analysis_versions
                └── {analysis_id}

              plan_versions
                └── {plan_id}
                     tasks
                       └── {task_id}
                            completed_at
```

---

**Workflow: Create Case (Typical Sequence)**

1. **Patient Search**  
   Call: `GET /patients_list`  
   Input: none  
   Output: `{ status, patients: [...] }`  
   Creates/Updates: none (read-only).

2. **Ensure Patient Profile**  
   If patient exists:  
   Call: `PATCH /patients/{patient_id}`  
   Input: patient profile JSON (from intake)  
   Output: updated patient record  
   Creates/Updates: updates `patients/{patient_id}` for non-null fields, casts `height_cm`/`weight_kg` to float, sets `synced_at = server timestamp`.

   If patient does not exist:  
   Call: `POST /create-patient-profile`  
   Input: multipart form (`patient_data` + optional `image`)  
   Output: `{ status, patient_id, photo_url, message }`  
   Creates/Updates: increments `metadata/counters_{yyMM}.last_running_num`; creates `patients/{patient_id}` with `nrc_id`, `patient_name`, `phone_no`, `dob`, `gender`, `height_cm`, `weight_kg`, `medical_history`, `diabetes`, `status`, `created_at`, `synced_at`, `photo_url`; optional image uploaded to Storage at `patients/{patient_id}/profile/profile_photo.jpg` and `photo_url` set.

3. **Create Case**  
   Call: `POST /create-case`  
   Input: `{ patient_id, status, vitals, meta }`  
   Output: `{ status, case_id, record_id, patient_id }`  
   Creates/Updates: increments `metadata/counters_case_{yyMMdd}.last_running_num`; creates `cases/{case_id}` with `case_id`, `patient_id`, `created_by_nurse`, `assigned_doctor`, `status`, `urgency`, `case_created_at`, `case_updated_at`, `current_record_id`, `current_analysis_id=null`, `current_plan_id=null`, plus current snapshot fields `current_timestamps`, `current_image`, `current_vital_signs`, `current_wound_detail`, `current_ischemia`, `current_infection`, `current_neuropathy`, `current_sinbad`, `current_lab_results`, `current_vascular`, `current_analysis`, `current_treatment_plan`; creates `cases/{case_id}/records/{record_id}` with `record_id`, `case_id`, `patient_id`, `record_created_by`, `record_created_at`, `record_updated_at`, `created_by_nurse`, `assigned_doctor`, `status`, `urgency`, `timestamps`, `image`, `vital_signs`, `wound_detail`, `ischemia`, `infection`, `neuropathy`, `sinbad`, `lab_results`, `vascular`, `gangrene_extent`, `analysis`, `treatment_plan`, `task_list`.

4. **Wound Photo Analyze (Fill-in)**  
   Call: `POST /analyze-fillin`  
   Input: multipart form: `case_id`, `record_id`, `image`  
   Output: `{ status, analysis, image_id, image_url, ... }`  
   Creates/Updates: uploads image to Storage at `cases/{case_id}/{record_id}/{image_id}`; updates `records/{record_id}.image.image_folder_url` and `record_updated_at`; if `case.current_record_id == record_id`, updates `cases/{case_id}.current_image.image_folder_url` and `case_updated_at`.

5. **Wound Assessment**  
   Call: `POST /analyze-wound`  
   Input: multipart form: `payload_data` (JSON string with patient_profile + nurse_reviewed), `image`  
   Output: `{ status, analysis }`  
   Creates/Updates (before AI call): updates `records/{record_id}` with `patient_id`, `status=ANALYZING`, `vital_signs`, `wound_detail`, `ischemia`, `infection`, `neuropathy`, `sinbad`, `lab_results`, `vascular`, `gangrene_extent`, `record_updated_at`; updates `cases/{case_id}` with `patient_id`, `status=ANALYZING`, `case_updated_at`, `current_record_id`, `current_vital_signs`, `current_wound_detail`, `current_ischemia`, `current_infection`, `current_neuropathy`, `current_sinbad`, `current_lab_results`, `current_vascular`, `current_gangrene_extent`.

6. **Send To Doctor**  
   Call: `POST /send-to-doctor`  
   Input: `{ record_id, case_id, patient_id, status, ... }`  
   Output: `{ status, case_id, record_id, analysis_id, plan_id }`  
   Creates/Updates: merges `records/{record_id}` with incoming data for `vital_signs`, `wound_detail`, `ischemia`, `infection`, `neuropathy`, `sinbad`, `lab_results`, `vascular`, `gangrene_extent`, `treatment_plan`, `task_list`, `analysis`, `image` (preserve-non-null; if incoming `vital_signs` is all null, it keeps existing `vital_signs`); sets `records/{record_id}.timestamps.updated_at` and `timestamps.analyze_at` to server timestamp and sets `record_updated_at`; injects `treatment_plan.plan_id` and `treatment_plan.plan_tasks[*].task_id` plus `completed_at`; creates `records/{record_id}/analysis_versions/{analysis_id}` with `payload`, `status`, `source`, `created_at`; creates `records/{record_id}/plan_versions/{plan_id}` with `plan_text`, `followup_days`, `status`, `created_at`; creates `records/{record_id}/plan_versions/{plan_id}/tasks/{task_id}` for each task with `task_text`, `status`, `task_due`, `completed_at`, `created_at`; updates `cases/{case_id}` with `status=DOCTOR_REVIEW`, `urgency`, `case_updated_at`, `current_record_id`, `current_analysis_id`, `current_plan_id`, and current snapshot fields.

**Total create‑case calls (typical path):** 6  
If you skip photo or exit early, fewer calls happen.

---

**Workflow: Follow-Up Flow (Typical Sequence)**

1. **Patient Search**  
   Call: `GET /patients_list`  
   Input: none  
   Output: `{ status, patients: [...] }`  
   Creates/Updates: none (read-only).

2. **Update Patient Profile**  
   Call: `PATCH /patients/{patient_id}`  
   Input: patient profile JSON (from intake)  
   Output: updated patient record  
   Creates/Updates: updates `patients/{patient_id}` for non-null fields, sets `synced_at`.

3. **Load Patient Cases**  
   Call: `POST /cases_list`  
   Input: `{ "limit": 50, "patient_id": "<patient_id>" }`  
   Output: `{ status, cases: [...] }`  
   Creates/Updates: none (read-only).

4. **Select Case → Vital Check**  
   Call: `POST /update_cases`  
   Input: `{ patient_id, case_id, status, vitals, meta }`  
   Output: `{ status, case_id, record_id, patient_id }`  
   Creates/Updates: creates `cases/{case_id}/records/{record_id}` with merged snapshot from latest record; merged fields are `vital_signs`, `wound_detail`, `ischemia`, `infection`, `neuropathy`, `sinbad`, `lab_results`, `vascular`, `gangrene_extent`, `treatment_plan`, `task_list`, `analysis` (preserve-non-null; if incoming `vital_signs` is all null, it keeps the latest `vital_signs`); duplicates latest `treatment_plan` into the new record with a new `plan_id` when a previous plan exists; creates `records/{record_id}/plan_versions/{plan_id}` and `plan_versions/{plan_id}/tasks/{task_id}` using copied fields (status, plan_text, followup_days, task_text, status, task_due, completed_at, task_photo_url); updates `cases/{case_id}` with `status`, `urgency`, `case_updated_at`, `current_record_id`, `current_analysis_id=null`, `current_plan_id=new_plan_id`, and current snapshot fields.

5. **Wound Photo Analyze (Fill-in)**  
   Call: `POST /analyze-fillin`  
   Input: multipart form: `case_id`, `record_id`, `image`  
   Output: `{ status, analysis, image_id, image_url, ... }`  
   Creates/Updates: same as Create Case step 4.

6. **Wound Assessment**  
   Call: `POST /analyze-wound`  
   Input: multipart form: `payload_data` (JSON string with patient_profile + nurse_reviewed), `image`  
   Output: `{ status, analysis }`  
   Creates/Updates: same as Create Case step 5.

7. **Healing Summary (follow-up only)**  
   Call: `POST /analyze-healing`  
   Input: `{ "case_id": "<case_id>" }`  
   Output: `{ status, analysis, records }`  
   Creates/Updates: updates latest `records/{record_id}.healing_progress` and `cases/{case_id}.current_healing_progress`.

**Total follow‑up calls (typical path):** 7  
If you skip photo or exit early, fewer calls happen.

---

**Workflow Flowchart**

Create Case
```mermaid
flowchart TD
  A[GET /patients_list] --> B{Patient exists?}
  B -->|Yes| B2["PATCH /patients/{patient_id}"]
  B -->|No| B3[POST /create-patient-profile]
  B2 --> C[POST /create-case]
  B3 --> C
  C --> D[POST /analyze-fillin]
  D --> E[POST /analyze-wound]
  E --> F[POST /send-to-doctor]
  F --> G(Finish create case)
```

Follow-Up Case
```mermaid
flowchart TD
  A[GET /patients_list] --> B["PATCH /patients/{patient_id}"]
  B --> C[POST /cases_list]
  C --> D[POST /update_cases]
  D --> E[POST /analyze-fillin]
  E --> F[POST /analyze-wound]
  F --> G[POST /analyze-healing]
  G --> H(Finish follow up case)
```

Task Execution
```mermaid
flowchart TD
  A[POST /tasks_list] --> B[POST /task_detail]
  B --> C[POST /task_update]
  C --> D(Finish task updates)
```

---

**Endpoint Payloads And Database Updates**

| Endpoint | Payload Fields | Database Updates |
|---|---|---|
| `POST /load-dashboard` | none | none |
| `GET /patients_list` | none (query param `limit`) | none |
| `POST /create-patient-profile` | `patient_data` (JSON string), optional `image` file | Writes `patients/{patient_id}`; increments `metadata/counters_{yyMM}`; uploads image to Storage if provided |
| `PATCH /patients/{patient_id}` | Partial patient fields (JSON) | Updates `patients/{patient_id}`; sets `synced_at` |
| `POST /cases_list` | `patient_id` (optional), `limit` (optional) | none |
| `POST /case_detail` | `case_id` | none |
| `POST /create-case` | `patient_id`, `status`, `urgency`, `created_by_nurse`, `assigned_doctor`, `vitals`, `meta` | Writes `cases/{case_id}` and `cases/{case_id}/records/{record_id}`; increments `metadata/counters_case_{yyMMdd}` |
| `POST /update_cases` | `case_id`, `patient_id`, `status`, `urgency`, `created_by_nurse`, `assigned_doctor`, `vitals`, `meta` | Updates `cases/{case_id}` current fields; creates new `records/{record_id}` |
| `POST /send-to-doctor` | `record_id`, `case_id`, `patient_id`, `status`, `urgency`, `vital_signs`, `wound_detail`, `ischemia`, `infection`, `neuropathy`, `sinbad`, `lab_results`, `vascular`, `gangrene_extent`, `analysis`, `treatment_plan`, `task_list`, optional `timestamps`, `image` | Updates `cases/{case_id}` current fields; merges `records/{record_id}`; creates `analysis_versions/{analysis_id}`, `plan_versions/{plan_id}`, and `plan_versions/{plan_id}/tasks/{task_id}` |
| `POST /analyze-fillin` | `case_id`, `record_id`, `image` file | Uploads image to Storage; updates `records/{record_id}.image.image_folder_url` |
| `POST /analyze-healing` | `case_id` | Writes `records/{latest_record_id}.healing_progress` and `cases/{case_id}.current_healing_progress` |
| `POST /analyze-wound` | `payload_data` (JSON string), `image` file | Updates `records/{record_id}` with `nurse_reviewed` fields and `status=ANALYZING`; updates `cases/{case_id}` current fields and `status=ANALYZING` |
| `POST /tasks_list` | `limit` (optional) | none |
| `POST /task_detail` | `case_id`, `task_index` (optional) | none |
| `POST /task_update` | `case_id`, `plan_id?`, `updates`, `images?` | Updates `cases/{case_id}.current_treatment_plan.plan_tasks` and active plan version tasks |

---

**Observed Standards Gaps And Missing Items**

Compared with a typical production-ready API specification template, the current `API.md` still lacks:

- No versioning strategy (e.g., `/v1` or version header).
- No authentication/authorization model specified.
- No standard error schema with machine-readable codes and examples.
- No endpoint-by-endpoint response schemas (only examples).
- Field constraints incomplete (enums, ranges, nullable, defaults).
- Date/time formats not standardized across examples.
- No pagination contract beyond `limit` (no cursor/offset/total).
- No idempotency guidance for create/update endpoints.
- No concurrency/conflict behavior documented for PATCH or follow-ups.
- No rate limiting/timeout/retry/size limits (esp. image uploads & AI).
- No media requirements for uploads (type, size, resolution).
- No environment definitions (local/staging/prod base URLs).
- No status/state machine definition (CREATION, DOCTOR_REVIEW, URGENT, etc.).
- No data retention, audit logging, PHI/PII handling, privacy or security notes.
- No webhook/async job behavior for AI analysis endpoints.
- No non‑200 error response examples (400/404/422/500).
- `send-to-doctor` references a full JSON example, but it is not explicitly repeated as a full schema.
- No rules for case sensitivity, unknown fields, or partial object merge vs replace.

---

**Recommended Next Improvements**

- Convert to OpenAPI 3.1 with schemas, enums, validation rules, and examples.
- Define a shared error model and include example bodies for common errors.
- Standardize all timestamps to ISO 8601 with timezone.
- Add authentication, security, and privacy sections before external publication.
- Add complete schemas for core objects: patient profile, case, record, analysis version, plan version.

---

**Plan & Record State Guidance**

Best‑practice rules for plans and records:
- A plan is always tied to a specific record (`record_id + plan_id`).
- The case points to the active plan via `current_record_id` and `current_plan_id`.
- Use plan statuses to track lifecycle: `DRAFT`, `ACTIVE`, `COMPLETED`, `CANCELLED`, `SUPERSEDED`.
- Do not move a plan to a different record. If a new record is created, create a new plan version (even if content is identical).

Common transitions:
1. **Activate same plan (Record A / Plan A)**  
   - Update plan status `DRAFT` → `ACTIVE`.  
   - No record change, no new plan version.

2. **Plan change only (Record A / Plan B)**  
   - Create new plan version under Record A.  
   - Set `current_plan_id = Plan B`.  
   - Mark Plan A as `SUPERSEDED` or `CANCELLED` (optional).

3. **Record + plan change (Record B / Plan B)**  
   - Create Record B.  
   - Create Plan B under Record B.  
   - Set `current_record_id = Record B`, `current_plan_id = Plan B`.

4. **Record change only**  
   - Recommended: create a new plan version under Record B (even if duplicate).  
   - Avoid reusing a plan from Record A to keep audit history clean.

---

**Task Execution Workflow**

Typical task execution flow (active plan only):
1. **Load tasks**  
   Call: `POST /tasks_list`  
   Input: `{ "limit": 200 }`  
   Output: `{ status, tasks: [...] }`  
   Notes: Each item includes `case_id`, `current_record_id`, `current_plan_id`, and `current_treatment.plan_tasks`.

2. **View task detail (optional)**  
   Call: `POST /task_detail`  
   Input: `{ "case_id": "<case_id>", "task_index": 0 }`  
   Output: `{ status, case_id, current_treatment, plan_tasks }` or `{ status, case_id, current_treatment, task }`

3. **Update task status / due / completion / photo**  
   Call: `POST /task_update` (multipart)  
   Form fields: `case_id`, `plan_id` (optional but recommended; must match current plan if provided), `updates` (JSON list of `{ task_id, updates }`), `images` (optional, one file per update, index-matched).  
   Output: `{ status, case_id, plan_id, updated_task_ids }`  
   Creates/Updates: updates `cases/{case_id}.current_treatment_plan.plan_tasks` and `case_updated_at`; updates `records/{current_record_id}/plan_versions/{current_plan_id}/tasks/{task_id}` with `updated_at`; if images are provided, uploads to Storage at `cases/{case_id}/tasks/{task_id}/{filename}` and sets `task_photo_url`.

**Task Workflow API Specs (Quick Reference)**
| Step | Endpoint | Input | Output |
|---|---|---|---|
| Load tasks | `POST /tasks_list` | `{ "limit": 200 }` | `{ status, tasks: [...] }` |
| Task detail | `POST /task_detail` | `{ "case_id": "...", "task_index": 0 }` | `{ status, case_id, current_treatment, plan_tasks }` or `{ status, case_id, current_treatment, task }` |
| Update tasks | `POST /task_update` | `case_id`, `plan_id?`, `updates`, `images?` | Updates `cases/{case_id}.current_treatment_plan.plan_tasks` and active plan version tasks |


