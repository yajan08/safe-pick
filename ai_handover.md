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

## 🗄️ Firestore Database Schema (Reference Only)
The database uses a flattened Firestore NoSQL hierarchy for performance, offline scalability, and simplicity.

### `users`
- **Path:** `/users/{uid}`
- **Fields:**
  - `uid`: String (Firebase Auth UID)
  - `role`: String (`parent` | `driver` | `admin`)
  - `name`: String
  - `phone`: String
  - `status`: String (`active` | `suspended` | `pending`)
  - `created_at`: Timestamp

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

## 📈 Current Status: **Phase 1 Complete (System Checked & Ready for Phase 2)**

### Completed Milestones:
1. **Workspace Cleanup:** Successfully purged all legacy Next.js/Web template files and directories.
2. **Flutter Initialization:** Run `flutter create` using org `com.safepick` and project name `safe_pick`.
3. **Strict Color Theme Applied:** Configured [app_theme.dart](file:///c:/Users/ASUS/Desktop/safe-pick/lib/core/theme/app_theme.dart) to strictly enforce the brand guidelines:
   - Primary Accent: Premium dark golden/amber (`#C1942B`)
   - Backgrounds/Surfaces: Black (`#000000` / `#121212`)
   - Text/Icons: White (`#FFFFFF` / `#B3B3B3`)
4. **Folder Structure Audit:** Verified that directories for core features (`theme`, `services`, `constants`, `widgets`) and modular feature directories (`auth`, `trips`, `students`, `attendance`, `profile`) are perfectly aligned.
5. **KGP Warning Resolved:** Upgraded packages and dependencies via `flutter pub upgrade --major-versions` to verify Kotlin Gradle Plugin compliance for all packages.
6. **Static Verification:** Completed code audit using `flutter analyze` returning **"No issues found!"** with all lints (including `avoid_print` inside MQTT services) fully resolved.

---

## 🎯 Next Tasks (Phase 2)
- **User Model Schema:** Add the structured `UserModel` matching `{uid, role, name, phone, status, created_at}`.
- **Firebase Auth Service:** Connect FirebaseAuth methods and Riverpod streams.
- **Role-based Authentication Routing:** Implement `AuthGate` routing check (logged out -> LoginScreen; logged in -> verify role check scaffold).
- **Branded Login UI:** Design high-fidelity, validated Login form using the premium black & gold design system.
