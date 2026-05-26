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

## 📈 Current Status: **Phase 2.1 Complete - Registration & User Profile Synced**

### Completed Milestones:
1. **Workspace Cleanup (Phase 1):** Successfully purged all Next.js/Web template files and directories.
2. **Flutter Initialization (Phase 1):** Run `flutter create` using org `com.safepick` and project name `safe_pick`.
3. **Strict Color Theme Applied (Phase 1/Pre-Flight):** Configured `app_theme.dart` to strictly enforce the brand guidelines (Gold `#C1942B`, black backgrounds, white text).
4. **User Model (Phase 2):** Designed immutable `UserModel` in [user_model.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/features/auth/data/user_model.dart) with native Firestore `Timestamp` serialization.
5. **Authentication Services (Phase 2 & 2.1):** 
   - Exposes Riverpod streams monitoring authorization state changes.
   - Implemented `signIn(email, password)` and `signOut()`.
   - Coded `getUserRole(uid)` querying Firestore collections.
   - Added `signUp({required email, required password, required name, required phone, required role})` which creates a Firebase Auth user credential, translates it to a `UserModel` with `'active'` status and native timestamp date, and writes it directly to the `/users/{uid}` collection.
6. **Branded Login & Sign-Up UI Screens (Phase 2 & 2.1):** 
   - Validiated inputs, loading buttons, and snackbars.
   - Integrated [sign_up_screen.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/features/auth/presentation/sign_up_screen.dart) for registering Parents and Drivers.
   - Appended routing buttons at the bottom of the screens to allow swapping between Sign In and Sign Up structures.
7. **Auth Gate Router (Phase 2):** Programmed [auth_gate.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/features/auth/presentation/auth_gate.dart) which routes signed-out users to `LoginScreen`, and queries and welcomes authenticated users depending on their retrieved Firestore user role.
8. **Testing Checks:** Clean analysis (`flutter analyze` - No issues found) and automated unit test coverage passing 100%.

---

## 🎯 Next Tasks (Phase 3)
- **Dashboard Interfaces:** Build the layout for Driver Dashboard (van control panel, passenger manifest list) and Parent Dashboard (live tracking details, student status cards).
- **MQTT/EMQX Tracking Hooks:** Connect MQTT listeners inside UI structures for active locations updates.
- **Attendance Logging:** Implement check-in/check-out buttons writing directly to the `attendance` Firestore sub-collections.
