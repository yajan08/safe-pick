import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import 'trip_manifest_model.dart';
import '../../students/data/student_ride_log_model.dart';
import 'daily_session_model.dart';

/// Riverpod provider for the [TripService] instance.
final tripServiceProvider = Provider<TripService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return TripService(firestore, auth);
});

/// Riverpod StreamProvider family that streams a trip's manifest ordered by stop_order.
final tripManifestProvider = StreamProvider.family<List<TripManifestModel>, String>((ref, tripId) {
  final tripService = ref.watch(tripServiceProvider);
  return tripService.streamTripManifest(tripId);
});

/// Riverpod StreamProvider family that streams a daily session by trip ID.
final activeSessionProvider = StreamProvider.family<DailySessionModel?, String>((ref, tripId) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  
  if (auth.currentUser == null) return Stream.value(null);

  final now = DateTime.now();
  final dateString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

  return firestore
      .collection('daily_sessions')
      .where('trip_id', isEqualTo: tripId)
      .where('driver_uid', isEqualTo: auth.currentUser!.uid)
      .where('date', isEqualTo: dateString)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        // Assume the most recent one for today if multiple exist
        final doc = snapshot.docs.first;
        return DailySessionModel.fromJson(doc.data(), doc.id);
      });
});

/// Riverpod StreamProvider family that streams a daily session's attendance.
final sessionAttendanceProvider = StreamProvider.family<Map<String, String>, String>((ref, sessionId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('daily_sessions')
      .doc(sessionId)
      .collection('attendance')
      .snapshots()
      .map((snapshot) {
        final Map<String, String> attendance = {};
        for (var doc in snapshot.docs) {
          attendance[doc.id] = doc.data()['status'] as String? ?? 'pending';
        }
        return attendance;
      });
});

