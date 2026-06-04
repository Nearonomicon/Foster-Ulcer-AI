# feat: resume incomplete cases (CREATION / ANALYZING / AI_PROCESSING)

## Problem

When a nurse starts the create-case flow, `/create-case` fires as soon as vitals are submitted — creating a Firestore case document immediately. If the nurse exits the app before reaching **Send to Doctor**, the case is left stuck with blank or partial clinical data and no way to continue it.

Three statuses are affected:

| Status | Cause | Data state |
|---|---|---|
| `CREATION` | Nurse exited after vitals, before camera/assessment | Vitals may be blank or partial; no image, no assessment |
| `ANALYZING` | `/analyze-wound` was called (assessment saved), but AI call failed or nurse exited before Send to Doctor | Full assessment saved; AI result may or may not be stored |
| `AI_PROCESSING` | Legacy / transitional status, same situation as ANALYZING | Same as above |

Previously the only option was to start a **new duplicate case** for the same patient.

---

## Solution

Add a **"Continue Case"** path that re-enters the existing case at the right step without creating a new record.

### Resume entry points

```
CREATION                          → vital_check_page  (vitals pre-filled, same record patched)
ANALYZING + AI result present     → doctor_summary     (AI result loaded, ready to send)
ANALYZING + AI result missing     → assessment         (all fields pre-filled, re-run AI)
```

---

## Changes

### Backend

**`backend/schemas.py`**
- Added `RESUMABLE_STATUSES = {"CREATION", "AI_PROCESSING", "ANALYZING"}`
- Added `ResumeCaseRequest` Pydantic model

**`backend/routes/cases.py`**
- Added `POST /resume-case` endpoint
  - Validates case exists and status is in `RESUMABLE_STATUSES`
  - Patches vitals onto the **existing** `current_record_id` record using a Firestore batch (no new record created)
  - Returns same `{ case_id, record_id }` — downstream flow (camera → assessment → send-to-doctor) is unchanged

> **Why not reuse `/update_cases`?** That endpoint always creates a new follow-up record. `/resume-case` deliberately does not, keeping the semantic clean.

### Flutter

**`lib/widgets/main_navigation_screen.dart`**
- Added `bool _resumingIncompleteCase` state flag
- Added `final Uri _resumeCaseUri` pointing to `/resume-case`
- Added `_resumeIncompleteCase(caseData)` — routes to the correct re-entry step based on status and available data
- Added `_resumeExistingCaseVitals()` — calls `/resume-case`, keeps `_caseRefs` unchanged (same record)
- Modified `_createCaseFromVitals()` — short-circuits to `_resumeExistingCaseVitals()` when flag is set
- Modified `_navigateTo()` — skips `_clearVitalsInfo()` when resuming; resets flag on navigation to top-level screens

**`lib/pages/vital_check_page.dart`**
- Back button routes to `cases` when resuming (instead of `intake`)

**`lib/pages/cases_page.dart`**
- Per-patient case list tap handler routes resumable statuses to `_resumeIncompleteCase` instead of `_enterFollowUpVitals`

**`lib/pages/case_detail_page.dart`**
- "Continue Case" button added to case header — visible only when status is `CREATION`, `AI_PROCESSING`, or `ANALYZING`

---

## Flow diagrams

### CREATION resume
```
Cases tab / Case Detail
  → tap "Continue Case"
    → vital_check_page  (vitals pre-filled from current_vital_signs)
      → [POST /resume-case — patches vitals, same record_id]
        → camera → assessment → doctor_summary
          → [POST /send-to-doctor]  ✅
```

### ANALYZING resume (AI result present)
```
Cases tab / Case Detail
  → tap "Continue Case"
    → doctor_summary  (_aiWoundJson loaded from current_analysis)
      → [POST /send-to-doctor]  ✅
```

### ANALYZING resume (AI result missing — AI previously failed)
```
Cases tab / Case Detail
  → tap "Continue Case"
    → assessment  (all fields pre-filled from current_* snapshots)
      → [POST /analyze-wound] → doctor_summary
        → [POST /send-to-doctor]  ✅
```

---

## What is NOT changed

- Follow-up flow (`_followUpFlow`, `/update_cases`) — completely unaffected
- `/send-to-doctor`, `/analyze-wound`, `/analyze-fillin` — work unchanged with the existing `case_id` + `record_id`
- No database migration required — existing orphaned cases become resumable automatically

---

## Deployment

| Layer | Action |
|---|---|
| Backend | Redeploy Cloud Run container |
| Flutter | `shorebird patch android` — pure Dart changes, no new APK needed |

---

## Testing checklist

- [ ] CREATION case: tap Continue → vitals pre-filled → complete flow → case reaches DOCTOR_REVIEW
- [ ] ANALYZING case (with analysis): tap Continue → lands on doctor summary → send to doctor works
- [ ] ANALYZING case (no analysis): tap Continue → lands on assessment pre-filled → re-submit AI → send to doctor works
- [ ] Normal follow-up on a PLAN_ISSUED / COMPLETED case → still calls `/update_cases`, creates new record as before
- [ ] Back button on vital_check_page during resume → returns to Cases tab, not Intake
- [ ] Exiting to dashboard during resume → `_resumingIncompleteCase` flag is reset correctly
- [ ] `/resume-case` with a non-resumable status (e.g. DOCTOR_REVIEW) → returns 400
