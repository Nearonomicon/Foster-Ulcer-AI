# Foster Ulcer AI — Codebase Summary

> Last updated: 2026-06-04  
> For onboarding new teammates and tracking active issues.

---

## 1. What the App Does

Foster Ulcer AI is a clinical wound-care tool for nurses and doctors managing diabetic foot ulcer (DFU) patients. Nurses capture wound images, fill in clinical assessments, and send cases to doctors for AI-assisted review and treatment planning.

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| Mobile frontend | Flutter (Dart) |
| Backend API | Python 3 / FastAPI |
| Database | Google Firestore |
| File storage | Firebase Storage |
| AI engine | Google Gemini (via `genai_client.py`) |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Hosting | Cloud Run (Docker) |

---

## 3. Repository Structure

```
Foster-Ulcer-AI/
├── backend/
│   ├── app.py               # FastAPI app, middleware, /load-dashboard
│   ├── main.py              # Entry point
│   ├── schemas.py           # All Pydantic models and enums
│   ├── routes/
│   │   ├── cases.py         # Core case lifecycle endpoints
│   │   ├── patients.py      # Patient CRUD
│   │   ├── analysis.py      # AI analysis endpoints
│   │   ├── notifications.py # FCM notification endpoints
│   │   └── task.py          # Treatment task endpoints
│   ├── services/
│   │   ├── firebase.py      # Firestore + Storage client init
│   │   ├── genai_client.py  # Gemini AI wrapper
│   │   └── notifications.py # Notification helpers
│   ├── prompts.py           # AI prompt templates
│   ├── utils.py             # Shared helpers
│   ├── workflow.md          # Full workflow documentation (read this!)
│   └── API.md / openapi.yaml
│
└── mobile_app/trying_flutter/Foster Ulcer AI/foster_ulcer_ai/
    └── lib/
        ├── main.dart
        ├── firebase_options.dart
        ├── widgets/
        │   ├── main_navigation_screen.dart  # Root state + all navigation logic
        │   └── foster_ulcer_app.dart
        ├── pages/                           # UI split as extensions on main state
        │   ├── vital_check_page.dart
        │   ├── intake_page.dart
        │   ├── camera_page.dart
        │   ├── assessment_page.dart
        │   ├── doctor_summary_page.dart
        │   ├── case_detail_page.dart
        │   ├── cases_page.dart
        │   ├── dashboard_page.dart
        │   ├── healing_progress_page.dart
        │   ├── response_view_page.dart
        │   └── task_detail_page.dart
        └── services/
            └── notification_service.dart
```

---

## 4. Firestore Data Model

```
patients/{patient_id}
  - patient_name, nrc_id, dob, gender, phone_no
  - height_cm, weight_kg, diabetes, medical_history
  - photo_url, created_at

cases/{case_id}
  - patient_id, status, urgency
  - created_by_nurse, assigned_doctor
  - case_created_at, case_updated_at
  - current_record_id, current_analysis_id, current_plan_id
  - current_vital_signs, current_wound_detail, current_analysis, ...  (snapshot mirrors)
  - current_treatment_plan { plan_tasks: [...] }   ← task source of truth on the case

  records/{record_id}
    - vital_signs, wound_detail, ischemia, infection, neuropathy
    - sinbad, lab_results, vascular, gangrene_extent
    - timestamps { created_at, updated_at, analyze_at, doctor_review_at, ... }
    - image { image_folder_url }
    - analysis, treatment_plan { plan_tasks: [...] }  ← task source of truth on the record
    - status, urgency

    analysis_versions/{analysis_id}
    plan_versions/{plan_id}
      tasks/{task_id}
```

---

## 5. Case Status Lifecycle

```
CREATION → AI_PROCESSING / ANALYZING → DOCTOR_REVIEW → PLAN_ISSUED
         → TREATMENT_ACTIVE → APPOINTMENT → REQUEST_CLOSE → COMPLETED
```

