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

## 📈 Current Status: **Phase 3 Complete - Role Dashboards Configured**

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
9. **Testing & Checks:** Zero issues/warnings on `flutter analyze` and widget tests passing 100%.

---

## 🎯 Next Tasks (Phase 4)
- **MQTT Real-Time Location stream:** Wire the driver location publishing streams and MQTT map listeners.
- **Attendance Check-In Events:** Build check-in/check-out scanners/buttons inside the Driver's Passenger Manifest view.
