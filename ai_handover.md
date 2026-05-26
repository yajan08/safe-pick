# SafePick AI Handover File

This living document keeps track of the project's current state, codebase architecture, database schema, and feature progress. Keep this file updated at the end of every development phase.

---

## 🚀 Project Overview
**SafePick** is a production-ready mobile application designed to track school vans and manage student check-in/check-out events. It facilitates real-time communication and location updates to build trust between parents, transport drivers, and school administrations.

---

## 🛠️ Tech Stack
- **Framework:** Flutter (Dart)
- **State Management:** Flutter Riverpod (`flutter_riverpod` - Upgraded to v3)
- **Backend:** Firebase (Authentication & Cloud Firestore)
- **Real-Time Communication:** EMQX / MQTT (Client integrated)
- **Mapping & Location:** Google Maps API & Geolocator (integrated)

---

## 🗄️ Firestore Database Schema
The database uses a flattened Firestore NoSQL hierarchy for performance, offline scalability, and simplicity.

### `users`
- **Path:** `/users/{uid}`
- **Fields:**
  - `uid`: String (Firebase Auth UID)
  - `role`: String (`parent` | `driver` | `admin`)
  - `name`: String
  - `phone`: String
  - `status`: String (`active` | `suspended` | `pending`)
  - `created_at`: Timestamp (Firestore Native)
  - `managed_school_id`: String? (nullable, used when `role == 'admin'` to link to a school)

### `metadata`
- **Path:** `/metadata/counters`
- **Fields:**
  - `student_count`: Integer (auto-incrementing counter used by `generateSequentialStudentId` to produce IDs like SP1001, SP1002, etc.)

### `schools`
- **Path:** `/schools/{school_id}`
- **Fields:**
  - `school_id`: String (Document ID)
  - `name`: String
  - `address`: String
  - `location`: GeoPoint (Latitude & Longitude)
  - `status`: String (`active` | `inactive`)

### `students`
- **Path:** `/students/{student_id}`
- **Fields:**
  - `student_id`: String (Document ID)
  - `parent_uid`: String (UID referencing `/users/{uid}`)
  - `school_id`: String (ID referencing `/schools/{school_id}`)
  - `name`: String
  - `grade`: String
  - `home_location`: GeoPoint (Latitude & Longitude)
  - `status`: String (`active` | `inactive`)
  - `stats`: Map (e.g. `total_trips`, `attendance_rate`)

### `trips`
- **Path:** `/trips/{trip_id}`
- **Fields:**
  - `trip_id`: String (Document ID)
  - `driver_uid`: String (UID referencing `/users/{uid}`)
  - `trip_name`: String (e.g., "Route A Morning")
  - `trip_type`: String (`pickup` | `dropoff`)
  - `school_ids`: Array of Strings (IDs of schools visited on this route)
  - `status`: String (`active` | `inactive` | `completed`)
  - `estimated_duration`: String (estimated travel duration)

#### `trips/{trip_id}/trip_manifest`
- **Path:** `/trips/{trip_id}/trip_manifest/{student_id}`
- **Fields:**
  - `student_id`: String (Document ID)
  - `school_id`: String
  - `name`: String
  - `stop_order`: Integer
  - `status`: String (`active` | `absent` | `skipped`)

### `daily_sessions`
- **Path:** `/daily_sessions/{session_id}`
- **Fields:**
  - `session_id`: String (Document ID - e.g., `trip_id_YYYY_MM_DD`)
  - `trip_id`: String (References `/trips/{trip_id}`)
  - `driver_uid`: String (References `/users/{uid}`)
  - `date`: String (Format: `YYYY-MM-DD`)
  - `status`: String (`scheduled` | `ongoing` | `completed` | `cancelled`)
  - `mqtt_topic_id`: String (MQTT topic for real-time tracking streams)

#### `daily_sessions/{session_id}/attendance`
- **Path:** `/daily_sessions/{session_id}/attendance/{student_id}`
- **Fields:**
  - `student_id`: String (Document ID)
  - `status`: String (`picked_up` | `dropped_off` | `absent` | `pending`)
  - `timestamp`: Timestamp

---

## 📈 Current Status: **Phase 15 Complete - Live GPS Telemetry Pipeline via Secure MQTT**

### Completed Milestones:
1. **Workspace Cleanup (Phase 1):** Purged Next.js legacy templates.
2. **Flutter Setup (Phase 1):** Initialized standard Flutter package structure.
3. **Core Premium Dark Theme (Phase 1):** Standardized color scheme (Gold `#C1942B`, black backgrounds, white text).
4. **Auth Layer (Phase 2 & 2.1):** 
   - Created `UserModel`.
   - Coded `AuthService` handling sign-in, sign-up, sign-out, and firestore profile document creation.
   - Built custom validated `LoginScreen` and `SignUpScreen` UIs.
5. **Data Models (Phase 3):**
   - Created `StudentModel` in [student_model.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/features/students/data/student_model.dart) matching students collection.
   - Created `TripModel` in [trip_model.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/features/trips/data/trip_model.dart) matching trips collection.
