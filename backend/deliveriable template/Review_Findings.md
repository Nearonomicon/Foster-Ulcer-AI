# Foster Ulcer AI Review Findings

## 1. Summary

The project has a workable end-to-end prototype covering patient intake, case creation, wound analysis, task execution, and notifications. The main delivery risks are not missing features; they are consistency, security, and maintainability.

## 2. High-severity findings

### Finding 1: No authentication or authorization on clinical APIs

Observed in:

- `app.py`
- all reviewed route files

Impact:

- any caller who can reach the backend can read and modify patient, case, task, and notification data
- inappropriate for medical data handling

Recommendation:

- add authentication
- add role-based authorization
- restrict route access by actor type

### Finding 2: Hardcoded Firebase admin credential path

Observed in:

- `services/firebase.py`

Impact:

- local-machine dependency
- credential exposure risk
- non-portable deployment and onboarding

Recommendation:

- use environment-based credential configuration only

### Finding 3: Notification feeds are shared by role, not user

Observed in:

- `routes/notifications.py`
- `services/notifications.py`
- mobile notification panel logic

Impact:

- read state is shared across all doctors or all nurses
- user-specific inbox semantics do not exist
- auditability is weak

Recommendation:

- move to per-user notification ownership if individual clinician workflows matter

## 3. Medium-severity findings

### Finding 4: Status model is inconsistent

Observed in:

- `schemas.py`
- `routes/analysis.py`
- `app.py`
- mobile filters in `main_navigation_screen.dart`

Issue:

- schema enum uses `AI_PROCESSING`
- route logic writes `ANALYZING`
- dashboard active-status logic does not include `ANALYZING`

Impact:

- filtering inconsistencies
- incorrect dashboard counts
- API contract confusion

Recommendation:

- normalize to one status vocabulary and update backend, frontend, and OpenAPI together

### Finding 5: OpenAPI file does not match implemented API

Observed in:

- `openapi.yaml`
- implemented routes

Examples:

- `/load-dashboard` is implemented as `GET`, but OpenAPI defines `POST`
- some documented response bodies differ from route behavior

Impact:

- integration confusion
- broken client generation
- invalid external documentation

Recommendation:

- regenerate or rewrite the OpenAPI spec from actual route behavior

### Finding 6: Frontend orchestration is concentrated in one large controller

Observed in:

- `lib/widgets/main_navigation_screen.dart`

Impact:

- high regression risk
- difficult testing
- difficult onboarding

Recommendation:

- split by feature area
- move API operations into service/repository classes
- isolate camera/audio/notification concerns

### Finding 7: No meaningful automated test suite

Observed in:

- backend has manual guides and helper scripts
- frontend has no practical automated tests

Impact:

- release confidence is limited
- regressions likely during refactor

Recommendation:

- implement backend integration tests and Flutter widget tests as a minimum baseline

## 4. Low-severity findings

### Finding 8: Response shape is inconsistent across routes

Impact:

- more defensive parsing in client
- more brittle integration

Recommendation:

- standardize success envelope and error model

### Finding 9: Some route naming is operational rather than resource-oriented

Examples:

- `/update_cases`
- `/tasks_list`
- `/case_detail`

Impact:

- not functionally broken, but harder to maintain and document

Recommendation:

- standardize naming during next API versioning cycle

## 5. Strengths observed

- Good case and record versioning pattern
- Practical current snapshot strategy for mobile retrieval
- End-to-end AI integration already wired
- Push notification plumbing exists on both backend and mobile
- Manual smoke-test assets already started

## 6. Recommended remediation order

Priority 1:

- API authentication and authorization
- secret/config hardening
- status vocabulary normalization

Priority 2:

- OpenAPI correction
- automated backend regression tests
- frontend modularization plan

Priority 3:

- notification model refinement
- response model normalization
- broader non-functional testing

