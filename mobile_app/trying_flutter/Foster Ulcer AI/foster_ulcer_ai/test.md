# Foster Ulcer AI Frontend Manual Test Guide

## Purpose

This document is a manual test checklist for the Flutter frontend.

It is intended to be filled in during QA, UAT, or smoke testing while running the mobile app against the current backend.

## Scope

This guide covers the current frontend flows exposed in the app:

1. Dashboard
2. Patient search
3. New patient intake
4. Vital check
5. Wound image capture and AI fill-in
6. Wound assessment
7. Doctor summary and send-to-doctor
8. Notifications panel
9. Healing progress
10. Cases list and case detail
11. Tasks list and task detail
12. Profile tab and app navigation
13. Follow-up case flow
14. Emergency escalate entry flow

## Test Environment

Fill these in before execution.

| Field | Value |
| --- | --- |
| Tester |  |
| Test Date |  |
| App Build / Commit |  |
| Device Model |  |
| OS Version |  |
| Backend Base URL |  |
| Network |  |
| Notes |  |

## Suggested Test Data

Use unique values for each run.

| Field | Suggested Value |
| --- | --- |
| Patient Name | `Frontend Test Patient YYYY-MM-DD A` |
| NRC ID | `1234567890123` |
| Phone No | Leave blank for optional-phone validation, then also test with a value |
| DOB | Any valid past date |
| Gender | Male / Female / Other |
| Height | `160` |
| Weight | `55` |
| Diabetes | `Yes` and `No` in separate runs if needed |
| Wound Image | 1 clear sample wound photo |
| Audio Note | 1 short assessment audio clip |

## Result Legend

| Status | Meaning |
| --- | --- |
| PASS | Worked as expected |
| FAIL | Did not match expected behavior |
| BLOCKED | Could not execute because of dependency or environment issue |
| N/A | Not applicable for this run |

## Test Case Matrix

Fill in the last four columns during testing.

