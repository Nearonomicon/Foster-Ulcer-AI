# Foster Ulcer AI API Contract

## 1. Scope

This contract describes the backend currently implemented in the FastAPI service. It is the effective contract used by the Flutter client.

Base backend entry points found in code:

- Local: `http://127.0.0.1:8080`
- Android emulator: `http://10.0.2.2:8080`
- Mobile app production target: `https://foster-ulcer-ai-backend-429230748709.asia-southeast3.run.app`

## 2. Technology and runtime

- Framework: FastAPI
- Data store: Firestore
- File store: Firebase Storage
- AI provider: Google Gemini via `google-genai`
- Push notifications: Firebase Cloud Messaging
- Auth: none implemented

## 3. Contract conventions

- Most success responses include a `status` field, but values are not fully standardized.
- Error responses generally return `{"detail": ...}`.
- Reads are a mix of `GET` and `POST`.
- Some write/read route names use underscores instead of REST resource naming.
- Some payloads are `multipart/form-data` because they include image or audio uploads.

## 4. Core domain entities

### Patient

Key fields:

- `patient_id`
- `patient_name`
- `phone_no`
- `dob`
- `gender`
- `height_cm`
- `weight_kg`
- `medical_history`
- `diabetes`
- `status`
- `photo_url`

### Case

Key fields:

- `case_id`
- `patient_id`
- `created_by_nurse`
- `assigned_doctor`
- `status`
- `urgency`
- `current_record_id`
- `current_analysis_id`
- `current_plan_id`
- `current_*` snapshot fields

### Record

Key fields:

- `record_id`
- `case_id`
- `patient_id`
- `status`
- `vital_signs`
- `wound_detail`
- `ischemia`
- `infection`
- `neuropathy`
- `sinbad`
- `lab_results`
- `vascular`
- `gangrene_extent`
- `analysis`
- `treatment_plan`
- `image`
- `current_healing_progress`

### Treatment plan

Key fields:

- `plan_id`
- `plan_text`
- `followup_days`
- `status`
- `plan_tasks`

### Task

Key fields:

- `task_id`
- `task_text`
- `status`
- `task_due`
- `completed_at`
- `task_photo_url`
- `source`
- `order_index`

## 5. Status values in use

Declared enum values in backend schema:

- `CREATION`
- `AI_PROCESSING`
- `DOCTOR_REVIEW`
- `PLAN_ISSUED`
- `TREATMENT_ACTIVE`
- `APPOINTMENT`
- `REQUEST_CLOSE`
- `COMPLETED`

Observed additional runtime value written by code:

- `ANALYZING`

This mismatch is a known implementation issue and should be treated as an integration risk.

## 6. Endpoint summary

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/load-dashboard` | Dashboard counts and upcoming plan items |
| `POST` | `/create-patient-profile` | Create patient profile with optional image |
| `GET` | `/patients_list` | List patient profiles |
| `PATCH` | `/patients/{patient_id}` | Partial patient update |
| `POST` | `/create-case` | Create initial case and first record |
| `POST` | `/update_cases` | Create follow-up record for existing case |
| `POST` | `/cases_list` | List cases, optional filters |
| `POST` | `/case_detail` | Get case, records, and patient profile |
| `POST` | `/send-to-doctor` | Save reviewed record, AI draft analysis, draft plan |
| `POST` | `/doctor-review` | Save doctor-reviewed analysis and treatment plan |
| `POST` | `/create_appointment` | Move current case/plan/tasks to appointment state |
| `POST` | `/request_close` | Request case closure |
| `POST` | `/complete_case` | Complete current case |
| `POST` | `/analyze-transcribe` | AI transcription from wound audio note |
| `POST` | `/analyze-fillin` | Image upload and AI field prefill |
| `POST` | `/analyze-wound` | Main layered AI wound analysis |
| `POST` | `/analyze-healing` | Healing summary across record history |
| `POST` | `/tasks_list` | List current treatment plans containing tasks |
| `POST` | `/task_detail` | Get current treatment plan or specific task |
| `POST` | `/task_update` | Update task status, due date, text, evidence image |
| `POST` | `/notification-devices/register` | Register FCM token |
| `POST` | `/notification-devices/unregister` | Unregister FCM token |
| `GET` | `/doctor-notifications` | Shared doctor notification feed |
| `GET` | `/nurse-notifications` | Shared nurse notification feed |
| `POST` | `/notifications/{notification_id}/read` | Mark one notification read |
| `POST` | `/notifications/mark-all-read` | Mark all notifications read |

## 7. Endpoint details

### `GET /load-dashboard`

Returns:

- `today_task_no`
- `total_active_patient`
- `upcoming_plan`

Current implementation rule:

- It counts active patients only for statuses in `CREATION`, `AI_PROCESSING`, `DOCTOR_REVIEW`, `PLAN_ISSUED`, `TREATMENT_ACTIVE`, `APPOINTMENT`.
- Cases in `ANALYZING` are not counted as active by dashboard logic.

### `POST /create-patient-profile`

Content type: `multipart/form-data`

Form fields:

- `patient_data`: JSON string, required
- `image`: file, optional

Behavior:

- Generates patient ID in form `PT-YYMM-#####`
- Stores profile image under Firebase Storage if supplied
- Writes patient document to `patients/{patient_id}`

### `GET /patients_list`

Query:

- `limit` default `50`, clamped `1..200`

Behavior:

- Returns patients ordered by `created_at` descending

### `PATCH /patients/{patient_id}`

Body:

- Partial JSON object

Behavior:

- Only non-null fields are merged
- `height_cm` and `weight_kg` are cast to float if present

### `POST /create-case`

Body:

