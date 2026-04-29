# Foster Ulcer AI User Manual

## 1. Purpose

This manual describes the reviewed nurse-facing mobile workflow implemented in the current Flutter app.

Primary user role observed in the reviewed client:

- Nurse or wound-care operator

## 2. Main app areas

The app navigation currently exposes:

- Home dashboard
- Tasks
- Cases
- Profile

The implementation is centered in one large screen controller that switches internal workflow steps.

## 3. Startup and connectivity

At app launch the client:

- initializes Firebase push notifications
- opens the nurse navigation shell
- attempts to sync the mobile FCM token to the backend
- loads nurse notifications or handles an opened push message

Backend URL configured in the app:

- `https://foster-ulcer-ai-backend-429230748709.asia-southeast3.run.app`

## 4. Nurse workflow

### Step 1: Open dashboard

Use the Home tab to review:

- number of tasks due today
- number of active patients
- upcoming treatment items
- unread notifications

### Step 2: Search or select patient

Use the patient search flow to:

- find an existing patient
- review patient summary
- begin a new case
- continue a follow-up case

### Step 3: Create or update patient profile

The app supports:

- new patient registration
- editing an existing patient profile
- optional patient photo

Typical captured profile data:

- name
- NRC / ID
- date of birth
- gender
- phone
- height and weight
- medical history
- diabetes history and complications

### Step 4: Create case or follow-up record

For new visits:

- the app creates a new case

For existing treatment journeys:

- the app creates a new follow-up record under the existing case

The nurse typically selects:

- urgency
- assigned doctor
- initial vital signs

### Step 5: Capture wound image

The camera flow supports:

- wound framing guidance
- capture stability checks
- image confirmation

After confirmation the image is uploaded for AI prefill.

### Step 6: Review AI prefill

The app requests `/analyze-fillin` and populates editable fields from the returned wound analysis.

The nurse should review and correct all suggested values before continuing.

### Step 7: Complete assessment

Assessment sections currently implemented:

- vital signs
- wound detail
- ischemia
- infection
- neuropathy
- SINBAD
- lab results
- vascular assessment
- gangrene extent
- audio note transcription assist

The app also validates required clinical sections before send-to-doctor.

### Step 8: Run main AI wound analysis

The app sends the reviewed structured assessment and wound image to `/analyze-wound`.

Expected result:

- AI summary
- AI classifications
- draft treatment plan

### Step 9: Review AI summary and draft plan

The nurse can inspect:

- AI diagnosis
- treatment summary
- draft plan tasks

This step is the nurse-side validation step before official send-to-doctor.

### Step 10: Send to doctor

When the assessment is complete, the nurse sends the case to doctor review.

Expected outcome:

- case status moves to doctor review
- draft plan and task versions are stored
- doctor receives role notification

## 5. Follow-up workflow

For follow-up care:

1. Open existing patient.
2. Select existing case.
3. Create follow-up record.
4. Capture a new wound image.
5. Review and update assessment values.
6. Run AI wound analysis.
7. Optionally trigger healing analysis across record history.
8. Send updated record to doctor if escalation is needed.

Implementation note:

- The current mobile app waits one minute before calling healing analysis in the follow-up path. This is a workflow risk and may feel unresponsive in live usage.

## 6. Tasks workflow

Use the Tasks tab to:

- list active treatment plans
- inspect task details
- capture evidence image
- mark tasks completed

Expected current task actions:

- attach task evidence image
- mark a task completed

Backend APIs support broader task-field updates, but the reviewed mobile UI primarily exercises completion with an evidence photo.

## 7. Cases workflow

Use the Cases tab to:

- list cases
- filter by status
- review urgency and last updated time
- open case history

Case detail shows:

- current case summary
- historical records
- patient profile
- treatment details

## 8. Notifications workflow

The app includes a notifications panel for:

- unread nurse workflow events
- case-related updates
- navigating directly into a case from a notification

Current functional limitations:

- the reviewed client reads from the shared nurse feed only
- read state is shared at role level, not per person

## 9. Good operating practice

- Review every AI-generated field before submission.
- Confirm patient identity before creating a new case.
- Use follow-up records instead of overwriting earlier records.
- Capture clear wound images before AI analysis.
- Attach evidence image before marking tasks completed.
- Treat notification feeds as operational aids, not as the legal source of truth.

## 10. Known user-facing limitations

- No visible login or role-based access control is implemented.
- Notification read state is shared by role.
- Some status names differ between backend enum definitions and runtime behavior.
- The app controller is highly coupled, so regressions in one flow may affect others.
- The reviewed Flutter app appears nurse-facing only; doctor review exists in backend APIs but is not exposed here as a dedicated doctor client flow.
