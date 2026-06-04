# Foster Ulcer AI Testing Document

## 1. Objective

This document records the current testing posture of the project and defines a practical test standard for delivery and maintenance.

## 2. Reviewed test assets

Backend files found:

- `api_test_runner.py`
- `test_gemini_api.py`
- `test_notification.py`
- `test.md`

Frontend automated test folder:

- no meaningful Flutter widget or integration test suite was found in the reviewed app source

## 3. Current test maturity assessment

### What exists

- Manual API test guide in markdown
- A Python smoke-test runner for backend lifecycle flows
- Small utility scripts for Gemini connectivity and FCM notification sending

### What is missing

- Unit tests for backend route logic
- Unit tests for backend schema/validation helpers
- Integration tests with Firestore emulator
- Flutter widget tests
- Flutter integration tests
- End-to-end test automation across mobile and backend
- Security tests
- Performance and load tests

## 4. Recommended test levels

### Level 1: Backend unit tests

Target:

- helper functions in `app.py`
- task normalization and plan status helpers in `routes/cases.py` and `routes/task.py`
- datetime parsing and merge behavior

Priority examples:

- `_normalize_datetime`
- `_normalize_plan_tasks`
- `_merge_non_null`
- dashboard due-date parsing and counting

### Level 2: Backend integration tests

Target:

- FastAPI route behavior
- Firestore reads/writes using emulator or mocked repository boundary

Priority flows:

- patient create and update
- case create and follow-up
- send-to-doctor
- doctor-review
- task update
- notifications read and mark-all-read

### Level 3: Mobile widget tests

Target:

- key screens render correctly
- form validation
- task completion gating
- notification panel

### Level 4: Mobile integration tests

Target:

- create patient and case flow
- capture image path
- analyze wound path
- task completion with evidence image

### Level 5: Non-functional tests

Target:

- API response-time measurement
- notification delivery verification
- offline/poor-network behavior
- concurrency and shared-feed behavior

## 5. Regression checklist

Minimum release regression set:

- Create patient profile
- Update patient profile
- Create new case
- List cases
- Open case detail
- Run image fill-in
- Run wound analysis
- Send to doctor
- Save doctor review
- List tasks
- Open task detail
- Update task with evidence photo
- Load dashboard
- Create appointment
- Request close
- Complete case
- Create follow-up record
- Run healing analysis for a follow-up case
- Open nurse notifications
- Mark notification read

## 6. High-risk scenarios that require explicit testing

- Status transitions involving `ANALYZING`, `DOCTOR_REVIEW`, `PLAN_ISSUED`, `APPOINTMENT`, `REQUEST_CLOSE`, `COMPLETED`
- Follow-up case creation with carried-forward treatment plan
- Task updates when image count and update count differ
- Notification mark-all-read behavior in shared role feeds
- Healing analysis on large record histories
- Missing or malformed datetime values

## 7. Manual acceptance test matrix

| Area | Scenario | Expected result |
| --- | --- | --- |
| Patient | Create patient with image | Patient stored and photo URL returned |
| Patient | Patch patient profile | Updated fields returned and visible later |
| Case | Create initial case | New case and `REC-00001` created |
| Case | Create follow-up record | New record ID generated and current snapshot updated |
| Analysis | Fill-in with valid image | Image stored and structured analysis returned |
| Analysis | Wound analysis | `success` or safe `blocked` response |
| Review | Send to doctor | Analysis and plan versions created |
| Review | Doctor review with reordered tasks | Plan saved, statuses `SENT`, order normalized |
| Task | Complete task with evidence image | Task updated and evidence URL stored |
| Dashboard | Load dashboard after plan creation | Due counts and upcoming items returned |
| Notification | Read one notification | Item becomes `READ` |
| Notification | Mark all read | Shared role unread count cleared |
| Lifecycle | Appointment transition | Case, record, plan, tasks move to `APPOINTMENT` |
| Lifecycle | Close request | Case and record move to `REQUEST_CLOSE` |
| Lifecycle | Complete case | Case, record, plan, tasks move to `COMPLETED` |

## 8. Suggested automation priority

Priority 1:

- Backend route integration tests for core lifecycle
- Backend helper unit tests

Priority 2:

- Flutter widget tests for intake, assessment, tasks, notifications

Priority 3:

- Full end-to-end test harness against a staging backend

## 9. Evidence from review

Based on repository review, testing is currently documentation-heavy and script-assisted, not automated in a CI-quality way.

Practical conclusion:

- The project has a usable manual smoke-test baseline.
- It does not yet meet a strong app-development testing standard for a medical workflow product.

## 10. Release gate recommendation

Before production rollout, require:

- automated backend regression suite
- Flutter smoke integration test
- environment-based staging validation
- security review for unauthenticated API access
- documented incident rollback procedure
