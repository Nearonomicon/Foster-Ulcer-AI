# Wound Care AI API

Base URL: `http://127.0.0.1:8000`

All endpoints are unauthenticated by default. CORS allows `*`.

---

**Health**

`POST /load-dashboard`

Response 200
```json
{"message":"CORS is working!"}
```

---

**Patients**

`POST /create-patient-profile`

Content-Type: `multipart/form-data`

Form fields
- `patient_data` (string, required): JSON string that matches `PatientSchema`.
- `image` (file, optional): patient profile photo.

`patient_data` schema
```json
{
  "patient_name": "John Doe",
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

**Cases**

`POST /create-case`

Content-Type: `application/json`

Request body
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
    "repiratory_rate": "Normal",
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

Errors
- 500 server errors (see terminal for traceback)

Notes
- If `urgency` is omitted, it is stored as `null`.

---

`POST /send-to-doctor`

Content-Type: `application/json`

Request body
- Uses `WoundCaseRecordUpdate` schema.
- Required (non-null) sections:
  `vital_signs`, `wound_detail`, `ischemia`, `infection`,
  `neuropathy`, `sinbad`, `lab_results`, `vascular`.

Minimal example (fields inside sections are illustrative)
```json
{
  "record_id": "REC-00001",
  "case_id": "CS-260306-00001",
  "patient_id": "PT-2603-00001",
  "record_created_by": "NUR-0001",
  "record_created_at": "2026-03-06T01:22:17Z",
  "record_updated_at": "2026-03-06T01:22:17Z",
  "created_by_nurse": "NUR-0001",
  "assigned_doctor": "DR-0001",
  "status": "DOCTOR_REVIEW",
  "urgency": "MEDIUM",
  "timestamps": {
    "created_at": "2026-03-06T01:22:17Z",
    "updated_at": "2026-03-06T01:22:17Z",
    "analyze_at": null,
    "doctor_review_at": null,
    "plan_issued_at": null,
    "treatment_active_at": null,
    "appointment_at": null,
    "completed_at": null
  },
  "image": {
    "image_folder_url": null
  },
  "vital_signs": {
    "temperature": "Warm",
    "blood_pressure": "Normal",
    "blood_glucose": "Normal",
    "heart_rate": "Normal",
    "respiratory_rate": "Normal"
  },
  "wound_detail": {
    "location_primary": "foot",
    "size": { "width_cm": 2.0, "length_cm": 3.0 },
    "bed": { "slough_pct": 10, "necrotic_pct": 0 },
    "discharge": { "volume": "low", "type": "serous" }
  },
  "ischemia": { "pulse": "weak", "points": [], "checklist": [] },
  "infection": {
    "erythema_extent": "mild",
    "probe_to_bone_test": "negative",
    "has_deep_abscess_or_fasciitis": "no",
    "checklist": []
  },
  "neuropathy": { "points": [] },
  "sinbad": { "site": "forefoot" },
  "lab_results": { "wbc_count": "normal" },
  "vascular": { "abi_value": "1.0" },
  "analysis": {},
  "treatment_plan": {
    "status": "DRAFT",
    "plan_text": "Clean and dress daily",
    "followup_days": 7,
    "plan_tasks": [
      { "task_text": "Change dressing", "status": "PENDING", "task_due": "2026-03-10" }
    ]
  },
  "task_list": []
}
```

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

---

**Analysis**

`POST /analyze-fillin`

Content-Type: `multipart/form-data`

Form fields
- `case_id` (string, required)
- `record_id` (string, required)
- `image` (file, required)

Response 200
```json
{
  "status": "success",
  "case_id": "CS-260306-00001",
  "record_id": "REC-00001",
  "analysis": {},
  "image_id": "CS-260306-00001-REC-00001-20260306012345.jpg",
  "image_url": "https://..."
}
```

Errors
- 400 invalid image
- 500 server errors

---

`POST /analyze-wound`

Content-Type: `multipart/form-data`

Form fields
- `patient_data` (string, required): JSON string used by the prompt.
- `image` (file, required)

Response 200
```json
{"status":"success","analysis":"..."}
```

Errors
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
```
