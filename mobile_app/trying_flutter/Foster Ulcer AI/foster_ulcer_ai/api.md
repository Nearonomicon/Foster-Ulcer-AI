# API Trigger Map (App → Backend)

This document lists when each API is triggered, the payload sent, and the expected response shape.

## Base URL
- `https://foster-ulcer-ai-backend-429230748709.asia-southeast3.run.app`

---

## Patients

### GET `/patients_list`
**Triggered**
- Every time `patient_search_page` opens.

**Request**
- No body.

**Response (example)**
```json
{
  "status": "success",
  "patients": [
    {
      "patient_id": "PT-2603-00001",
      "patient_name": "John Doe",
      "phone_no": "0812345678",
      "dob": "1990-01-01",
      "gender": "Male",
      "height_cm": 170,
      "weight_kg": 65,
      "medical_history": "DM",
      "diabetes": { "has_diabetes": "yes", "years": "5", "risk_history": [], "complications": [] },
      "status": "Active",
      "created_at": "2026-03-06",
      "synced_at": "2026-03-06T01:22:17Z",
      "photo_url": "https://..."
    }
  ]
}
```

### POST `/create-patient-profile`
**Triggered**
- Intake page when registering a **new** patient.

**Request (multipart/form-data)**
- `patient_data` (JSON string)
- `image` (optional file)

**Response**
- `status: success` with created patient data.

### PATCH `/patients/{patient_id}`
**Triggered**
- Intake page when **follow-up flow** is true and patient is selected (profile update).

**Request (JSON)**
- Same fields as intake form (no image in JSON).

**Response**
- `status: success` and updated patient record.

---

## Cases

### POST `/cases_list`
**Triggered**
- Cases tab opens (no patient filter).
- Follow‑up flow: after intake update, to list cases for selected patient.

**Request (JSON)**
```json
{
  "limit": 50,
  "patient_id": "PT-xxxx-xxxxx" // optional
}
```

**Response (example)**
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

### POST `/case_detail`
**Triggered**
- Tapping a case in Cases tab (before navigating to Case Detail page).

**Request (JSON)**
```json
{ "case_id": "CS-260312-00002" }
```

**Response**
```json
{
  "status": "success",
  "case": { ... },
  "records": [ ... ],
  "patient_profile": { ... }
}
```

### POST `/create-case`
**Triggered**
- Vital Check → “Wound is present / not present” (Create Case flow).

**Request (JSON)**
```json
{
  "patient_id": "PT-xxxx-xxxxx",
  "status": "CREATION",
  "vitals": {
    "temperature": "...",
    "blood_pressure": "...",
    "heart_rate": "...",
    "respiratory_rate": "...",
    "blood_sugar": "..."
  },
  "meta": { "sent_at": "YYYY-MM-DD HH:MM:SS" }
}
```

**Response**
```json
{
  "status": "success",
  "patient_id": "...",
  "case_id": "...",
  "record_id": "..."
}
```

### POST `/update_cases`
**Triggered**
- Vital Check in **follow‑up flow**.

**Request (JSON)**
```json
{
  "patient_id": "PT-xxxx-xxxxx",
  "case_id": "CS-xxxx-xxxxx",
  "status": "CREATION",
  "vitals": {
    "temperature": "...",
    "blood_pressure": "...",
    "heart_rate": "...",
    "respiratory_rate": "...",
    "blood_sugar": "..."
  },
  "meta": { "sent_at": "YYYY-MM-DD HH:MM:SS" }
}
```

**Response**
```json
{
  "status": "Case update success",
  "patient_id": "...",
  "case_id": "...",
  "record_id": "..."
}
```

---

## Analyze

### POST `/analyze-fillin`
**Triggered**
- After photo capture (camera), to extract structured fields from image.

**Request (multipart/form-data)**
- `case_id`
- `record_id`
- `image` (file)

**Response**
```json
{
  "status": "success",
  "case_id": "...",
  "record_id": "...",
  "analysis": { ... },
  "image_id": "...",
  "image_url": "https://storage.googleapis.com/..."
}
```

### POST `/analyze-wound`
**Triggered**
- Wound assessment → Submit Assessment (both create-case and follow-up).

**Request (multipart/form-data)**
- `payload_data` (JSON string)
- `image` (file)

**payload_data schema (simplified)**
```json
{
  "patient_profile": { ... },
  "nurse_reviewed": {
    "nurse_reviewed_flag": false,
    "vital_signs": { ... },
    "wound_detail": { ... },
    "ischemia": { ... },
    "infection": { ... },
    "neuropathy": { ... },
    "sinbad": { ... },
    "lab_results": { ... },
    "vascular": { ... },
    "gangrene_extent": null
  },
  "ai_prefill": { ... },     // optional
  "case_ref": { ... }        // optional
}
```

**Response**
```json
{ "status": "success", "analysis": "{...json string...}" }
```

### POST `/analyze-healing`
**Triggered**
- Follow‑up flow only, after `/analyze-wound` success.

**Request (JSON)**
```json
{ "case_id": "CS-xxxx-xxxxx" }
```

**Response**
```json
{
  "status": "success",
  "analysis": "plain text summary",
  "records": [ ... ]
}
```

---

## Send To Doctor

### POST `/send-to-doctor`
**Triggered**
- Doctor summary page → Send to doctor.

**Request (JSON)**
```json
{
  "record_id": "...",
  "case_id": "...",
  "patient_id": "...",
  "status": "DOCTOR_REVIEW",
  "urgency": "URGENT|MEDIUM|ROUTINE",
  "vital_signs": { ... },
  "wound_detail": { ... },
  "ischemia": { ... },
  "infection": { ... },
  "neuropathy": { ... },
  "sinbad": { ... },
  "lab_results": { ... },
  "vascular": { ... },
  "gangrene_extent": null,
  "analysis": { ... },
  "treatment_plan": { ... },
  "task_list": [ ... ]
}
```

**Response**
```json
{ "status": "success", ... }
```

---

## Notes
- `vital_signs` are populated in `vital_check_page` and stored in `_reviewed`.
- `payload_data` in `/analyze-wound` is sent as a JSON string inside multipart form.
