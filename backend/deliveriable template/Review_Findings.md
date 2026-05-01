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

### Finding 10: Specific code-level issues discovered during this review

The following concrete code defects were observed and should be tracked as discrete tickets:

**`services/firebase.py` line 12 — credential filename leaked in source.**
The hardcoded path `C:/Users/Pawarit/Desktop/foster-ulcer-ai-firebase-adminsdk-fbsvc-6eda7ee8ab.json` is committed to the repository. Even though the file is local, the *filename* itself reveals service-account naming conventions and is now in git history. Same path also appears in `backend/blackboard.ipynb`. Treat the existing service-account key as compromised and rotate it.

**`app.py` lines 96–129 — request/response middleware logs full PHI bodies.**
Every request and response body is decoded and printed, including patient names, NRC IDs, vitals, and structured wound assessments. This is a HIPAA / PDPA exposure if logs land in any non-restricted log sink. The middleware also reconstructs the response body from the iterator on every call, which breaks streaming responses and adds memory pressure on large analysis payloads.

**`app.py` line 167 — unbounded dashboard scan.**
`/load-dashboard` streams the entire `cases` collection on every call. There is no limit, no pagination, and no index hint. This will silently degrade and then time out as case volume grows.

**`routes/analysis.py` lines 184–186 — duplicate JSON parse.**
```python
data_dict = json.loads(response.text)
raw_text = response.text.strip().replace("```json", "").replace("```", "")
data_dict = json.loads(raw_text)
```
The first `json.loads` is wasted work and will throw on fenced output before the cleanup runs. Reorder so the cleanup happens first, or drop the first call.

**`routes/analysis.py` `/analyze-healing` — sequential image fetches.**
Each historical image is downloaded synchronously inside an `async` route via `urlopen`. For a chronic patient with many follow-ups, this serializes N HTTPS round-trips on the request thread and blocks the event loop. Use `httpx.AsyncClient` with concurrency, or pre-fetch in a thread pool.

**`routes/analysis.py` line 119, line 480, `routes/task.py` line 239 — `datetime.utcnow()` is deprecated.**
Replace with `datetime.now(timezone.utc)`. `utcnow()` returns a naive datetime and is removed in future Python releases.

**`services/genai_client.py` lines 13–18 — all Gemini safety filters set to `BLOCK_NONE`.**
This is intentional for clinical wound imagery but should be documented in a model card, audited periodically, and gated to wound-image and clinical-text inputs only. If user-supplied audio is ever extended beyond transcription, revisit.

**`backend/requirements.txt` — no version pins, plus `pandas` declared but never imported.**
Unpinned dependencies make builds non-reproducible and expose the deployment to upstream breakage. `pandas` is heavy (~50MB extra image weight) and is not actually used by the backend code reviewed.

**`backend/Dockerfile` — single-stage, runs as root, copies the entire context.**
There is no `.dockerignore` visible; the local `venv/` directory and Firebase admin JSON could leak into the image. Image runs as `root` with no `USER` directive. Add `.dockerignore`, switch to a multi-stage slim build, and run as a non-root user.

**`mobile_app/.../main_navigation_screen.dart` — 3,734-line god file with `part of` directive.**
All `lib/pages/*.dart` files are `part of` this single controller. State, API calls, camera, audio, navigation, and notification handling all share private fields. Refactor into per-feature modules with explicit interfaces.

**Mobile API base URL is hardcoded.**
`_baseUrl` flips between commented-out emulator and production Cloud Run URL. Move to compile-time `--dart-define` or a flavor system so dev/staging/prod can be selected without editing source.

**`routes/cases.py` lines 311, 328 — Firestore transactional helpers.**
`@firestore.transactional` decorated functions are correctly defined but the `transaction = db.transaction()` instance is reused across `get_next_case_id` and `create_case_with_first_record` in the request handler. Confirm this is intentional; the safer pattern is one transaction per critical section.

**`routes/cases.py` `/cases_list` — composite-index hazard.**
When both `patient_id` and a status `IN` filter are supplied, the code intentionally drops `order_by` to dodge composite-index errors. The trade-off is unstable result ordering. Add the composite index in Firestore and remove the workaround.

**`routes/notifications.py` `/notifications/mark-all-read` — multi-batch race.**
Streaming the unread query and committing 500-doc batches in a loop can race against concurrent inserts and miss records. Acceptable for a shared role inbox, but document the eventual-consistency behavior.

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