| Test ID | Screen / Flow | Scenario | Expected Result | Status | Actual Result | Evidence / Notes | Retest |
| --- | --- | --- | --- | --- | --- | --- | --- |
| FE-001 | App launch | Open app and land on default home screen | App loads without crash and shows Dashboard |  |  |  |  |
| FE-002 | Bottom navigation | Switch between Home, Tasks, Cases, and Profile tabs | Each tab opens correctly and active tab state updates |  |  |  |  |
| FE-003 | Dashboard | Load dashboard metrics from backend | Dashboard cards render counts and upcoming plans without layout breakage |  |  |  |  |
| FE-003A | Dashboard | Pull to refresh dashboard | Dashboard reloads without crash and values/cards refresh |  |  |  |  |
| FE-004 | Dashboard | Open New Patient flow from dashboard | App navigates to Find Patient screen |  |  |  |  |
| FE-004A | Dashboard | Open Follow-up Case flow from dashboard | App navigates to Find Patient screen with follow-up path available |  |  |  |  |
| FE-004B | Dashboard | Open Emergency Escalate flow from dashboard | App bypasses profile flow and opens camera step without crash |  |  |  |  |
| FE-005 | Patient Search | Search existing patient by name or query | Matching patients are shown in the results list |  |  |  |  |
| FE-005A | Patient Search | Pull to refresh patient list | Patient list reloads without crash |  |  |  |  |
| FE-005B | Patient Search | Select an existing patient | Selected patient row is visually marked as selected |  |  |  |  |
| FE-006 | Patient Search | Start intake for a new patient | App navigates to New Patient Intake |  |  |  |  |
| FE-006A | Patient Search | Proceed with a selected existing patient | Intake page opens with selected patient data prefilled |  |  |  |  |
| FE-007 | Intake | Create patient with required fields populated | Patient profile saves successfully and flow continues |  |  |  |  |
| FE-008 | Intake | Leave phone number blank and save patient profile | Save is allowed; phone number is treated as optional |  |  |  |  |
| FE-009 | Intake | Capture or change patient image | Captured image is displayed in intake screen |  |  |  |  |
| FE-010 | Intake | Select date of birth using date picker | Selected date appears in DOB field |  |  |  |  |
| FE-011 | Intake | Select gender option | Selected gender chip/button is visually highlighted |  |  |  |  |
| FE-012 | Intake | Set Diabetes = No | Diabetes dependent fields are hidden or cleared |  |  |  |  |
| FE-013 | Intake | Set Diabetes = Yes without years selection | Save is blocked and validation message is shown |  |  |  |  |
| FE-014 | Intake to Vital Check | Save valid patient profile | App moves to Vital Check or patient cases flow as designed |  |  |  |  |
| FE-015 | Vital Check | Enter vital signs and continue | Values are retained and next step opens |  |  |  |  |
| FE-016 | Camera | Open wound camera / image capture screen | Camera page opens without crash |  |  |  |  |
| FE-017 | Camera | Capture wound image | Captured image preview is shown and app proceeds |  |  |  |  |
| FE-018 | AI Fill-in Response | Submit image for fill-in | Response screen shows extracted output or handled error state |  |  |  |  |
| FE-019 | Response View | Proceed from fill-in response to checklist | App navigates to Wound Assessment |  |  |  |  |
| FE-020 | Assessment | Load assessment page after fill-in | Assessment form renders without missing section errors |  |  |  |  |
| FE-021 | Assessment | Review or edit wound assessment fields | Manual edits are accepted and remain visible |  |  |  |  |
| FE-022 | Assessment | Record audio note | Recording starts and stops successfully |  |  |  |  |
| FE-023 | Assessment | Preview recorded audio | Recorded audio preview plays and stops correctly |  |  |  |  |
| FE-024 | Assessment | Send transcription request with recorded audio | Transcript request completes or returns a handled blocked/error state |  |  |  |  |
| FE-025 | Assessment | Submit wound analysis | App shows loading state and then opens result flow without crash |  |  |  |  |
| FE-026 | Doctor Summary | Load AI analysis and draft treatment plan | Summary page shows diagnosis, urgency, and tasks data |  |  |  |  |
| FE-027 | Doctor Summary | Change urgency selection | Selected urgency updates visually and is used for submission |  |  |  |  |
| FE-028 | Doctor Summary | Send case to doctor | Success message appears and app returns to dashboard |  |  |  |  |
| FE-029 | Dashboard | Verify newly sent case affects dashboard data | Dashboard refresh shows updated counts or upcoming items when backend data supports it |  |  |  |  |
| FE-029A | Notifications | Open notifications panel from dashboard/profile/cases/tasks | Notifications bottom sheet opens and loads notification items or empty state |  |  |  |  |
| FE-029B | Notifications | Open case detail from a notification item | Tapping case pill opens Case Detail for that case |  |  |  |  |
| FE-030 | Cases | Open Cases tab and load list | Cases list loads without crash and displays cards/items |  |  |  |  |
| FE-030A | Cases | Pull to refresh case list | Case list reloads without crash |  |  |  |  |
| FE-030B | Cases | Search by case ID, patient ID, patient name, or status | Visible case results update correctly |  |  |  |  |
| FE-030C | Cases | Filter by case status | Only matching case statuses remain visible |  |  |  |  |
| FE-030D | Cases | Filter by urgency | Only matching urgency items remain visible |  |  |  |  |
| FE-030E | Cases | Change case sort order | Case ordering updates according to selected sort |  |  |  |  |
| FE-031 | Cases | Open case detail from case list | Case Detail screen opens for selected case |  |  |  |  |
| FE-032 | Case Detail | Review patient, wound, and treatment details | Main case sections render correctly with no obvious missing data binding |  |  |  |  |
| FE-033 | Case Detail | Open task detail from case detail | Task Detail opens for selected task |  |  |  |  |
| FE-033A | Patient Cases | Open follow-up patient case list for selected patient | Patient-specific case list opens and shows existing cases for that patient |  |  |  |  |
| FE-033B | Patient Cases | Start follow-up from an existing patient case | App enters Vital Check for the selected case and preserves case references |  |  |  |  |
| FE-034 | Tasks | Open Tasks tab and load plans/tasks | Tasks page loads current treatment plans or task items |  |  |  |  |
| FE-035 | Tasks | Use search field on tasks page | Search filters visible task results correctly |  |  |  |  |
| FE-036 | Tasks | Filter by treatment status / task status | Filtered results update correctly |  |  |  |  |
| FE-037 | Tasks | Change sort order | Task ordering changes according to selected sort |  |  |  |  |
| FE-038 | Tasks | Expand a task group / case card | Expanded section reveals task items correctly |  |  |  |  |
| FE-038A | Tasks | Switch between Treatment Plans and Individual Tasks views | Page content changes correctly between grouped and flat task views |  |  |  |  |
| FE-039 | Task Detail | Mark one or more tasks completed | Update succeeds and UI reflects changed status after refresh/navigation |  |  |  |  |
| FE-040 | Task Detail | Update tasks without evidence photo | App handles missing photo warning gracefully and still follows designed behavior |  |  |  |  |
| FE-041 | Healing Progress | Open healing progress flow for follow-up case | Healing Progress screen opens and displays available healing analysis |  |  |  |  |
| FE-042 | Healing Progress | Swipe or switch between healing records | Record carousel/page indicator updates correctly |  |  |  |  |
| FE-043 | Profile | Open Profile tab | Profile page renders without crash |  |  |  |  |
| FE-044 | Navigation | Use back buttons across major screens | Back navigation returns to the expected previous screen |  |  |  |  |
| FE-045 | Error Handling | Disconnect backend or use bad base URL during load action | App shows a readable failure state/snackbar instead of crashing |  |  |  |  |
| FE-046 | Responsive Layout | Test on target device size/orientation | No critical overflow, clipped controls, or unusable actions |  |  |  |  |

## Test Flow

Run the following flows in order. Record the related test IDs as you go.

### Flow 1: App Launch And Navigation Smoke

1. Launch the app and confirm Dashboard is the default screen.
2. Open the notification panel and confirm it loads either data or an empty state.
3. Switch through Home, Tasks, Cases, and Profile.
4. Return to Home.

