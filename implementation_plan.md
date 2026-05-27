# Refactor Core Application Lifecycle

This implementation plan covers the massive refactor requested for the SafePick application lifecycle across the 5 domains. Many features from the previous sessions (QR Scanner logic, Map View Placeholders, and Edit Button constraints) are already in place, but we need to unify the data models, fix the sorting, and implement the critical "End Trip Cleanup" auto-updates.

## User Review Required

- **Model Naming Conventions:** I will rename `lastAttendanceStatus` to `currentStatus` on the `StudentModel` to strictly align with the prompt. 
- **Trip Types:** I will standardize all trip types across the app to `Morning` and `Afternoon` (replacing older usages of `pickup`/`dropoff`). This might require existing trips in Firestore to be re-created or migrated, as previous strings were different.

## Proposed Changes

### 1. Data Models (Domain 1)

#### [MODIFY] [student_model.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/features/students/data/student_model.dart)
- Rename `lastAttendanceStatus` to `currentStatus`.
- Update `fromJson` and `toJson` to use the key `current_status` (instead of `last_attendance_status`).

#### [MODIFY] [trip_model.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/features/trips/data/trip_model.dart)
- Update documentation and logic to strictly enforce `Morning` and `Afternoon` enum/strings instead of `pickup` / `dropoff`.

### 2. Global State Updates (Renaming)

#### [MODIFY] Several UI and Service Files
- Since we are renaming `lastAttendanceStatus` to `currentStatus`, I will update all references in:
  - `lib/features/trips/data/trip_service.dart`
  - `lib/features/trips/presentation/trip_detail_screen.dart`
  - `lib/features/students/presentation/parent_dashboard.dart`
  - Any other components querying or updating this field.

### 3. Driver Dashboard & Sorting Logic (Domain 2)

#### [MODIFY] [driver_dashboard.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/features/trips/presentation/driver_dashboard.dart)
- Adjust the trip sorting logic. 
- **Sorting Rule:** First sort by whether the trip was completed today (Lazy Evaluation - moves to bottom). For remaining pending trips, sort so that `Morning` trips appear before `Afternoon` trips.
- Ensure the UI badge dynamically reads "READY", "ACTIVE", or "COMPLETED".

### 4. Active Trip State Machine - End Trip Cleanup (Domain 4)

#### [MODIFY] [trip_service.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/features/trips/data/trip_service.dart)
- Update the `endDailySession` method.
- When ending the session, query the `attendance` sub-collection for this session.
- Identify any students currently stuck `In Van`.
- Update their `current_status` in both the `daily_sessions/{id}/attendance` and the global `students` collection.
  - If `tripType == 'Morning'`, update `In Van` -> `At School`.
  - If `tripType == 'Afternoon'`, update `In Van` -> `At Home`.
- Students `At Home` are ignored/left at home.

### 5. Domains Already Covered (Verified)
- **Pre-Trip UI (Domain 3):** The Edit Button correctly uses `showEdit = session == null` and is hidden when the trip is active. The Map Placeholder is present.
- **Parent Dashboard (Domain 5):** Uses a real-time stream `parentStudentsProvider` that updates immediately when the child's status changes. (Will just update to use the new `currentStatus` field).

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no issues exist after the refactor.
- Run `flutter test` (if applicable) to ensure models parse correctly.

### Manual Verification
- Driver Dashboard correctly sorts Morning -> Afternoon.
- Start a Morning trip, scan a student `In Van`, leave them there, and click "End Trip". Verify the student is updated to `At School`.
- Start an Afternoon trip, scan a student `In Van`, click "End Trip". Verify they update to `At Home`.
- Parent Dashboard correctly shows the real-time `currentStatus`.
