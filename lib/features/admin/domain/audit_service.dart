import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_service.dart';
import '../../../firebase_options.dart';
import '../../trips/data/daily_session_model.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

/// Immutable record of a single auditable event inside the SafePick system.
@immutable
class AuditLogModel {
  final String logId;
  final String action; // e.g. 'STATUS_CHANGE', 'TRIP_START', 'USER_EDITED'
  final String targetId;
  final String targetType; // 'student' | 'driver' | 'trip' | 'user'
  final String performedBy; // uid of the actor
  final DateTime timestamp;
  final Map<String, dynamic> details;

  const AuditLogModel({
    required this.logId,
    required this.action,
    required this.targetId,
    required this.targetType,
    required this.performedBy,
    required this.timestamp,
    this.details = const {},
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseTimestamp(dynamic raw) {
      if (raw == null) return DateTime.now();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      try {
        return (raw as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return AuditLogModel(
      logId: id,
      action: json['action'] as String? ?? '',
      targetId: json['target_id'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      performedBy: json['performed_by'] as String? ?? 'system',
      timestamp: parseTimestamp(json['timestamp']),
      details: json['details'] as Map<String, dynamic>? ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'target_id': targetId,
      'target_type': targetType,
      'performed_by': performedBy,
      'timestamp': Timestamp.fromDate(timestamp),
      'details': details,
    };
  }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Centralised audit service used by the admin portal.
///
/// Every mutation method atomically writes the data change **and** a
/// corresponding audit log entry inside a single Firestore batch so neither
/// can succeed without the other.
class AuditService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AuditService(this._firestore, this._auth);

  // ── helpers ──────────────────────────────────────────────────────────────

  String get _currentUid => _auth.currentUser?.uid ?? 'system';

  // ── generic audit log writer ─────────────────────────────────────────────

  /// Writes a single audit-log document to the `audit_logs` collection.
  ///
  /// Prefer the higher-level methods below when you also need to mutate
  /// domain data; they wrap the mutation + log in a single batch.
  Future<void> log({
    required String action,
    required String targetId,
    required String targetType,
    Map<String, dynamic> details = const {},
  }) async {
    final batch = _firestore.batch();
    final logRef = _firestore.collection('audit_logs').doc();

    final entry = AuditLogModel(
      logId: logRef.id,
      action: action,
      targetId: targetId,
      targetType: targetType,
      performedBy: _currentUid,
      timestamp: DateTime.now(),
      details: details,
    );

    batch.set(logRef, entry.toJson());
    await batch.commit();
  }

  // ── user status toggle ───────────────────────────────────────────────────

  /// Toggles a user between `active` ↔ `suspended` and records the change.
  Future<void> toggleUserStatus(String uid, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';

    final batch = _firestore.batch();

    // 1. Update the user document
    final userRef = _firestore.collection('users').doc(uid);
    batch.update(userRef, {'status': newStatus});

    // 2. Write the audit log
    final logRef = _firestore.collection('audit_logs').doc();
    final entry = AuditLogModel(
      logId: logRef.id,
      action: 'STATUS_CHANGE',
      targetId: uid,
      targetType: 'user',
      performedBy: _currentUid,
      timestamp: DateTime.now(),
      details: {'previous_status': currentStatus, 'new_status': newStatus},
    );
    batch.set(logRef, entry.toJson());

    await batch.commit();
  }

  // ── user detail edits ────────────────────────────────────────────────────

  /// Applies arbitrary field updates to a user document with an audit trail.
  Future<void> updateUserDetails(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    final batch = _firestore.batch();

    final userRef = _firestore.collection('users').doc(uid);
    batch.update(userRef, updates);

    final logRef = _firestore.collection('audit_logs').doc();
    final entry = AuditLogModel(
      logId: logRef.id,
      action: 'USER_EDITED',
      targetId: uid,
      targetType: 'user',
      performedBy: _currentUid,
      timestamp: DateTime.now(),
      details: {'updated_fields': updates},
    );
    batch.set(logRef, entry.toJson());

    await batch.commit();
  }

  // ── student detail edits ─────────────────────────────────────────────────

  /// Applies arbitrary field updates to a student document with an audit trail.
  Future<void> updateStudentDetails(
    String studentId,
    Map<String, dynamic> updates,
  ) async {
    final batch = _firestore.batch();

    final studentRef = _firestore.collection('students').doc(studentId);
    batch.update(studentRef, updates);

    final logRef = _firestore.collection('audit_logs').doc();
    final entry = AuditLogModel(
      logId: logRef.id,
      action: 'STUDENT_EDITED',
      targetId: studentId,
      targetType: 'student',
      performedBy: _currentUid,
      timestamp: DateTime.now(),
      details: {'updated_fields': updates},
    );
    batch.set(logRef, entry.toJson());

    await batch.commit();
  }

  // ── driver session history ───────────────────────────────────────────────

  /// Returns up to 50 most-recent daily sessions for the given driver,
  /// ordered by date descending.
  Future<List<DailySessionModel>> getDriverSessions(String driverUid) async {
    final snapshot = await _firestore
        .collection('daily_sessions')
        .where('driver_uid', isEqualTo: driverUid)
        .orderBy('date', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => DailySessionModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// Registers a new driver from an Admin session using a secondary Firebase app instance
  /// to avoid signing out the current Admin.
  Future<void> registerDriver({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String gender,
    required String vehicleNumber,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      final appName = 'DriverCreationApp_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final secondaryFirestore = FirebaseFirestore.instanceFor(app: secondaryApp);

      // 1. Create user in Firebase Auth
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // 2. Create the user document in Firestore users collection
      final userRef = secondaryFirestore.collection('users').doc(uid);
      
      final normalizedVehicleNumber = vehicleNumber.trim().toUpperCase();
      final vehicleNumbers = normalizedVehicleNumber.isEmpty
          ? const <String>[]
          : [normalizedVehicleNumber];

      final userDoc = {
        'uid': uid,
        'role': 'driver',
        'name': name.trim(),
        'phone': phone.trim(),
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
        'gender': gender,
        'vehicle_number': normalizedVehicleNumber,
        'vehicle_numbers': vehicleNumbers,
      };
      await userRef.set(userDoc);

      // 3. Write the audit log using the primary Firestore instance (authenticated as the Admin)
      final logRef = _firestore.collection('audit_logs').doc();
      final entry = AuditLogModel(
        logId: logRef.id,
        action: 'DRIVER_CREATED',
        targetId: uid,
        targetType: 'driver',
        performedBy: _currentUid,
        timestamp: DateTime.now(),
        details: {
          'email': email.trim(),
          'name': name.trim(),
          'phone': phone.trim(),
          'vehicle_number': normalizedVehicleNumber,
        },
      );
      await _firestore.collection('audit_logs').doc(logRef.id).set(entry.toJson());

    } on FirebaseAuthException catch (e) {
      String message = 'Failed to register driver.';
      if (e.code == 'email-already-in-use') {
        message = 'This email address is already registered.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak. Must be at least 6 characters.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is badly formatted.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/password sign-in is not enabled for this project.';
      } else if (e.message != null) {
        message = e.message!;
      }
      throw message;
    } catch (e) {
      throw 'An error occurred during driver creation: $e';
    } finally {
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Riverpod provider for [AuditService].
final auditServiceProvider = Provider<AuditService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return AuditService(firestore, auth);
});