- `patient_id` required
- optional `status`, `urgency`, `created_by_nurse`, `assigned_doctor`, `vitals`, `meta.sent_at`

Behavior:

- Generates `case_id`
- Creates `record_id = REC-00001`
- Writes both case and first record
- Initializes empty clinical sections

### `POST /update_cases`

Purpose:

- Creates a follow-up record for an existing case

Behavior:

- Validates `case_id`
- Validates patient ownership
- Computes next `record_id`
- Merges forward non-null sections from the latest record
- May duplicate prior treatment plan into a new plan version
- Updates top-level `current_*` case snapshot

### `POST /cases_list`

Body:

- `limit`
- `patient_id`
- `filter` list of statuses

Behavior:

- No filter: ordered by `case_updated_at` descending
- With filter or patient ID: queried without ordering
- Enriches case rows with patient name and photo

### `POST /case_detail`

Body:

- `case_id` required

Returns:

- `case`
- `records`
- `patient_profile`

### `POST /send-to-doctor`

Purpose:

- Finalizes nurse-reviewed record payload for doctor review

Required sections:

- `record_id`
- `case_id`
- `patient_id`
- `vital_signs`
- `wound_detail`
- `ischemia`
- `infection`
- `neuropathy`
- `sinbad`
- `lab_results`
- `vascular`

Behavior:

- Merges with existing record
- Generates new `analysis_id`
- Generates new `plan_id`
- Stores AI draft analysis version
- Stores treatment plan version and task documents
- Sets case status to `DOCTOR_REVIEW`
- Creates doctor notification and broadcasts FCM to role `DOCTOR`

### `POST /doctor-review`

Preferred body shape:

- top-level `case_id`
- top-level `record_id`
- top-level `analysis`
- optional top-level `treatment_plan`

Legacy compatibility:

- accepts `payload`

Behavior:

- Creates new doctor analysis version
- Copies prior `SINBAD` classification into doctor payload
- Creates new plan version if treatment plan provided
- Forces plan task statuses to `SENT`
- Sets case status to `PLAN_ISSUED`
- Creates nurse notification and broadcasts FCM to role `NURSE`

### `POST /create_appointment`

Body:

- `case_id`
- `appointment_at`

Behavior:

- Updates current case, record, plan, and task statuses to `APPOINTMENT`

### `POST /request_close`

Body:

- `case_id`

Behavior:

- Updates current case and record to `REQUEST_CLOSE`
- Creates doctor notification

### `POST /complete_case`

Body:

- `case_id`
- optional `completed_at`

Behavior:

- Updates current case, record, plan, and task statuses to `COMPLETED`

### `POST /analyze-transcribe`

Content type: `multipart/form-data`

Fields:

- `case_id`
- `record_id`
- `audio`

Returns:

- `status: success` with `transcript`
- or `status: blocked`

### `POST /analyze-fillin`

Content type: `multipart/form-data`

Fields:

- `case_id`
- `record_id`
- `image`

Behavior:

- Validates image
- Uploads to Firebase Storage
- Updates record image reference
- Returns structured AI prefill payload

### `POST /analyze-wound`

Content type: `multipart/form-data`

Fields:

- `payload_data`: JSON string
- `image`

Behavior:

- Persists nurse-reviewed data to current record
- Sets case and record status to `ANALYZING`
- Runs three Gemini layers
- Returns final AI result as a JSON string inside `analysis`

Integration note:

- Response is not a nested object. Clients must parse the string.

### `POST /analyze-healing`

Body:

- `case_id`

Behavior:

- Loads all records for the case
- Attaches stored wound images when reachable by URL
- Generates healing summary
- Stores summary on latest record and current case snapshot
- Sets latest record and case status to `DOCTOR_REVIEW`
- Creates doctor notification

### `POST /tasks_list`

Body:

- optional `limit`, default `200`

Returns:

- `current_treatment_plan`: array of cases with active current treatment plans

Contract note:

- Response field name is misleading. It contains a list, not one treatment plan.

### `POST /task_detail`

Body:

- `case_id` required
- optional `task_id`
- optional `task_index`

Returns:

- `current_treatment`
- and either `task` or `plan_tasks`

### `POST /task_update`

Content type: `multipart/form-data`

Fields:

- `case_id`
- optional `plan_id`
- `updates`: JSON string list
- optional `images`

Allowed update fields:

- `status`
- `task_due`
- `completed_at`
- `task_photo_url`
- `task_text`
- `source`

Behavior:

- Updates case current treatment plan
- Updates current record treatment plan
- Updates plan-version task documents
- Uploads evidence photos to Firebase Storage when provided

### Notification endpoints

Role model:

- `DOCTOR`
- `NURSE`

Current behavior:

- Notification feeds are shared by role, not user-specific
- Marking notifications read affects the shared role feed

## 8. Firestore structure

Collections observed in code:

- `patients/{patient_id}`
- `cases/{case_id}`
- `cases/{case_id}/records/{record_id}`
- `cases/{case_id}/records/{record_id}/analysis_versions/{analysis_id}`
- `cases/{case_id}/records/{record_id}/plan_versions/{plan_id}`
- `cases/{case_id}/records/{record_id}/plan_versions/{plan_id}/tasks/{task_id}`
- `all_doctor/{notification_id}`
- `all_nurse/{notification_id}`
- `notification_devices/{device_token_id}`
- `metadata/counters_*`

## 9. Integration risks

- No authentication or authorization on any route
- Contract/doc mismatch exists between `openapi.yaml` and implemented routes
- Enum mismatch exists between `AI_PROCESSING` and runtime `ANALYZING`
- Some response payloads are not normalized
- Medical and notification data is exposed through broad shared feeds and open CORS