6. **Parent Dashboard (Phase 3):**
   - Coded [parent_dashboard.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/features/students/presentation/parent_dashboard.dart) using Riverpod `parentStudentsProvider` to listen to real-time updates where `parent_uid == currentUser.uid`.
   - Renders child cards detailing grade, status, and expandable stats (attendance rate, trip totals).
7. **Driver Dashboard (Phase 3):**
   - Coded [driver_dashboard.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/features/trips/presentation/driver_dashboard.dart) using Riverpod `driverTripsProvider` to track assigned routes where `driver_uid == currentUser.uid`.
   - Renders trip card detailing route name, type (pickup/dropoff), status, duration, and route initiation controls.
8. **AuthGate Router Upgrade (Phase 3):**
   - Modified [auth_gate.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/features/auth/presentation/auth_gate.dart) to route users directly to their corresponding dashboards depending on their Firestore user profile role.
9. **Trip Service & Manifest (Phase 4):**
   - Created `TripManifestModel` schema mirroring the `trip_manifest` subcollection under `trips/{trip_id}/trip_manifest`.
   - Extended `TripService` with methods to stream manifest data sorted by stop order, and `startDailySession(tripId)` which instantiates a daily session document with `in_progress` status and a unique `mqtt_topic_id`.
   - Built `TripDetailScreen` displaying metadata, a state-driven "Start Trip" button, and list cards for students on the manifest.
   - Connected `DriverDashboard` to `TripDetailScreen` for both card-tap and action button actions.
10. **Data CRUD & Roster Allocation (Phase 5):**
    - Added styled log-out confirmation `AlertDialog` flows to both `ParentDashboard` and `DriverDashboard`.
    - Implemented `AddStudentScreen` with form validation, FAB hooks, and Geolocator GPS capturing.
    - Implemented `CreateTripScreen` with route setup fields and FAB hooks.
    - Programmed student ID-lookup dialog inside `TripDetailScreen` enabling drivers to query and add students to the trip's manifest subcollection.
11. **Advanced Dashboards & Workflow Polish (Phase 6):**
    - Converted app to Premium Light Mode (off-white backgrounds, dark typography).
    - Added `flutter_animate` for elegant entry animations across all screens.
    - Updated `StudentModel` with `school_name`, `note`, and `last_attendance_status` fields.
    - Updated `TripModel` with `approx_start_time` field.
    - Rebuilt `ParentDashboard` with child selector dropdown, profile card, status card, ETA card, and map placeholder.
    - Rebuilt `DriverDashboard` with amber Top Summary Tile (Total/Pending trips).
    - Updated `CreateTripScreen` with TimePicker, student search by ID, roster state management, and batch manifest writing.
    - Updated `AddStudentScreen` with edit capability and new fields.
12. **Parent CRUD Polish, Sequential IDs, & Admin Prep (Phase 7):**
    - Added `managed_school_id` (nullable) to `UserModel` for future admin role support.
    - Implemented Firestore Transaction-based sequential ID generator (`generateSequentialStudentId`) using `metadata/counters` document. IDs follow the format `SPXXXX` (e.g., SP1001, SP1002).
    - Updated `AddStudentScreen` to use the sequential ID generator instead of random strings.
    - Displayed `student_id` prominently in `ParentDashboard` profile card as a styled chip.
    - Added "Remove Student" button with confirmation dialog implementing soft-delete (sets `status` to `inactive`).
    - Updated Firestore query in `parentStudentsProvider` to filter only `status == 'active'` students.
    - Updated `CreateTripScreen` search hint to reflect new SPXXXX format.
13. **Parent Profile, QR Codes, & Dashboard Cleanup (Phase 8):**
    - Added `qr_flutter` package for QR code generation.
    - Created [parent_profile_screen.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/features/profile/presentation/parent_profile_screen.dart) — dedicated hub for account management with user info card, child list, sign out, and "Add New Child" button.
    - Created [student_detail_screen.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/features/profile/presentation/student_detail_screen.dart) — shows full student details with a visual QR code (`QrImageView`) encoding the `student_id` (e.g., `SP1005`). Includes Edit and Remove actions.
    - Cleaned up `ParentDashboard`: removed FAB, removed sign out and remove button. Added a Profile avatar icon in AppBar that navigates to `ParentProfileScreen`.
    - Dashboard now strictly focuses on child status monitoring (selector, status card, ETA card, map placeholder).
14. **Registration Overhaul & Driver UI Polish (Phase 9):**
    - Updated `UserModel` and `AuthService` to include `gender` and `vehicleNumber` (nullable, for drivers).
    - Overhauled `SignUpScreen` with dynamic form fields (Vehicle Number appears when Driver role is selected).
    - Redesigned `DriverDashboard` with high-contrast summary cards ("Total Trips", "Pending Today") and accessible trip list items.
    - Restructured `TripDetailScreen` into a clear hierarchy: Status Banner, Details & Edit, Map Placeholder, Target Schools Summary (dynamically derived from manifest), and a staggered animated Student Roster List with colored status chips.
    - Added massive high-contrast FAB for QR scanning when trips are in progress.