/// Service class responsible for Firestore Trip and Manifest operations.
class TripService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TripService(this._firestore, this._auth);

  /// Streams the manifest list for a specific trip, ordered by stop_order.
  Stream<List<TripManifestModel>> streamTripManifest(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('trip_manifest')
        .orderBy('stop_order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TripManifestModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Creates a new document in the daily_sessions collection, starting a trip.
  /// Returns the generated session_id / mqtt_topic_id.
  Future<String> startDailySession(String tripId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User must be authenticated to start a session.';
      }

      // Generate a unique session ID using Firestore doc ID generator
      final docRef = _firestore.collection('daily_sessions').doc();
      final sessionId = docRef.id;

      final now = DateTime.now();
      final dateString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final sessionData = {
        'session_id': sessionId,
        'trip_id': tripId,
        'driver_uid': currentUser.uid,
        'date': dateString,
        'status': 'in_progress',
        'mqtt_topic_id': sessionId,
        'start_time': Timestamp.fromDate(now),
      };

      final batch = _firestore.batch();
      batch.set(docRef, sessionData);

      // Initialize attendance records from manifest, and stamp active_session_id on each student.
      final manifestDocs = await _firestore.collection('trips').doc(tripId).collection('trip_manifest').get();
      for (var manifestDoc in manifestDocs.docs) {
        final studentId = manifestDoc.id;
        final attendanceRef = docRef.collection('attendance').doc(studentId);
        batch.set(attendanceRef, {'status': 'pending'});
        // Fan-out: write active_session_id so parent can subscribe to the MQTT topic.
        batch.update(_firestore.collection('students').doc(studentId), {
          'stats.active_session_id': sessionId,
        });
      }

      await batch.commit();
      return sessionId;
    } catch (e) {
      throw 'Failed to start trip: $e';
    }
  }

  Future<void> pauseDailySession(String sessionId) async {
    await _firestore.collection('daily_sessions').doc(sessionId).update({'status': 'paused'});
  }

  Future<void> resumeDailySession(String sessionId) async {
    await _firestore.collection('daily_sessions').doc(sessionId).update({'status': 'in_progress'});
  }

  Future<void> reopenDailySession(String sessionId) async {
    await _firestore.collection('daily_sessions').doc(sessionId).update({
      'status': 'in_progress',
      'end_time': FieldValue.delete(),
    });
  }

  Future<void> endDailySession(String sessionId, String tripId) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('daily_sessions').doc(sessionId), {
      'status': 'completed',
      'end_time': Timestamp.fromDate(DateTime.now()),
    });
    // Clear active_session_id from all manifest students.
    final manifestDocs = await _firestore.collection('trips').doc(tripId).collection('trip_manifest').get();
    for (var doc in manifestDocs.docs) {
      batch.update(_firestore.collection('students').doc(doc.id), {
        'stats.active_session_id': FieldValue.delete(),
      });
    }
    await batch.commit();
  }

  /// Process a QR Scan event using Firestore Batch Writes (Fan-out)
  /// Optionally accepts an overrideTimestamp for offline sync processing.
  Future<void> processQrScan(String studentId, String sessionId, {DateTime? overrideTimestamp}) async {
    final sessionRef = _firestore.collection('daily_sessions').doc(sessionId);
    final attendanceRef = sessionRef.collection('attendance').doc(studentId);
    
    // We need some trip info to populate the ride log
    final sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) throw 'Active trip session not found.';
    final tripId = sessionSnap.data()?['trip_id'] as String? ?? '';
    final dateString = sessionSnap.data()?['date'] as String? ?? '';
    final driverUid = sessionSnap.data()?['driver_uid'] as String? ?? '';

    // Fetch trip details
    final tripSnap = await _firestore.collection('trips').doc(tripId).get();
    final tripName = tripSnap.data()?['trip_name'] as String? ?? 'Unknown Trip';

    // Fetch driver details
    final driverSnap = await _firestore.collection('users').doc(driverUid).get();
    final driverName = driverSnap.data()?['name'] as String? ?? 'Unknown Driver';
    final vehicleNumber = driverSnap.data()?['vehicle_number'] as String? ?? '';

    // Fetch current attendance
    final attendanceSnap = await attendanceRef.get();
    if (!attendanceSnap.exists) {
      throw 'Student $studentId is not on this trip\'s manifest.';
    }

    final currentStatus = attendanceSnap.data()?['status'] as String? ?? 'pending';
    final rideHistoryRef = _firestore.collection('students').doc(studentId).collection('ride_history').doc(sessionId);

    final batch = _firestore.batch();
    final now = Timestamp.fromDate(overrideTimestamp ?? DateTime.now());

    if (currentStatus == 'pending') {
      // Boarding
      batch.update(attendanceRef, {
        'status': 'onboarded',
        'boarded_at': now,
      });

      // Create ride history entry
      final rideLog = StudentRideLogModel(
        logId: sessionId,
        sessionId: sessionId,
        tripName: tripName,
        driverName: driverName,
        vehicleNumber: vehicleNumber,
        date: dateString,
        boardedAt: now.toDate(),
        status: 'onboarded',
      );
      batch.set(rideHistoryRef, rideLog.toJson());
      
      // Sync to global student record
      batch.update(_firestore.collection('students').doc(studentId), {
        'last_attendance_status': 'In Van',
      });
    } else if (currentStatus == 'onboarded') {
      // Alighting
      batch.update(attendanceRef, {
        'status': 'dropped',
        'alighted_at': now,
      });

      // Update ride history entry
      batch.update(rideHistoryRef, {
        'status': 'dropped',
        'alighted_at': now,
      });

      // Sync to global student record
      batch.update(_firestore.collection('students').doc(studentId), {
        'last_attendance_status': 'At Home',
      });
    } else {
      throw 'Student has already been dropped off or is marked absent.';
    }

    await batch.commit();
  }

  /// Manually override attendance status (e.g. Absent, Manual Onboard)
  Future<void> manualAttendanceOverride(String sessionId, String studentId, String status) async {
    final sessionRef = _firestore.collection('daily_sessions').doc(sessionId);
    final attendanceRef = sessionRef.collection('attendance').doc(studentId);
    
    final sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) throw 'Active trip session not found.';

    final tripId = sessionSnap.data()?['trip_id'] as String? ?? '';
    final dateString = sessionSnap.data()?['date'] as String? ?? '';
    final driverUid = sessionSnap.data()?['driver_uid'] as String? ?? '';

    // Fetch details for ride log
    final tripSnap = await _firestore.collection('trips').doc(tripId).get();
    final tripName = tripSnap.data()?['trip_name'] as String? ?? 'Unknown Trip';

    final driverSnap = await _firestore.collection('users').doc(driverUid).get();
    final driverName = driverSnap.data()?['name'] as String? ?? 'Unknown Driver';
    final vehicleNumber = driverSnap.data()?['vehicle_number'] as String? ?? '';

    final batch = _firestore.batch();
    final now = Timestamp.fromDate(DateTime.now());
    
    final updateData = <String, dynamic>{
      'status': status,
    };
    if (status == 'onboarded') {
      updateData['boarded_at'] = now;
    } else if (status == 'dropped') {
      updateData['alighted_at'] = now;
    }

    batch.update(attendanceRef, updateData);

    // Ride History
    final rideHistoryRef = _firestore.collection('students').doc(studentId).collection('ride_history').doc(sessionId);
    
    final rideLog = StudentRideLogModel(
      logId: sessionId,
      sessionId: sessionId,
      tripName: tripName,
      driverName: driverName,
      vehicleNumber: vehicleNumber,
      date: dateString,
      boardedAt: status == 'onboarded' ? now.toDate() : null,
      status: status,
    );
    
    if (status == 'onboarded' || status == 'absent') {
      // First time log creation
      batch.set(rideHistoryRef, rideLog.toJson());
    } else {
      // Just update existing
      batch.update(rideHistoryRef, updateData);
    }

    // Sync to global student record
    String globalStatus = 'Unknown';
    if (status == 'onboarded') globalStatus = 'In Van';
    if (status == 'dropped') globalStatus = 'At Home';
    if (status == 'absent') globalStatus = 'Absent';
    if (status == 'pending') globalStatus = 'Pending';
    
    batch.update(_firestore.collection('students').doc(studentId), {
      'last_attendance_status': globalStatus,
    });

    await batch.commit();
  }
}
