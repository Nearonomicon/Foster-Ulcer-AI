# API Trigger Map (App -> Backend)

This document is based on the actual API calls in `lib/widgets/main_navigation_screen.dart` and the fields consumed by the UI.

## Summary

- Base URL: `https://foster-ulcer-ai-backend-429230748709.asia-southeast3.run.app`
- Actual endpoints called by the app: `14`
- Configured but currently unused: `1`
  - `GET /docs`

## Endpoint Inventory

| # | Method | Path | Used |
|---|---|---|---|
| 1 | `GET` | `/patients_list` | Yes |
| 2 | `POST` | `/create-patient-profile` | Yes |
| 3 | `PATCH` | `/patients/{patient_id}` | Yes |
| 4 | `POST` | `/create-case` | Yes |
| 5 | `POST` | `/update_cases` | Yes |
| 6 | `POST` | `/analyze-fillin` | Yes |
| 7 | `POST` | `/analyze-wound` | Yes |
| 8 | `POST` | `/analyze-healing` | Yes |
| 9 | `POST` | `/send-to-doctor` | Yes |
| 10 | `POST` | `/cases_list` | Yes |
| 11 | `POST` | `/case_detail` | Yes |
| 12 | `POST` | `/tasks_list` | Yes |
| 13 | `POST` | `/task_detail` | Yes |
| 14 | `POST` | `/task_update` | Yes |
| 15 | `GET` | `/docs` | No |

## General Notes

- Most JSON requests use `Content-Type: application/json`.
- Multipart endpoints use `http.MultipartRequest`.
- Some values are sent as strings even when they look numeric because they come from text inputs.
- Several endpoints accept multiple response shapes; those are noted below.

---

## 1. GET `/patients_list`

**Triggered**
- When `patient_search_page` opens or refreshes.

**Request**
- No body.

**Expected response shape used by app**

The app accepts either:
- a bare JSON array of patient objects, or
- an object containing `patients: []`

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
      "height_cm": 170,
      "weight_kg": 65,
      "medical_history": "DM, HTN",
      "diabetes": {
        "has_diabetes": "yes",
        "years": "5",
        "risk_history": [],
        "complications": []
      },
      "status": "Active",
      "photo_url": "https://...",
      "patient_photo_url": "https://...",
      "patient_photo": "https://..."
    }
  ]
}
```

**Fields actually read by UI**
- `patient_id`
- `patient_name`
- `nrc_id`
- `phone_no`
- `dob`
- `gender`
- `height_cm`
- `weight_kg`
- `medical_history`
- `diabetes.has_diabetes`
- `diabetes.years`
- `diabetes.risk_history`
- `diabetes.complications`
- `status`
- `photo_url` or `patient_photo_url` or `patient_photo`

---

## 2. POST `/create-patient-profile`

**Triggered**
- Intake page when creating a new patient.

**Request content type**
- `multipart/form-data`

**Multipart fields**
- `patient_data`: JSON string
- `image`: optional file

**Outgoing `patient_data` JSON**

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
    "risk_history": ["Smoking"],
    "complications": ["Neuropathy"]
  },
  "created_at": "2026-03-22 22:15:33"
}
```

**Expected response shape used by app**

The app requires:
- `status == "success"`
- either `patient_id` or `id`

```json
{
  "status": "success",
  "patient_id": "PT-2603-00002"
}
```

**Notes**
- The app does not parse a full patient object here.
- `height_cm` and `weight_kg` are sent as strings.
- `dob` is sent in `dd/MM/yyyy` format from the form.

---

## 3. PATCH `/patients/{patient_id}`

**Triggered**
- Intake page when editing an existing patient profile.

**Request content type**
- `application/json`

**Outgoing JSON**

Same schema as `patient_data` above:

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

**Expected response shape used by app**

The app requires only:
- HTTP `200`
- `status == "success"`

```json
{
  "status": "success",
  "patient_id": "PT-2603-00002"
}
```

---

## 4. POST `/create-case`

**Triggered**
- Vital check flow for a new case.

**Request content type**
- `application/json`

**Outgoing JSON**

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

**Expected response shape used by app**

The app requires all 3 IDs:

```json
{
  "status": "success",
  "patient_id": "PT-2603-00002",
  "case_id": "CS-260322-00002",
  "record_id": "REC-00001"
}
```

---