15. **Trip Execution State Machine & QR Logging (Phase 10):**
    - Created `DailySessionModel` to support pause/resume/end states.
    - Created `AttendanceModel` nested within sessions for detailed boarding/alighting timestamps.
    - Created `StudentRideLogModel` for a Fan-out write to `students/{student_id}/ride_history`.
    - Updated `TripService` to manage session state (`pauseDailySession`, `resumeDailySession`, `endDailySession`).
    - Implemented `processQrScan` with Firestore Batch Writes to synchronously update attendance, manifest status, and student ride history.
    - Overhauled `TripDetailScreen` action buttons to dynamically reflect and control the active session state.
    - Integrated `mobile_scanner` and built `QRScannerScreen` accessible via the massive FAB on active trips.
    - Added `TripHistoryScreen` accessible from `DriverDashboard` to view completed trips.
17. **Reusable Trip Templates & UI Polish (Phase 11):**
    - Transitioned Trip model to act as reusable templates. `TripService` no longer mutates the master trip or manifest during daily runs.
    - Added `sessionAttendanceProvider` to stream active session attendance seamlessly while preserving master manifest state.
    - Implemented a "More Options" manual override in `TripDetailScreen` roster to explicitly mark students Absent or Manually Onboard without QR scans.
    - Integrated static brand logo (`light_logo.jpg`) across `LoginScreen`, `SignUpScreen`, and main AppBars, stripping out text titles for a minimalist look.
    - Hardened `AuthGate` to catch missing profile errors and automatically log out the user with a graceful SnackBar message to prevent infinite loops.
18. **Offline-First QR Scanner & Network Sync Queue (Phase 12):**
    - Added `connectivity_plus` and `sqflite` for offline-resilient operations.
    - Implemented `SyncQueueService` using a local SQLite database (`sync_queue.db`) to queue offline scans. Sqflite was chosen for its simple setup, zero code-gen overhead, and robust auto-incrementing ID capabilities.
    - Added a background sync engine that listens to `connectivity_plus` changes and flushes pending scans to Firestore (`processQrScan`) when online.
    - Upgraded `QRScannerScreen` to instantly queue scans locally, providing haptic feedback and capturing GPS coordinates, without waiting for slow or unavailable network responses. The UI resets within 1 second for rapid scanning.
19. **App-Wide UI/UX Refinement & Production Stabilization (Phase 13):**
    - Integrated `shimmer` package for elegant skeleton loading states across all dashboards and profile screens.
    - Standardized `AuthGate` to gracefully display an "Offline Mode" prompt if the user boots without internet instead of logging them out aggressively.
    - Upgraded core data models (`UserModel`, `StudentModel`, `TripModel`) with robust null-safety defaults in `fromJson` constructors to prevent crashes from bad data.
    - Polished form inputs across the app with `.trim()` on text extraction. 
    - Verified large touch targets and confirmation prompts for driver manual roster overrides.
20. **Testing & Checks:** Zero issues/warnings on `flutter analyze`.
21. **SVG Branding, Driver Profile, & Infinite Trips (Phase 14):**
    - Transitioned branding to SVG (`flutter_svg`) using `assets/images/logo.svg` across Auth, Dashboards, and a new dedicated `SplashScreen` with Hero/FadeIn animations.
    - Added `DriverProfileScreen` for full CRUD capabilities over Name, Phone, Gender, and Vehicle Number, integrated to Firestore.
    - Upgraded `TripService` and `TripDetailScreen` to support "Infinite Trips" (allowing drivers to click "REDO / REOPEN TRIP" on completed sessions to convert them back to `in_progress`).
    - Finalized End-to-End QR Sync fan-out: Scans/manual overrides now instantly update the global student record (`last_attendance_status`) so parents see real-time updates (e.g. "In Van", "At Home").
    - Verified UX minimum button heights (56.0) across auth flows and primary actions.

22. **Live GPS Telemetry Pipeline via Secure MQTT (Phase 15):**
    - Integrated `mqtt_client` and `geolocator` packages.
    - Created `MqttService` connecting securely to EMQX Serverless (`x6ee8611.ala.asia-southeast1.emqxsl.com:8883`) using a root CA loaded from `assets/certs/emqxsl-ca.crt`.
    - **Driver Pipeline:** Drivers now automatically broadcast their GPS coordinates (`latitude`, `longitude`, `speed`) every 3s (with a 5m filter) to `safepick/trips/{session_id}/telemetry` whenever a trip is "In Progress".
    - **Parent Pipeline:** Parents automatically connect to EMQX and subscribe to the active telemetry topic of their child when the child is marked "In Van". The coordinates and speed are streamed and displayed directly on the `ParentDashboard` Map Placeholder card.

---

## 🎯 Next Tasks
- **Map Visualizations:** Replace the text-based coordinate display on `ParentDashboard` with an actual Google Maps widget plotting the van's marker.
- **Admin Dashboard:** Build school admin role with dashboard filtered by `managed_school_id`.