Relevant statuses:
- `CREATION` — case created by nurse, clinical data not yet submitted
- `DOCTOR_REVIEW` — nurse submitted via `/send-to-doctor`
- `PLAN_ISSUED` — doctor has reviewed and issued a treatment plan
- `COMPLETED` — case closed

---

## 6. Core API Endpoints

| Method | Path | Description |
|---|---|---|
| POST | `/create-case` | Creates a new case + first record (REC-00001) with blank clinical data |
| POST | `/update_cases` | Creates a new follow-up record under an existing case |
| POST | `/cases_list` | Lists cases, optionally filtered by patient/status |
| POST | `/case_detail` | Returns case + all records + patient profile |
| POST | `/analyze-fillin` | Uploads wound image, returns AI pre-fill |
| POST | `/analyze-wound` | Submits full nurse assessment, runs AI analysis |
| POST | `/send-to-doctor` | Finalizes record, creates analysis+plan versions, sets DOCTOR_REVIEW |
| POST | `/no-wound-assessment` | Completes a case where no wound is present |
| POST | `/doctor-review` | Doctor submits reviewed analysis + treatment plan |
| POST | `/create_appointment` | Sets appointment date, moves to APPOINTMENT |
| POST | `/request_close` | Nurse requests case closure |
| POST | `/complete_case` | Marks case COMPLETED |
| GET  | `/load-dashboard` | Returns summary stats + upcoming tasks |
| POST | `/task_update` | Updates task progress/photos |

---

## 7. Flutter Navigation Flow (Create Case)

All navigation is managed by `_currentStep` (a String) in `_MainNavigationScreenState`.

**New Case Flow:**
```
patient_search → intake → vital_check_page
  ↓ [/create-case called here, stores case_id + record_id in _caseRefs]
camera → assessment → response_view → doctor_summary
  ↓ [/send-to-doctor called here]
dashboard
```

**Follow-Up Flow** (`_followUpFlow = true`):
```
patient_search → patient_cases → vital_check_page
  ↓ [/update_cases called, creates a new record]
camera → assessment → healing_progress → doctor_summary
  ↓ [/send-to-doctor]
dashboard
```

Key state variables:
- `_caseRefs` — `{ patient_id, case_id, record_id }` — set after `/create-case` or `/update_cases`
- `_followUpFlow` — `true` when in follow-up path (causes `/update_cases` instead of `/create-case`)
- `_reviewed` — map of all nurse-assessed clinical values
- `_patientProfile` — current patient data

---

## 8. Key Design Decisions

- **Snapshot pattern:** The `cases` document mirrors the latest record's clinical data in `current_*` fields. This lets the dashboard and case list show current info without reading subcollections.
- **Non-null merge:** `/update_cases` and `/send-to-doctor` use `_merge_non_null()` to carry forward existing clinical data when incoming fields are null.
- **Plan versioning:** Every time a treatment plan is issued (via `/send-to-doctor` or `/doctor-review`), a new `plan_versions/{plan_id}` subcollection is created.
- **`task_list` is deprecated** — the canonical task location is `treatment_plan.plan_tasks` on both case and record documents.

---

---

# 🐛 Bug Report & Fix Plan

## Issue: Incomplete Cases Cannot Be Resumed

Three statuses represent cases that are stuck mid-flow and need to be resumable:

| Status | What it means | Stuck point |
|---|---|---|
| `CREATION` | Case created, vitals may be blank or partial, no image/assessment yet | Before or during `vital_check_page` |
| `AI_PROCESSING` / `ANALYZING` | Vitals + image + assessment submitted, AI called, but nurse never reached "Send to Doctor" | Between `response_view` and `doctor_summary` |

All three statuses leave an orphan case the nurse cannot continue. Starting a new case creates duplicates.

---

## Fix Plan

### Approach: Resume flow at the correct step based on status

The resumable statuses map to different re-entry points in the Flutter navigation flow:

```
CREATION          → resume at vital_check_page  (may need to redo vitals/image/assessment)
AI_PROCESSING     → resume at response_view      (AI result already available, skip to review)
ANALYZING         → resume at response_view      (same as above)
```

