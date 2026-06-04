# Foster Ulcer AI Improvement Guide

A prioritized, file-level engineering and delivery plan for the next two iterations of Foster Ulcer AI. Every item is written so it can be turned into a ticket without further analysis: scope, where to change it, acceptance criteria, and rough effort.

The guide is organized by priority bucket. Do **all of P0** before any external pilot. Do **most of P1** before broader handover. P2 is engineering hygiene that pays off across the next year of work.

---

## P0 — Must do before any external use

### 1. Rotate the leaked Firebase admin key, then move credentials out of source

**Why:** `services/firebase.py:12` and `backend/blackboard.ipynb` both contain the path `C:/Users/Pawarit/Desktop/foster-ulcer-ai-firebase-adminsdk-fbsvc-6eda7ee8ab.json`. The filename itself is a service-account naming convention and is now in git history. Treat the underlying key as compromised.

**Action:**
1. In the Google Cloud Console, delete the existing service account key and issue a new one.
2. Store the new key in Secret Manager (or your team's secret store).
3. Update `services/firebase.py` to load credentials from `GOOGLE_APPLICATION_CREDENTIALS` (an env var pointing at a path) for local dev, and from default-application-credentials when `K_SERVICE` is set on Cloud Run.
4. Add the JSON filename pattern to `.gitignore` and run `git filter-repo` (or BFG) on the historical commits if the key file ever sat in the working tree.
5. Strip the path out of `blackboard.ipynb`.

**Acceptance:** No path containing `Pawarit` or `adminsdk` appears in any tracked file. Backend boots locally with `GOOGLE_APPLICATION_CREDENTIALS=...` and on Cloud Run with no env file.

**Effort:** 0.5 day.

---

### 2. Add authentication and role authorization to every clinical endpoint

**Why:** All routes in `routes/*.py` accept anonymous calls. Anyone who reaches the public Cloud Run URL can read patient data, create cases, mark tasks complete, and write doctor reviews. This is incompatible with the data being handled.

**Action:**
1. Pick an auth provider. Firebase Authentication is the path of least resistance because the app already depends on Firebase.
2. Add a FastAPI dependency `get_current_user` that verifies the bearer ID token via `firebase_admin.auth.verify_id_token`.
3. Define two roles — `NURSE` and `DOCTOR` — as custom claims on the user.
4. Replace open routes with role-guarded ones:
   - Nurse: `/create-patient-profile`, `/create-case`, `/update_cases`, `/analyze-*`, `/send-to-doctor`, `/task_update`, `/nurse-notifications`, `/load-dashboard`.
   - Doctor: `/doctor-review`, `/create_appointment`, `/request_close`, `/complete_case`, `/doctor-notifications`.
   - Both: read-only `/cases_list`, `/case_detail`, `/patients_list`.
5. Update the Flutter client to attach `Authorization: Bearer <id_token>` to every request via an `http.BaseClient` interceptor.

**Acceptance:** Anonymous calls return `401`. A nurse token cannot call `/doctor-review` (returns `403`). End-to-end nurse flow still works with a logged-in test account.

**Effort:** 3–5 days, including the Flutter login screen.

---

### 3. Stop logging request and response bodies

**Why:** `app.py:96–129` writes the entire request and response payload — including patient names, NRC IDs, vitals, and AI-generated medical assessments — to stdout on every call. On Cloud Run those logs land in Cloud Logging, which is broadly readable by default project members.

**Action:**
1. Replace the body-printing middleware with structured logging that captures method, path, status, latency, and a request ID only.
2. If body logging is needed for debug, gate it on `LOG_BODIES=true` and never enable it in production.
3. Remove the synchronous body re-buffering — it breaks streaming and adds memory pressure on the layered analysis responses.
4. Confirm `log_requests` is below auth so unauthenticated 401s do not include request bodies.

**Acceptance:** No PHI in logs. A grep for patient names in Cloud Logging on a smoke-test day returns zero hits.

**Effort:** 0.5 day.

---

### 4. Lock down CORS

**Why:** `app.py:22` sets `allow_origins=["*"]`, `allow_methods=["*"]`, `allow_headers=["*"]`. The mobile client never needs CORS — only the (currently nonexistent) doctor web app does.

**Action:**
1. Change `allow_origins` to a hardcoded list of approved origins (the doctor portal once it exists, plus localhost for dev) read from env.
2. Set `allow_credentials=True` only after auth is in place.

**Acceptance:** Browser calls from an unknown origin are blocked. Mobile app is unaffected (no CORS for native apps).

**Effort:** 1 hour.

---

### 5. Resolve the `ANALYZING` vs `AI_PROCESSING` status drift

**Why:** `schemas.py` defines `Status.AI_PROCESSING`, but `routes/analysis.py:226–244` writes the literal string `"ANALYZING"` for both `record.status` and `case.status`. The `app.py` dashboard's `ACTIVE_CASE_STATUSES` includes `AI_PROCESSING` but **not** `ANALYZING`, so any case mid-analysis is silently dropped from the active patient count.

**Action:**
1. Decide on one term — `AI_PROCESSING` is the schema-correct one.
2. Update `routes/analysis.py` to write `Status.AI_PROCESSING` (use the enum, not a string).
3. Search the Flutter client for the string `"ANALYZING"` and replace, then add it to any status filter list that displays in-flight cases.
4. Add a tiny migration: a one-shot script that updates existing Firestore documents with `status == "ANALYZING"` to `"AI_PROCESSING"`.

**Acceptance:** No literal `"ANALYZING"` string in backend or frontend source. Dashboard active-patient count includes mid-analysis cases.

**Effort:** 0.5 day plus migration.

---

## P1 — Should do before broader handover

### 6. Refactor `lib/widgets/main_navigation_screen.dart`

**Why:** This file is 3,734 lines and uses Dart's `part of` directive to merge fourteen page files into a single class scope. Every `_baseUrl`, every API call, every controller, every piece of intake state is private to this one widget. New work breaks unrelated flows; the file is the single biggest regression risk in the product.

**Action (incremental, do not rewrite at once):**
1. Extract the API surface into `lib/services/api_client.dart` — a class with typed methods (`createPatient`, `analyzeWound`, `sendToDoctor`, etc.) and one shared `http.Client`. Make `_baseUrl` a `--dart-define` constant.
2. Extract per-feature state into `ChangeNotifier` (or Riverpod / Bloc — pick one) so `dashboard`, `intake`, `assessment`, `tasks`, and `notifications` each own their state.
3. Convert `lib/pages/*.dart` from `part of` into real imports with their own widgets receiving the state objects.
4. Move camera and audio recording into dedicated services so the screen does not own the lifecycles.
5. Add Flutter widget tests for each extracted page as you go.

**Acceptance:** No file in `lib/` exceeds 600 lines. `lib/pages/*.dart` are real imports, not `part of`. Adding a new field to intake does not require touching cases, tasks, or notifications.

**Effort:** 2–3 weeks if done carefully alongside other work. Do not skip the tests.

---

### 7. Regenerate the OpenAPI spec from the live FastAPI app

**Why:** `backend/openapi.yaml` is hand-maintained and has drifted — `/load-dashboard` is `GET` in code and `POST` in the spec, several response bodies do not match, and some routes are missing. Anyone generating clients from it will produce broken code.

**Action:**
1. Delete `openapi.yaml`.
2. Add a script `scripts/dump_openapi.py` that imports `app` from `backend.app` and writes `app.openapi()` to disk.
3. Run it in CI to publish the spec as a build artifact.
4. Add response models to every route (currently most return raw `dict`); FastAPI will then generate accurate schemas automatically.

**Acceptance:** `openapi.yaml` is regenerated on every push. The Flutter team can generate a typed client from it without hand-fixing.

**Effort:** 1 day for the script and CI step. Adding response models is incremental.

---

### 8. Build a real automated test suite

**Why:** `Testing.md` documents excellent intent. The reality is one Python script (`api_test_runner.py`) and zero Flutter tests. Without automation, every refactor in P1 #6 is a coin flip.

**Action — minimum viable suite:**
1. **Backend unit tests** (`pytest`):
   - `_normalize_datetime`, `_normalize_plan_tasks`, `_merge_non_null`, `_is_all_null` from `routes/cases.py`.
   - Dashboard date parsing and counting from `app.py`.
   - SINBAD/wIfI schema validation in `schemas.py`.
2. **Backend integration tests** (`pytest` + Firestore emulator):
   - Create patient → create case → fill-in → analyze-wound (mocked Gemini) → send-to-doctor → doctor-review → complete_case.
   - Follow-up record creation with carried-forward plan.
   - Task update with evidence image.
3. **Flutter widget tests** (`flutter test`):
   - Intake form validation.
   - SINBAD score calculation.
   - Task completion gating (cannot complete without evidence photo).
4. Run all of the above in GitHub Actions on every PR.

**Acceptance:** PRs cannot merge with red CI. Coverage on `routes/cases.py` and the assessment widget exceeds 60%.

**Effort:** 5–7 days for the initial harness, then continuous.

---

### 9. Move per-user notification ownership

**Why:** `routes/notifications.py` and `services/notifications.py` write to shared `all_doctor` and `all_nurse` collections. Marking a notification read affects every doctor or every nurse on the system. This is fine for a single-user demo, not for a real clinical setting where multiple users have distinct work queues.

**Action:**
1. Add `recipient_user_id` to the notification documents.
2. Replace the role broadcast with targeted writes — when a case has `assigned_doctor`, write to that user's inbox; otherwise fall back to broadcast.
3. Update read endpoints to filter by `recipient_user_id == current_user.uid`.
4. Update the FCM `send_push_to_role` to also support `send_push_to_user(user_id)` once user-token mapping exists.

**Acceptance:** Two doctors logged in see different notification counts. Marking one as read does not affect the other.

**Effort:** 3 days.

---

### 10. Bound the dashboard query

**Why:** `/load-dashboard` streams the entire `cases` collection. Today this works because there are tens of cases. At hundreds-to-low-thousands it will start adding seconds; at higher volumes it will time out the request.

**Action:**
1. Add a status filter to the Firestore query so only `ACTIVE_CASE_STATUSES` cases are streamed.
2. Add the appropriate composite index for `status IN ... ORDER BY case_updated_at DESC`.
3. Cap the stream at, say, 200 cases — the dashboard does not need more.
4. Move the upcoming-task aggregation into a denormalized `tasks` top-level collection so the dashboard does not have to walk every `current_treatment_plan`.

**Acceptance:** `/load-dashboard` returns in under 500ms with 1,000 historical cases.

**Effort:** 1.5 days.

---

## P2 — Engineering hygiene

### 11. Pin Python dependencies and trim unused ones

`requirements.txt` is unpinned and includes `pandas` (~50MB) which the backend never imports. Switch to `uv` or `pip-tools`, pin everything, and drop `pandas`.

**Effort:** 0.5 day.

### 12. Harden the Dockerfile

Add a `.dockerignore` (exclude `venv/`, `__pycache__/`, the Firebase admin JSON, mock data). Switch to a multi-stage build. Add `USER appuser` and create the user. Drop the `exec` from the `CMD` (it is unnecessary in `CMD exec` form already; modern Cloud Run handles SIGTERM correctly).

**Effort:** 0.5 day.

### 13. Replace `datetime.utcnow()`

Three call sites in `routes/analysis.py` and `routes/task.py` use the deprecated `datetime.utcnow()`. Replace with `datetime.now(timezone.utc)`.

**Effort:** 15 minutes.

### 14. Fix the duplicate `json.loads` in `/analyze-fillin`

Lines 184–186 of `routes/analysis.py` parse the same payload twice. The first call will throw on fenced output. Move the strip-fences cleanup before the parse, then call `json.loads` once.

**Effort:** 5 minutes.

### 15. Parallelize image fetches in `/analyze-healing`

Replace the `urlopen` loop with `httpx.AsyncClient` and `asyncio.gather` so historical images for chronic patients are fetched concurrently. Cap concurrency (e.g., 5) to avoid hitting Firebase Storage limits.

**Effort:** 1 day.

### 16. Standardize the response envelope

Most routes return `{"status": "success", ...}` but the keys differ wildly — `cases`, `current_treatment_plan` (which holds a list of plans, not one), `analysis` (sometimes a dict, sometimes a JSON string). Normalize to:

```json
{ "data": ..., "meta": { "request_id": "...", "version": "v1" } }
```

and roll it out as `/v1/*` routes while leaving the old paths in place for one release.

**Effort:** 3 days, including client migration.

### 17. Improve route naming during the v1 cut

`/update_cases` actually creates a follow-up record. `/tasks_list` returns plans, not tasks. `/case_detail` is a `POST` that takes a body. Rename to `/cases/{id}/follow-up`, `/treatment-plans`, and `GET /cases/{id}` respectively when v1 ships.

**Effort:** Folded into #16.

### 18. Remove the layered AI prompts from import-time loading

`backend/prompts.py` is 1,408 lines and is imported eagerly. Move it behind lazy loaders so cold starts do not pay the full parse cost.

**Effort:** 0.5 day.

### 19. Unify mobile environment configuration

Hardcoded Cloud Run URL in `lib/widgets/main_navigation_screen.dart:518`. Move to `--dart-define=API_BASE_URL=...` and create three flavors: `dev`, `staging`, `prod`.

**Effort:** 0.5 day.

### 20. Wire mobile FCM token unregister on logout

Once auth (P0 #2) lands, calling `/notification-devices/unregister` on logout will keep the device-token table accurate. The backend endpoint already exists.

**Effort:** Folded into the auth ticket.

---

## Suggested two-sprint plan

**Sprint 1 (P0):** Tickets 1–5. End state: pilot-grade security and config baseline.

**Sprint 2 (P1, partial):** Tickets 7–8 plus the API-client extraction from #6. End state: drift-free OpenAPI, real CI, and a clean seam for the mobile refactor.

**Sprint 3+:** Continue #6 incrementally, then #9 and #10. Ship P2 items opportunistically alongside related feature work.

---

## Risk to flag to stakeholders

The two non-negotiables for any external clinical use:

1. **Authentication and authorization** (P0 #2). Without this, every demo or pilot is exposing patient data publicly. Pause external rollout until shipped.
2. **PHI-free logging** (P0 #3). Even an internal-only Cloud Run service will emit patient data to project-wide log readers. Fix before sharing the project beyond the dev team.

Everything else is recoverable. These two are not.