## 5. POST `/update_cases`

**Triggered**
- Vital check flow during follow-up, when updating an existing case.

**Request content type**
- `application/json`

**Outgoing JSON**

```json
{
  "patient_id": "PT-2603-00002",
  "status": "CREATION",
  "case_id": "CS-260322-00002",
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

**Expected response shape used by app**

```json
{
  "status": "success",
  "patient_id": "PT-2603-00002",
  "case_id": "CS-260322-00002",
  "record_id": "REC-00002"
}
```

---

## 6. POST `/analyze-fillin`

**Triggered**
- After wound image capture, before manual assessment review.

**Request content type**
- `multipart/form-data`

**Multipart fields**
- `record_id`
- `case_id`
- `image`

**Outgoing payload**

```json
{
  "record_id": "REC-00001",
  "case_id": "CS-260322-00002",
  "image": "<binary file>"
}
```

**Expected response shape used by app**

The app requires `analysis`. It can be:
- a JSON object, or
- a JSON string that decodes to an object

```json
{
  "status": "success",
  "record_id": "REC-00001",
  "case_id": "CS-260322-00002",
  "analysis": {
    "location_primary": "sole",
    "location_detail": "metatarsal head",
    "wound_type": "ulcer",
    "shape": "round",
    "size_width_cm": 1.5,
    "size_length_cm": 1.5,
    "depth_category": "full_thickness",
    "bed_slough_pct": 20,
    "bed_necrotic_pct": 30,
    "edge_description": "thickened",
    "periwound_status": "erythematous",
    "discharge_volume": "minimal",
    "discharge_type": "seropurulent (cloudy yellow)",
    "skin_condition": "cracked"
  },
  "image_id": "IMG-00001",
  "image_url": "https://storage.googleapis.com/..."
}
```

**Fields copied into `_reviewed`**
- `location_primary`
- `location_detail`
- `wound_type`
- `shape`
- `size_width_cm`
- `size_length_cm`
- `depth_category`
- `bed_slough_pct`
- `bed_necrotic_pct`
- `edge_description`
- `periwound_status`
- `discharge_volume`
- `discharge_type`
- `skin_condition`

**Important**
- The app explicitly removes AI-provided `odor_presence`, `pain_score`, and `has_infection` after parsing.

---

## 7. POST `/analyze-wound`

**Triggered**
- After nurse review / wound assessment submission.

**Request content type**
- `multipart/form-data`

**Multipart fields**
- `payload_data`: JSON string
- `image`: file

**Outgoing `payload_data` JSON**

```json
{
  "patient_profile": {
    "patient_id": "PT-2603-00002",
    "nrc_id": "12/ABC(N)123456",
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
  },
  "nurse_reviewed": {
    "nurse_reviewed_flag": false,
    "vital_signs": {
      "temperature": "High",
      "blood_pressure": "Very High",
      "blood_glucose": "Very High",
      "heart_rate": "High",
      "respiratory_rate": "High"
    },
    "wound_detail": {
      "location_primary": "sole",
      "location_detail": "metatarsal head",
      "wound_type": "ulcer",
      "shape": "round",
      "size": {
        "width_cm": 1.5,
        "length_cm": 1.5
      },
      "depth_category": "full_thickness",
      "bed": {
        "slough_pct": 20,
        "necrotic_pct": 30
      },
      "edge_description": "thickened",
      "periwound_status": "erythematous",
      "discharge": {
        "volume": "minimal",
        "type": "seropurulent (cloudy yellow)"
      },
      "odor_presence": "foul",
      "pain_score": 9,
      "has_infection": true,
      "skin_condition": "cracked"
    },
    "ischemia": {
      "points": [0, 1],
      "pulse": "yes",
      "checklist": ["Cold foot"]
    },
    "infection": {
      "checklist": ["Pain", "Pus", "Swelling", "Warmth"],
      "erythema_extent": "gt_0_5_cm",
      "probe_to_bone_test": "positive",
      "has_deep_abscess_or_fasciitis": "true"
    },
    "neuropathy": {
      "points": [0, 2]
    },
    "sinbad": {
      "site": "Forefoot",
      "ischemia": "Yes",
      "neuropathy": "Yes",
      "infection": "Yes",
      "area": "< 1 cm^2",
      "depth": "Deep"
    },
    "lab_results": {
      "wbc_count": "12000",
      "crp": "75",
      "esr": "40",
      "procalcitonin": "2.1"
    },
    "vascular": {
      "abi_value": "0.7",
      "ankle_pressure_mmHg": "80",
      "toe_pressure_mmHg": "50",
      "tcpo2_mmHg": "35"
    },
    "gangrene_extent": "forefoot"
  },
  "ai_prefill": {
    "location_primary": "sole"
  },
  "case_ref": {
    "patient_id": "PT-2603-00002",
    "case_id": "CS-260322-00002",
    "record_id": "REC-00001"
  }
}
```

**Expected response shape used by app**

The app requires:
- `status == "success"`
- `analysis`

`analysis` may be an object or a JSON string. The parsed object is expected to contain `AI_analysis`, `treatment_plan`, or both.

```json
{
  "status": "success",
  "analysis": {
    "AI_analysis": {
      "creator": "Gemini",
      "red_flag": true,
      "confidence": 0.92,
      "description": "Deep infected plantar ulcer.",
      "diagnosis": {
        "text": "Diabetic foot ulcer with infection"
      },
      "diagnosis_text": "Diabetic foot ulcer with infection",
      "treatment_plan_summary": "Urgent debridement and antibiotics.",
      "classifications": {
        "IDSA_infection_stage": 3,
        "WIfI": {
          "wound_grade": 2,
          "ischemia_grade": 1,
          "foot_infection_grade": 3,
          "clinical_stage": 3
        },
        "SINBAD": {
          "site": "Forefoot",
          "ischemia": "Yes",
          "neuropathy": "Yes",
          "bacterial_infection": "Yes",
          "area": "< 1 cm^2",
          "depth": "Deep",
          "total": 5
        }
      }
    },
    "treatment_plan": {
      "plan_id": "PLAN-00001",
      "plan_text": "Clean daily and refer urgently.",
      "followup_days": 3,
      "status": "DRAFT",
      "plan_tasks": [
        {
          "task_id": "TASK-00001",
          "task_text": "Clean wound",
          "task_due": "2026-03-23T09:00:00Z",
          "status": "PENDING"
        }
      ]
    }
  }
}
```

**AI fields actually read by UI**
- `AI_analysis.creator`
- `AI_analysis.red_flag`
- `AI_analysis.confidence`
- `AI_analysis.description`
- `AI_analysis.diagnosis.text` or `AI_analysis.diagnosis` or `AI_analysis.diagnosis_text` or `AI_analysis.dx`
- `AI_analysis.treatment_plan_summary`
- `AI_analysis.classifications.IDSA_infection_stage`
- `AI_analysis.classifications.WIfI.wound_grade`
- `AI_analysis.classifications.WIfI.ischemia_grade`
- `AI_analysis.classifications.WIfI.foot_infection_grade`
- `AI_analysis.classifications.WIfI.clinical_stage`
- `AI_analysis.classifications.SINBAD.site`
- `AI_analysis.classifications.SINBAD.ischemia`
- `AI_analysis.classifications.SINBAD.neuropathy`
- `AI_analysis.classifications.SINBAD.bacterial_infection`
- `AI_analysis.classifications.SINBAD.area`
- `AI_analysis.classifications.SINBAD.depth`
- `AI_analysis.classifications.SINBAD.total`

**Treatment plan fields actually read by UI**
- `treatment_plan.plan_id`
- `treatment_plan.plan_text`
- `treatment_plan.followup_days`
- `treatment_plan.status`
- `treatment_plan.plan_tasks[].task_id`
- `treatment_plan.plan_tasks[].task_text`
- `treatment_plan.plan_tasks[].task_due`
- `treatment_plan.plan_tasks[].status`
- `treatment_plan.plan_tasks[].completed_at`
- `treatment_plan.plan_tasks[].task_photo_url`

---

## 8. POST `/analyze-healing`

**Triggered**
- Automatically after `/analyze-wound` succeeds in follow-up flow.

**Request content type**
- `application/json`

**Outgoing JSON**

```json
{
  "case_id": "CS-260322-00002"
}
```

**Expected response shape used by app**

The app reads summary text from `analysis`, else `summary`, else `message`, else `result`. If `records` is present, the healing progress page uses it.

```json
{
  "status": "success",
  "analysis": "Healing has improved compared with prior record.",
  "records": [
    {
      "record_id": "REC-00001",
      "status": "DOCTOR_REVIEW",
      "record_created_at": "2026-03-20T10:00:00Z",
      "record_created_at_utc": "2026-03-20T10:00:00Z",
      "timestamps": {
        "created_at": "2026-03-20T10:00:00Z"
      },
      "vital_signs": {
        "temperature": "High",
        "blood_pressure": "Very High",
        "heart_rate": "High",
        "respiratory_rate": "High",
        "blood_glucose": "Very High"
      },
      "wound_detail": {
        "size": {
          "width_cm": 1.5,
          "length_cm": 1.5
        },
        "depth_category": "full_thickness",
        "pain_score": 9,
        "has_infection": true,
        "discharge": {
          "type": "seropurulent (cloudy yellow)"
        },
        "bed": {
          "slough_pct": 20,
          "necrotic_pct": 30
        }
      },
      "image": {
        "image_folder_url": "https://..."
      },
      "healing_progress": "Improving",
      "analysis": {
        "classifications": {
          "IDSA_infection_stage": 3,
          "WIfI": {
            "wound_grade": 2,
            "ischemia_grade": 1,
            "foot_infection_grade": 3
          },
          "SINBAD": {
            "total": 5
          }
        }
      }
    }
  ]
}
```

---

## 9. POST `/send-to-doctor`

**Triggered**
- Doctor summary page when user taps `Send to Doctor`.

**Request content type**
- `application/json`

**Outgoing JSON**

```json
{
  "record_id": "REC-00001",
  "case_id": "CS-260322-00002",
  "patient_id": "PT-2603-00002",
  "status": "DOCTOR_REVIEW",
  "urgency": "URGENT",
  "vital_signs": {
    "temperature": "High",
    "blood_pressure": "Very High",
    "blood_glucose": "Very High",
    "heart_rate": "High",
    "respiratory_rate": "High"
  },
  "wound_detail": {
    "location_primary": "sole",
    "location_detail": "metatarsal head",
    "wound_type": "ulcer",
    "shape": "round",
    "size": {
      "width_cm": 1.5,
      "length_cm": 1.5
    },
    "depth_category": "full_thickness",
    "bed": {
      "slough_pct": 20,
      "necrotic_pct": 30
    },
    "edge_description": "thickened",
    "periwound_status": "erythematous",
    "discharge": {
      "volume": "minimal",
      "type": "seropurulent (cloudy yellow)"
    },
    "odor_presence": "foul",
    "pain_score": 9,
    "has_infection": true,
    "skin_condition": "cracked"
  },
  "ischemia": {
    "points": [0, 1],
    "pulse": "yes",
    "checklist": ["Cold foot"]
  },
  "infection": {
    "checklist": ["Pain", "Pus", "Swelling", "Warmth"],
    "erythema_extent": "gt_0_5_cm",
    "probe_to_bone_test": "positive",
    "has_deep_abscess_or_fasciitis": "true"
  },
  "neuropathy": {
    "points": [0, 2]
  },
  "sinbad": {
    "site": "Forefoot",
    "ischemia": "Yes",
    "neuropathy": "Yes",
    "infection": "Yes",
    "area": "< 1 cm^2",
    "depth": "Deep"
  },
  "lab_results": {
    "wbc_count": "12000",
    "crp": "75",
    "esr": "40",
    "procalcitonin": "2.1"
  },
  "vascular": {
    "abi_value": "0.7",
    "ankle_pressure_mmHg": "80",
    "toe_pressure_mmHg": "50",
    "tcpo2_mmHg": "35"
  },
  "gangrene_extent": "forefoot",
  "analysis": {
    "creator": "Gemini"
  },
  "treatment_plan": {
    "plan_id": "PLAN-00001",
    "plan_text": "Clean daily and refer urgently.",
    "followup_days": 3,
    "status": "DRAFT",
    "plan_tasks": [
      {
        "task_id": "TASK-00001",
        "task_text": "Clean wound",
        "task_due": "2026-03-23T09:00:00Z",
        "status": "PENDING"
      }
    ]
  },
  "task_list": [
    {
      "task_id": "TASK-00001",
      "task_text": "Clean wound",
      "task_due": "2026-03-23T09:00:00Z",
      "status": "PENDING"
    }
  ]
}
```

**Expected response shape used by app**

The app only checks for HTTP `200`. It does not parse the body.

```json
{
  "status": "success",
  "case_id": "CS-260322-00002",
  "record_id": "REC-00001",
  "message": "Clinical case sent to doctor."
}
```

**Notes**
- `urgency` is `null` if the user did not choose one.
- `analysis` is `_aiWoundJson['AI_analysis']`.
- `task_list` duplicates `treatment_plan.plan_tasks`.

---

## 10. POST `/cases_list`

**Triggered**
- Cases tab load / refresh.
- Follow-up flow when loading cases for a selected patient.

**Request content type**
- `application/json`

**Outgoing JSON**

Without patient filter:

```json
{
  "limit": 50
}
```

With patient filter:

```json
{
  "limit": 50,
  "patient_id": "PT-2603-00002"
}
```

**Expected response shape used by app**

The app accepts either a bare array or an object with `cases: []`.

```json
{
  "status": "success",
  "cases": [
    {
      "case_id": "CS-260322-00002",
      "id": "CS-260322-00002",
      "patient_id": "PT-2603-00002",
      "status": "DOCTOR_REVIEW",
      "urgency": "URGENT",
      "case_created_at": "2026-03-22T10:00:00Z",
      "case_updated_at": "2026-03-22T12:00:00Z",
      "current_record_id": "REC-00001",
      "current_analysis_id": "AN-00001",
      "current_plan_id": "PLAN-00001"
    }
  ]
}
```

**Fields actually read by UI**
- `case_id` or `id`
- `patient_id`
- `status`
- `urgency`

---

## 11. POST `/case_detail`

**Triggered**
- When opening a case from the Cases tab.

**Request content type**
- `application/json`

**Outgoing JSON**

```json
{
  "case_id": "CS-260322-00002"
}
```

**Expected response shape used by app**

Preferred wrapper:

```json
{
  "status": "success",
  "case": {
    "case_id": "CS-260322-00002",
    "patient_id": "PT-2603-00002",
    "status": "DOCTOR_REVIEW",
    "urgency": "URGENT",
    "current_wound_detail": {},
    "current_vital_signs": {},
    "current_healing_progress": "Improving",
    "current_analysis": {
      "classifications": {
        "IDSA_infection_stage": 3,
        "WIfI": {
          "wound_grade": 2,
          "ischemia_grade": 1,
          "foot_infection_grade": 3,
          "clinical_stage": 3
        },
        "SINBAD": {
          "total": 5
        }
      }
    },
    "current_sinbad": {
      "total": 5
    },
    "current_timestamps": {
      "appointment_at": "2026-03-25T10:00:00Z"
    },
    "current_treatment_plan": {
      "plan_id": "PLAN-00001",
      "plan_text": "Clean daily and refer urgently.",
      "followup_days": 3,
      "status": "ACTIVE",
      "plan_tasks": []
    },
    "current_task_list": []
  },
  "patient_profile": {
    "patient_id": "PT-2603-00002",
    "patient_name": "John Doe",
    "dob": "1990-01-01",
    "gender": "male",
    "medical_history": "DM, HTN",
    "diabetes": {
      "has_diabetes": "yes",
      "years": "5",
      "risk_history": [],
      "complications": []
    }
  },
  "records": [
    {
      "record_id": "REC-00001",
      "status": "DOCTOR_REVIEW",
      "record_created_at": "2026-03-22T10:00:00Z",
      "timestamps": {
        "created_at": "2026-03-22T10:00:00Z",
        "appointment_at": "2026-03-25T10:00:00Z"
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
      "gangrene_extent": "forefoot",
      "analysis": {
        "classifications": {
          "IDSA_infection_stage": 3,
          "WIfI": {
            "wound_grade": 2,
            "ischemia_grade": 1,
            "foot_infection_grade": 3
          },
          "SINBAD": {
            "total": 5
          }
        }
      },
      "treatment_plan": {
        "plan_id": "PLAN-00001",
        "plan_text": "Clean daily and refer urgently.",
        "followup_days": 3,
        "status": "ACTIVE",
        "plan_tasks": []
      },
      "task_list": []
    }
  ]
}
```

**Response handling note**
- If `case` is missing, the app will treat the top-level response object itself as the case object.

---

## 12. POST `/tasks_list`

**Triggered**
- Tasks tab load / refresh.

**Request content type**
- `application/json`

**Outgoing JSON**

```json
{
  "limit": 200
}
```

**Expected response shape used by app**

Primary expected shape:

```json
{
  "status": "success",
  "tasks": [
    {
      "case_id": "CS-260322-00002",
      "patient_id": "PT-2603-00002",
      "patient_name": "John Doe",
      "current_treatment": {
        "plan_id": "PLAN-00001",
        "status": "ACTIVE",
        "plan_tasks": [
          {
            "task_id": "TASK-00001",
            "task_text": "Clean wound",
            "task_due": "2026-03-23T09:00:00Z",
            "status": "PENDING",
            "completed_at": null,
            "task_photo_url": "https://..."
          }
        ]
      }
    }
  ]
}
```

**Fields actually read by UI**
- `case_id`
- `patient_id`
- `patient_name`
- `current_treatment.plan_id`
- `current_treatment.status`
- `current_treatment.plan_tasks[]`

**Response handling note**
- The code also accepts `current_treatment_plan` as a list key, but the UI is built around the `tasks[] -> current_treatment` structure above.

---

## 13. POST `/task_detail`

**Triggered**
- Opening a treatment plan / task detail screen.

**Request content type**
- `application/json`

**Outgoing JSON**

```json
{
  "case_id": "CS-260322-00002",
  "task_index": 0
}
```

**Expected response shape used by app**

```json
{
  "status": "success",
  "case_id": "CS-260322-00002",
  "patient_id": "PT-2603-00002",
  "patient_name": "John Doe",
  "plan_id": "PLAN-00001",
  "task": {
    "task_id": "TASK-00001",
    "task_text": "Clean wound",
    "task_due": "2026-03-23T09:00:00Z",
    "status": "PENDING",
    "completed_at": null,
    "task_photo_url": "https://..."
  },
  "plan_tasks": [
    {
      "task_id": "TASK-00001",
      "task_text": "Clean wound",
      "task_due": "2026-03-23T09:00:00Z",
      "status": "PENDING",
      "completed_at": null,
      "task_photo_url": "https://..."
    }
  ],
  "current_treatment": {
    "plan_id": "PLAN-00001",
    "plan_tasks": []
  }
}
```

---

## 14. POST `/task_update`

**Triggered**
- Completing one or more tasks, optionally with evidence photos.

**Request content type**
- `multipart/form-data`

**Multipart fields**
- `case_id`
- `plan_id` (optional)
- `updates`: JSON string
- `images`: repeated file field, optional

**Outgoing payload**

```json
{
  "case_id": "CS-260322-00002",
  "plan_id": "PLAN-00001",
  "updates": [
    {
      "task_id": "TASK-00001",
      "updates": {
        "status": "COMPLETED",
        "completed_at": "2026-03-22 22:15:33"
      }
    }
  ],
  "images": ["<binary file>"]
}
```

**Expected response shape used by app**

The app only checks for HTTP `200`. It does not parse the body.

```json
{
  "status": "success",
  "case_id": "CS-260322-00002",
  "plan_id": "PLAN-00001",
  "updated_tasks": [
    {
      "task_id": "TASK-00001",
      "status": "COMPLETED",
      "completed_at": "2026-03-22 22:15:33"
    }
  ]
}
```

---

## 15. GET `/docs`

**Status**
- URI is defined in code but there is no API call to it at the moment.

---

## Response Flexibility the App Currently Accepts

- `/patients_list`: either `[]` or `{ "patients": [] }`
- `/cases_list`: either `[]` or `{ "cases": [] }`
- `/case_detail`: either `{ "case": {...}, "records": [...], "patient_profile": {...} }` or a bare case object
- `/analyze-fillin.analysis`: object or JSON string
- `/analyze-wound.analysis`: object or JSON string
- `/analyze-healing`: summary text may come from `analysis`, `summary`, `message`, or `result`
- `/send-to-doctor` and `/task_update`: any HTTP `200` body is effectively accepted because the body is not parsed

## Source of Truth

- API request builders: `lib/widgets/main_navigation_screen.dart`
- Task UI consumers: `lib/pages/tasks_page.dart`, `lib/pages/task_detail_page.dart`
- Case detail response consumers: `lib/pages/case_detail_page.dart`
- Healing response consumers: `lib/pages/healing_progress_page.dart`
- Doctor summary / AI response consumers: `lib/pages/doctor_summary_page.dart`