The fix requires changes in both Flutter and (optionally) the backend.

---

### Backend Changes

#### New endpoint: `POST /resume-case`

Handles resuming any case whose status is `CREATION`, `AI_PROCESSING`, or `ANALYZING`. Unlike `/update_cases` (which always creates a new record), this endpoint patches the **existing** current record in-place.

```
POST /resume-case
  Body: { case_id, patient_id, vitals, meta }
  Behavior:
    - Validates case exists
    - Validates status is one of: CREATION, AI_PROCESSING, ANALYZING
    - Updates vital_signs on the existing current_record_id record (no new record created)
    - Updates case_updated_at
    - Returns { case_id, record_id, status }
```

```python
# schemas.py
class ResumeCaseRequest(BaseModel):
    case_id: str
    patient_id: str
    vitals: Optional[CreateCaseVitals] = None
    meta: Optional[CreateCaseMeta] = None

RESUMABLE_STATUSES = {"CREATION", "AI_PROCESSING", "ANALYZING"}
```

```python
# routes/cases.py
@router.post("/resume-case")
async def resume_case(payload: ResumeCaseRequest):
    case_ref = db.collection("cases").document(payload.case_id)
    case_data = case_ref.get().to_dict() or {}
    status = str(case_data.get("status") or "").upper()
    if status not in RESUMABLE_STATUSES:
        raise HTTPException(400, f"Case is not resumable (status={status})")
    record_id = case_data.get("current_record_id")
    # patch vitals onto existing record
    record_ref = case_ref.collection("records").document(record_id)
    vital_signs = _build_vital_signs(payload.vitals)
    batch = db.batch()
    batch.set(record_ref, {"vital_signs": vital_signs, "record_updated_at": _utc_now()}, merge=True)
    batch.set(case_ref, {"current_vital_signs": vital_signs, "case_updated_at": _utc_now()}, merge=True)
    batch.commit()
    return {"status": "success", "case_id": payload.case_id, "record_id": record_id}
```

> **Why not reuse `/update_cases`?** That endpoint always creates a new record. Keeping resume as a separate endpoint preserves the semantic: `/update_cases` = new follow-up, `/resume-case` = continue existing incomplete case.

---

### Flutter Changes

#### 1. New state flag

```dart
// In _MainNavigationScreenState
bool _resumingIncompleteCase = false;
```

#### 2. Detect resumable cases and show the right CTA

In `cases_page.dart` and `case_detail_page.dart`, branch on status:

```dart
const resumableStatuses = {'CREATION', 'AI_PROCESSING', 'ANALYZING'};
final status = (caseData['status'] ?? '').toString().toUpperCase();

if (resumableStatuses.contains(status)) {
  _resumeIncompleteCase(caseData);
} else {
  _enterFollowUpVitals(caseData);  // existing follow-up path, unchanged
}
```

#### 3. Add `_resumeIncompleteCase()` — routes to the correct step

```dart
void _resumeIncompleteCase(Map<String, dynamic> caseData) {
  final patientId = caseData['patient_id']?.toString();
  final caseId    = caseData['case_id']?.toString();
  final recordId  = caseData['current_record_id']?.toString();
  final status    = (caseData['status'] ?? '').toString().toUpperCase();

  _patientProfile['patient_id'] = patientId;
  _caseRefs
    ..clear()
    ..addAll({'patient_id': patientId, 'case_id': caseId, 'record_id': recordId});

  _resumingIncompleteCase = true;
  _followUpFlow = false;

  if (status == 'CREATION') {
    // Pre-fill vitals from snapshot, resume from vitals step
    final existingVitals = caseData['current_vital_signs'];
    if (existingVitals is Map) {
      _reviewed.addAll(Map<String, dynamic>.from(existingVitals));
    }
    _navigateTo('vital_check_page');

  } else {
    // AI_PROCESSING or ANALYZING:
    // vitals + image + assessment already exist — skip straight to review/send
    // Pre-populate _aiWoundJson from current_analysis snapshot if available
    final existingAnalysis = caseData['current_analysis'];
    if (existingAnalysis is Map) {
      _aiWoundJson = Map<String, dynamic>.from(existingAnalysis);
    }
    final existingVitals = caseData['current_vital_signs'];
    if (existingVitals is Map) {
      _reviewed.addAll(Map<String, dynamic>.from(existingVitals));
    }
    _navigateTo('response_view');  // or 'doctor_summary' depending on what data is available
  }
}
```