Related test IDs: `FE-001`, `FE-002`, `FE-003`, `FE-003A`, `FE-029A`, `FE-043`

### Flow 2: New Patient To Send-To-Doctor

1. From Dashboard, tap `Create Case`.
2. In Find Patient, verify list load, search behavior, and refresh.
3. Choose `Register New Patient`.
4. Complete intake once with phone number blank.
5. Confirm intake save succeeds when phone is blank.
6. Separately verify diabetes validation by setting Diabetes = `Yes` without years and confirming save is blocked.
7. Complete valid intake data and continue.
8. In Vital Check, enter vitals and continue.
9. Open camera, capture wound image, and submit AI fill-in.
10. On response screen, proceed to checklist.
11. On assessment screen, review/edit fields.
12. Record audio, preview it, and send transcription.
13. Submit wound analysis.
14. On doctor summary, review AI output, adjust urgency, and send to doctor.
15. Confirm success snackbar/message and return to Dashboard.

Related test IDs: `FE-004`, `FE-005`, `FE-005A`, `FE-006`, `FE-007`, `FE-008`, `FE-009`, `FE-010`, `FE-011`, `FE-012`, `FE-013`, `FE-014`, `FE-015`, `FE-016`, `FE-017`, `FE-018`, `FE-019`, `FE-020`, `FE-021`, `FE-022`, `FE-023`, `FE-024`, `FE-025`, `FE-026`, `FE-027`, `FE-028`

### Flow 3: Post-Submission Verification

1. Refresh Dashboard and check whether counts or upcoming items change.
2. Open Notifications and verify a case-related item appears if backend data is available.
3. Open Cases tab.
4. Verify search, status filter, urgency filter, sort, and refresh behavior.
5. Open the case detail of the case created in Flow 2.
6. Confirm patient, wound, treatment plan, and task sections render.
7. Open task detail from case detail.

Related test IDs: `FE-029`, `FE-029A`, `FE-029B`, `FE-030`, `FE-030A`, `FE-030B`, `FE-030C`, `FE-030D`, `FE-030E`, `FE-031`, `FE-032`, `FE-033`

### Flow 4: Task Management

1. Open Tasks tab.
2. Verify both `Treatment Plans` and `Individual Tasks` views.
3. Test search, filters, sorting, and expansion.
4. Open a task detail page.
5. Mark one or more tasks completed.
6. Repeat once without evidence photo and confirm the warning/behavior is handled cleanly.

Related test IDs: `FE-034`, `FE-035`, `FE-036`, `FE-037`, `FE-038`, `FE-038A`, `FE-039`, `FE-040`

### Flow 5: Follow-Up Case And Healing

1. Return to Dashboard and tap `Follow-up Case`.
2. In Find Patient, select an existing patient and proceed.
3. Confirm intake is prefilled for the selected patient.
4. Continue to the patient-specific cases list.
5. Select an existing case to start follow-up.
6. Enter vitals, continue through image capture and assessment flow, and complete analysis.
7. If healing analysis is returned, verify Healing Progress opens and record paging works.

Related test IDs: `FE-004A`, `FE-005B`, `FE-006A`, `FE-033A`, `FE-033B`, `FE-041`, `FE-042`

### Flow 6: Emergency Entry

1. From Dashboard, tap `Emergency Escalate`.
2. Confirm the app bypasses profile entry and opens the camera flow directly.
3. Verify the screen loads without crash and back navigation remains usable.

Related test IDs: `FE-004B`, `FE-016`, `FE-044`

### Flow 7: Error And Layout Checks

1. Trigger a backend failure case, such as using an unavailable backend URL or disconnecting network.
2. Verify the current screen shows a readable error/snackbar instead of crashing.
3. Check the main flows on the target device size and orientation for overflow or clipping.

Related test IDs: `FE-045`, `FE-046`

## Focus Regression Checklist

Use this compact checklist for quick smoke testing after small frontend changes.

| Item | Check | Status | Notes |
| --- | --- | --- | --- |
| RG-001 | App launches successfully |  |  |
| RG-002 | Dashboard loads |  |  |
| RG-003 | Patient search opens |  |  |
| RG-004 | Intake form saves |  |  |
| RG-005 | Phone number can be blank on intake |  |  |
| RG-006 | Vital check continues correctly |  |  |
| RG-007 | Camera capture works |  |  |
| RG-008 | Fill-in response renders |  |  |
| RG-009 | Assessment page loads |  |  |
| RG-010 | Send-to-doctor works |  |  |
| RG-011 | Notifications panel opens |  |  |
| RG-012 | Cases tab loads |  |  |
| RG-013 | Tasks tab loads |  |  |
| RG-014 | Case detail opens from list |  |  |

## Defect Log

Record defects found during execution.

| Defect ID | Test ID | Summary | Severity | Repro Steps | Status | Owner |
| --- | --- | --- | --- | --- | --- | --- |
| BUG-001 |  |  |  |  |  |  |

## Sign-off

| Role | Name | Date | Result |
| --- | --- | --- | --- |
| Tester |  |  |  |
| Reviewer |  |  |  |
| Final QA Decision |  |  |  |
