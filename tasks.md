# Foster Ulcer AI — Frontend UX Improvement Tasks

## Status Legend
- ✅ Done
- 🔄 In Progress
- ⬜ Pending

---

## 🔴 High Impact

### ✅ 1. Error states with retry button
**Files:** `main_navigation_screen.dart`, `cases_page.dart`, `case_detail_page.dart`, `dashboard_page.dart`, `tasks_page.dart`  
**Problem:** Raw red text on error — no retry button, no icon, user is stuck.  
**Fix:** Shared `_buildErrorState(message, onRetry)` helper used in all list/detail screens.

### ✅ 2. Back button / swipe support (PopScope)
**Files:** `main_navigation_screen.dart` (`build()` method)  
**Problem:** Android back button and iOS swipe-back do nothing because navigation is manual string-based.  
**Fix:** Wrap root Scaffold in `PopScope`, call `_navigateTo(_previousStep)` on back press for non-dashboard steps.

### ✅ 3. Status labels — human-readable
**Files:** `main_navigation_screen.dart`, `tasks_page.dart`, `dashboard_page.dart`  
**Problem:** Raw API strings like `DOCTOR_REVIEW`, `REQUEST_CLOSE`, `PLAN_ISSUED` shown to users.  
**Fix:** `_statusLabel()` helper maps them to friendly text ("Awaiting Review", "Closure Req.", "Plan Issued").

### ⬜ 4. Loading states — shimmer skeleton (future)
**Files:** All list pages  
**Problem:** Full-screen spinner blocks content structure.  
**Note:** Requires adding `shimmer` package — deferred to separate PR.

### ⬜ 5. Assessment page progress indicator (future)
**Files:** `assessment_page.dart`  
**Problem:** Very long scroll with no sense of progress.  
**Note:** Deferred — requires larger structural change.

---

## 🟡 Medium Impact

### ✅ 6. Improved empty states in cases and tasks pages
**Files:** `cases_page.dart`, `tasks_page.dart`  
**Problem:** Plain "No cases found." text — no icon, no helpful guidance.  
**Fix:** Shared `_buildEmptyState(icon, message, subtitle)` widget with icon + text.

### ✅ 7. Intake photo picker — camera + gallery
**Files:** `intake_page.dart`, `main_navigation_screen.dart`  
**Problem:** Tapping photo always opens camera only — no gallery option.  
**Fix:** Show bottom sheet with "Take Photo" / "Choose from Gallery" options.

### ✅ 8. Dashboard Patients stat card — make tappable
**Files:** `dashboard_page.dart`  
**Problem:** Tasks card is tappable (→ Tasks tab), Patients card is not — inconsistent.  
**Fix:** Wrap Patients card in GestureDetector → navigate to Cases tab (tab index 2).

### ✅ 9. Haptic feedback on key interactions
**Files:** `assessment_page.dart`, `main_navigation_screen.dart`  
**Problem:** No tactile feedback on card toggles or form submissions.  
**Fix:** `HapticFeedback.lightImpact()` on SINBAD card taps; `HapticFeedback.mediumImpact()` on submit buttons.

### ✅ 10. SINBAD high-risk dialog — more context
**Files:** `assessment_page.dart`  
**Problem:** Dialog shows one line: "Referral recommended." — no actionable guidance.  
**Fix:** Expanded dialog with SINBAD score, what it means, and next-step actions.

---

## 🟢 Low Impact / Polish (Future)

### ⬜ 11. Pull username from auth session (profile_page.dart)
Currently hardcoded "Nurse Ananya Sharma".

### ⬜ 12. Role-aware dashboard title (dashboard_page.dart)
Hardcoded "AI DFU - Midwife" — should read from user role.

### ⬜ 13. Centralize color constants
`Colors.blue.shade600`, `Colors.red.shade600` scattered across files — create `AppColors` class.

---

## Architecture Note
All app state lives in one `_MainNavigationScreenState` (300+ variables). Every `setState()` rebuilds the entire tree. Medium-term, split into scoped Riverpod/Provider notifiers per feature for performance on mid-range devices.