#### 4. Patch `_createCaseFromVitals()` — call `/resume-case` instead of creating new

```dart
Future<bool> _createCaseFromVitals() async {
  if (_resumingIncompleteCase) {
    return await _resumeExistingCaseVitals();  // calls /resume-case, same record_id
  }
  // ... existing create-case logic unchanged
}

Future<bool> _resumeExistingCaseVitals() async {
  final payload = {
    'case_id': _caseRefs['case_id'],
    'patient_id': _caseRefs['patient_id'],
    'vitals': { /* same vitals map as in _createCaseFromVitals */ },
    'meta': {'sent_at': _getFormattedTimestamp()},
  };
  final resp = await http.post(_resumeCaseUri, ...).timeout(...);
  // _caseRefs already has the correct case_id + record_id — no need to update them
  return resp.statusCode == 200;
}
```

#### 5. Reset flag in `_navigateTo()`

```dart
void _navigateTo(String step, ...) {
  setState(() {
    ...
    if (step == 'vital_check_page') {
      if (!_resumingIncompleteCase) _clearVitalsInfo();  // don't wipe pre-populated vitals
    }
    if (step == 'dashboard' || step == 'patient_search') {
      _resumingIncompleteCase = false;
    }
  });
}
```

---

### UX Flows After Fix

**CREATION case:**
```
Cases Tab → tap "Continue Case"
  → vital_check_page (pre-filled vitals, no new record created)
    → camera → assessment → doctor_summary → send-to-doctor ✅
```

**AI_PROCESSING / ANALYZING case:**
```
Cases Tab → tap "Continue Case"
  → response_view (AI result pre-loaded from current_analysis snapshot)
    → doctor_summary → send-to-doctor ✅
```

Neither path creates a new record — both continue the same existing `record_id`.

---

### Files to Change

| File | Change |
|---|---|
| `backend/schemas.py` | Add `ResumeCaseRequest` model and `RESUMABLE_STATUSES` constant |
| `backend/routes/cases.py` | Add `POST /resume-case` endpoint |
| `lib/widgets/main_navigation_screen.dart` | Add `_resumingIncompleteCase` flag, `_resumeIncompleteCase()`, `_resumeExistingCaseVitals()`, `_resumeCaseUri`; update `_createCaseFromVitals()` and `_navigateTo()` |
| `lib/pages/cases_page.dart` | Show "Continue Case" button for CREATION / AI_PROCESSING / ANALYZING status |
| `lib/pages/case_detail_page.dart` | Show "Continue Case" action in header/footer for resumable statuses |

---

### Out of Scope (Not Needed for This Fix)

- No changes to the follow-up flow (`_followUpFlow` path) — it is unaffected.
- No changes to `/send-to-doctor`, `/analyze-wound`, or `/analyze-fillin` — they already work with existing `case_id` + `record_id`.
- No database migration — existing orphaned CREATION / AI_PROCESSING / ANALYZING cases will naturally become resumable once the UI supports it.

### Edge Case Notes

- **AI_PROCESSING / ANALYZING with no `current_analysis`:** The AI call may have failed before storing results. In this case, fall back to resuming at `assessment` (re-run the full assessment → AI flow) instead of `response_view`. Check `caseData['current_analysis'] != null` before deciding the entry point.
- **Image already uploaded:** `current_image.image_folder_url` will be non-null. The camera step can be made skippable (show existing image with an option to retake) rather than forcing a re-upload.
- **Vitals already complete:** Pre-fill the vital_check_page fields from `current_vital_signs` so the nurse only needs to confirm, not re-enter everything.
