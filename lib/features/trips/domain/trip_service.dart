import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../data/trip_manifest_model.dart';
import '../../students/data/student_ride_log_model.dart';
import '../data/daily_session_model.dart';

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
        .asyncMap((snapshot) async {
      final List<TripManifestModel> manifest = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        try {
          final studentDoc = await _firestore.collection('students').doc(doc.id).get();
          if (studentDoc.exists && studentDoc.data() != null) {
            final studentData = studentDoc.data()!;
            if (studentData.containsKey('home_location')) {
              data['home_location'] = studentData['home_location'];
            }
          }
        } catch (e) {
          // Fallback to existing data if fetch fails
        }
        
        manifest.add(TripManifestModel.fromJson(data, doc.id));
      }
      return manifest;
    });
  }

  /// Creates a new document in the daily_sessions collection, starting a trip.
  /// Returns the generated session_id.
  Future<String> startDailySession(String tripId, {String? selectedVehicle}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User must be authenticated to start a session.';
      }

      // Fetch trip details to determine trip type
      final tripSnap = await _firestore.collection('trips').doc(tripId).get();
      if (!tripSnap.exists) {
        throw 'Trip template not found.';
      }
      final tripType = tripSnap.data()?['trip_type'] as String? ?? 'Morning';
      final isMorning = tripType.toLowerCase() == 'morning';

      // Generate a unique session ID using Firestore doc ID generator
      final docRef = _firestore.collection('daily_sessions').doc();
      final sessionId = docRef.id;

      final now = DateTime.now();
      final dateString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final initialStatuses = <String, String>{};

      // Initialize attendance records from manifest and populate initialStatuses
      final manifestDocs = await _firestore.collection('trips').doc(tripId).collection('trip_manifest').get();
      for (var manifestDoc in manifestDocs.docs) {
        final studentId = manifestDoc.id;

        // Fetch student's current Firebase status
        final studentDoc = await _firestore.collection('students').doc(studentId).get();
        final studentStatus = studentDoc.data()?['current_status'] as String? ?? 'At Home';

        String studentInitialStatus;
        if (isMorning) {
          studentInitialStatus = 'At Home';
        } else {
          // Evening Trip: if student is already 'At Home', they are default 'Absent'
          if (studentStatus == 'At Home') {
            studentInitialStatus = 'Absent';
          } else {
            studentInitialStatus = 'At School';
          }
        }
        
        initialStatuses[studentId] = studentInitialStatus;
      }

      final sessionData = {
        'session_id': sessionId,
        'trip_id': tripId,
        'driver_uid': currentUser.uid,
        'date': dateString,
        'status': 'in_progress',
        'mqtt_topic_id': sessionId,
        'start_time': Timestamp.fromDate(now),
        'initial_statuses': initialStatuses,
        'is_redo': false,
        if (selectedVehicle != null) 'vehicle_number': selectedVehicle,
      };

      final batch = _firestore.batch();
      batch.set(docRef, sessionData);
      
      // Update trip template status
      batch.update(_firestore.collection('trips').doc(tripId), {
        'status': 'active',
      });

      // Initialize attendance records from manifest
      for (var manifestDoc in manifestDocs.docs) {
        final studentId = manifestDoc.id;
        final studentInitialStatus = initialStatuses[studentId]!;

        final attendanceRef = docRef.collection('attendance').doc(studentId);
        batch.set(attendanceRef, {
          'status': studentInitialStatus,
        });

        // Set global student status as well
        batch.update(_firestore.collection('students').doc(studentId), {
          'current_status': studentInitialStatus,
        });
      }

      await batch.commit();
      return sessionId;
    } catch (e) {
      throw 'Failed to start trip: $e';
    }
  }

  Future<String> startRedoDailySession(String tripId, String previousSessionId, {String? selectedVehicle}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User must be authenticated to start a session.';
      }

      final tripSnap = await _firestore.collection('trips').doc(tripId).get();
      if (!tripSnap.exists) {
        throw 'Trip template not found.';
      }
      final tripType = tripSnap.data()?['trip_type'] as String? ?? 'Morning';
      final isMorning = tripType.toLowerCase() == 'morning';

      final docRef = _firestore.collection('daily_sessions').doc();
      final sessionId = docRef.id;

      final now = DateTime.now();
      final dateString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final initialStatuses = <String, String>{};
      final manifestDocs = await _firestore.collection('trips').doc(tripId).collection('trip_manifest').get();
      for (var manifestDoc in manifestDocs.docs) {
        final studentId = manifestDoc.id;
        final studentDoc = await _firestore.collection('students').doc(studentId).get();
        final studentStatus = studentDoc.data()?['current_status'] as String? ?? 'At Home';

        String studentInitialStatus;
        if (isMorning) {
          studentInitialStatus = 'At Home';
        } else {
          if (studentStatus == 'At Home') {
            studentInitialStatus = 'Absent';
          } else {
            studentInitialStatus = 'At School';
          }
        }
        initialStatuses[studentId] = studentInitialStatus;
      }

      final sessionData = {
        'session_id': sessionId,
        'trip_id': tripId,
        'driver_uid': currentUser.uid,
        'date': dateString,
        'status': 'in_progress',
        'mqtt_topic_id': sessionId,
        'start_time': Timestamp.fromDate(now),
        'initial_statuses': initialStatuses,
        'is_redo': true,
        'previous_session_id': previousSessionId,
        if (selectedVehicle != null) 'vehicle_number': selectedVehicle,
      };

      final batch = _firestore.batch();
      batch.set(docRef, sessionData);
      
      batch.update(_firestore.collection('trips').doc(tripId), {
        'status': 'active',
      });

      for (var manifestDoc in manifestDocs.docs) {
        final studentId = manifestDoc.id;
        final studentInitialStatus = initialStatuses[studentId]!;

        final attendanceRef = docRef.collection('attendance').doc(studentId);
        batch.set(attendanceRef, {
          'status': studentInitialStatus,
        });

        batch.update(_firestore.collection('students').doc(studentId), {
          'current_status': studentInitialStatus,
        });
      }

      await batch.commit();
      return sessionId;
    } catch (e) {
      throw 'Failed to start redo trip: $e';
    }
  }

  Future<void> reopenDailySession(String sessionId, String tripId) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('daily_sessions').doc(sessionId), {
      'status': 'in_progress',
      'end_time': FieldValue.delete(),
    });
    batch.update(_firestore.collection('trips').doc(tripId), {
      'status': 'active',
      'last_completed_date': FieldValue.delete(),
    });
    await batch.commit();
  }

  Future<void> endDailySession(String sessionId, String tripId) async {
    // 1. Fetch trip document to get tripType for proper cleanup status
    final tripDoc = await _firestore.collection('trips').doc(tripId).get();
    if (!tripDoc.exists) return;

    final tripData = tripDoc.data()!;
    final tripType = tripData['trip_type'] as String? ?? 'Morning';
    final isMorning = tripType.toLowerCase() == 'morning';
    final autoUpdateStatus = isMorning ? 'At School' : 'At Home';

    final batch = _firestore.batch();
    final sessionRef = _firestore.collection('daily_sessions').doc(sessionId);

    final finalStatuses = <String, String>{};

    // 2. Fetch all attendance records for this session and clean up "In Van"
    final attendanceDocs = await sessionRef.collection('attendance').get();
    for (var doc in attendanceDocs.docs) {
      final currentStatus = doc.data()['status'] as String? ?? '';
      if (currentStatus == 'In Van') {
        // Auto-update student accidentally left in van
        batch.update(doc.reference, {'status': autoUpdateStatus});
        finalStatuses[doc.id] = autoUpdateStatus;
        // Sync to global student record
        batch.update(_firestore.collection('students').doc(doc.id), {
          'current_status': autoUpdateStatus,
        });
      } else {
        finalStatuses[doc.id] = currentStatus;
      }
    }

    // 3. Mark session and trip as completed
    batch.update(sessionRef, {
      'status': 'completed',
      'end_time': Timestamp.fromDate(DateTime.now()),
      'final_statuses': finalStatuses,
    });
    batch.update(_firestore.collection('trips').doc(tripId), {
      'status': 'completed',
      'last_completed_date': Timestamp.fromDate(DateTime.now()),
    });

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
    final tripType = tripSnap.data()?['trip_type'] as String? ?? 'Morning';

    // Fetch driver details
    final driverSnap = await _firestore.collection('users').doc(driverUid).get();
    final driverName = driverSnap.data()?['name'] as String? ?? 'Unknown Driver';
    final vehicleNumber = sessionSnap.data()?['vehicle_number'] as String? ?? _resolveDriverVehicleNumber(driverSnap.data());

    // Fetch current attendance
    final attendanceSnap = await attendanceRef.get();
    if (!attendanceSnap.exists) {
      throw 'Student $studentId is not on this trip\'s manifest.';
    }

    final currentStatus = attendanceSnap.data()?['status'] as String? ?? 'At Home';
    final rideHistoryRef = _firestore.collection('students').doc(studentId).collection('ride_history').doc(sessionId);

    final batch = _firestore.batch();
    final now = Timestamp.fromDate(overrideTimestamp ?? DateTime.now());

    final isMorning = tripType.toLowerCase() == 'morning';
    String nextStatus;

    if (isMorning) {
      if (currentStatus == 'At Home') {
        nextStatus = 'In Van';
      } else if (currentStatus == 'In Van') {
        nextStatus = 'At School';
      } else {
        throw 'Student already at school.';
      }
    } else {
      if (currentStatus == 'At School' || currentStatus == 'Absent') {
        nextStatus = 'In Van';
      } else if (currentStatus == 'In Van') {
        nextStatus = 'At Home';
      } else {
        throw 'Student already at home.';
      }
    }

    final updateData = <String, dynamic>{
      'status': nextStatus,
    };
    if (nextStatus == 'In Van') {
      updateData['boarded_at'] = now;
    } else {
      updateData['alighted_at'] = now;
    }

    batch.update(attendanceRef, updateData);

    // Create / update ride history entry
    final rideLog = StudentRideLogModel(
      logId: sessionId,
      sessionId: sessionId,
      tripId: tripId,
      tripName: tripName,
      tripType: tripType,
      driverName: driverName,
      vehicleNumber: vehicleNumber,
      date: dateString,
      boardedAt: nextStatus == 'In Van' ? now.toDate() : null,
      alightedAt: (nextStatus == 'At School' || nextStatus == 'At Home') ? now.toDate() : null,
      status: nextStatus,
    );
    batch.set(rideHistoryRef, rideLog.toJson(), SetOptions(merge: true));
    
    // Sync to global student record and increment stats if trip completed
    final globalUpdate = <String, dynamic>{
      'current_status': nextStatus,
    };
    if (nextStatus == 'At School' || nextStatus == 'At Home') {
      globalUpdate['stats.total_trips'] = FieldValue.increment(1);
    }
    
    batch.update(_firestore.collection('students').doc(studentId), globalUpdate);

    await batch.commit();
  }

  /// Manually override attendance status (At Home, In Van, At School)
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
    final tripType = tripSnap.data()?['trip_type'] as String? ?? 'Morning';

    final driverSnap = await _firestore.collection('users').doc(driverUid).get();
    final driverName = driverSnap.data()?['name'] as String? ?? 'Unknown Driver';
    final vehicleNumber = sessionSnap.data()?['vehicle_number'] as String? ?? _resolveDriverVehicleNumber(driverSnap.data());

    final batch = _firestore.batch();
    final now = Timestamp.fromDate(DateTime.now());
    
    final updateData = <String, dynamic>{
      'status': status,
    };
    if (status == 'In Van') {
      updateData['boarded_at'] = now;
    } else if (status == 'At Home' || status == 'At School') {
      updateData['alighted_at'] = now;
    }

    batch.update(attendanceRef, updateData);

    // Ride History
    final rideHistoryRef = _firestore.collection('students').doc(studentId).collection('ride_history').doc(sessionId);
    
    final rideLog = StudentRideLogModel(
      logId: sessionId,
      sessionId: sessionId,
      tripId: tripId,
      tripName: tripName,
      tripType: tripType,
      driverName: driverName,
      vehicleNumber: vehicleNumber,
      date: dateString,
      boardedAt: status == 'In Van' ? now.toDate() : null,
      alightedAt: (status == 'At Home' || status == 'At School') ? now.toDate() : null,
      status: status,
    );
    
    batch.set(rideHistoryRef, rideLog.toJson(), SetOptions(merge: true));

    // Sync to global student record and increment stats
    final globalUpdate = <String, dynamic>{
      'current_status': status,
    };
    if (status == 'At Home' || status == 'At School') {
      globalUpdate['stats.total_trips'] = FieldValue.increment(1);
    }
    
    batch.update(_firestore.collection('students').doc(studentId), globalUpdate);

    await batch.commit();
  }

  /// Bulk action to drop off all students currently "In Van" at the school.
  Future<void> dropOffAllStudentsAtSchool(String sessionId) async {
    final sessionRef = _firestore.collection('daily_sessions').doc(sessionId);
    
    final sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) throw 'Active trip session not found.';

    final tripId = sessionSnap.data()?['trip_id'] as String? ?? '';
    final dateString = sessionSnap.data()?['date'] as String? ?? '';
    final driverUid = sessionSnap.data()?['driver_uid'] as String? ?? '';

    // Fetch details for ride log
    final tripSnap = await _firestore.collection('trips').doc(tripId).get();
    final tripName = tripSnap.data()?['trip_name'] as String? ?? 'Unknown Trip';
    final tripType = tripSnap.data()?['trip_type'] as String? ?? 'Morning';

    final driverSnap = await _firestore.collection('users').doc(driverUid).get();
    final driverName = driverSnap.data()?['name'] as String? ?? 'Unknown Driver';
    final vehicleNumber = sessionSnap.data()?['vehicle_number'] as String? ?? _resolveDriverVehicleNumber(driverSnap.data());

    final batch = _firestore.batch();
    final now = Timestamp.fromDate(DateTime.now());
    final status = 'At School';

    final attendanceDocs = await sessionRef.collection('attendance').get();
    int count = 0;

    for (var doc in attendanceDocs.docs) {
      final currentStatus = doc.data()['status'] as String? ?? '';
      if (currentStatus == 'In Van') {
        final studentId = doc.id;
        final attendanceRef = sessionRef.collection('attendance').doc(studentId);

        final updateData = <String, dynamic>{
          'status': status,
          'alighted_at': now,
        };

        batch.update(attendanceRef, updateData);

        // Ride History
        final rideHistoryRef = _firestore.collection('students').doc(studentId).collection('ride_history').doc(sessionId);
        
        final rideLog = StudentRideLogModel(
          logId: sessionId,
          sessionId: sessionId,
          tripId: tripId,
          tripName: tripName,
          tripType: tripType,
          driverName: driverName,
          vehicleNumber: vehicleNumber,
          date: dateString,
          alightedAt: now.toDate(),
          status: status,
        );
        
        batch.set(rideHistoryRef, rideLog.toJson(), SetOptions(merge: true));

        // Sync to global student record and increment stats
        final globalUpdate = <String, dynamic>{
          'current_status': status,
          'stats.total_trips': FieldValue.increment(1),
        };
        
        batch.update(_firestore.collection('students').doc(studentId), globalUpdate);
        count++;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  /// Returns the active session ID for a student, regardless of their attendance status.
  /// The parent can track the van as long as the session is in_progress.
  Future<String?> getActiveSessionIdForStudent(String studentId) async {
    final activeSessions = await _firestore
        .collection('daily_sessions')
        .where('status', isEqualTo: 'in_progress')
        .get();

    for (var sessionDoc in activeSessions.docs) {
      final attendanceSnap = await sessionDoc.reference
          .collection('attendance')
          .doc(studentId)
          .get();
      if (attendanceSnap.exists) {
        return sessionDoc.id;
      }
    }
    return null;
  }

  String _resolveDriverVehicleNumber(Map<String, dynamic>? data) {
    if (data == null) return '';

    final primaryVehicleNumber = data['vehicle_number'] as String?;
    if (primaryVehicleNumber != null && primaryVehicleNumber.trim().isNotEmpty) {
      return primaryVehicleNumber.trim();
    }

    final rawVehicleNumbers = data['vehicle_numbers'];
    if (rawVehicleNumbers is List) {
      for (final value in rawVehicleNumbers) {
        final vehicleNumber = value.toString().trim();
        if (vehicleNumber.isNotEmpty) {
          return vehicleNumber;
        }
      }
    }

    return '';
  }

  /// Update full trip details (name, roster) and rebuild manifest & dynamically derived destinations (schools)
  Future<void> updateTrip(String tripId, String name, List<String> studentIds) async {
    final List<String> schoolIds = [];
    final List<Map<String, dynamic>> studentsData = [];

    for (var studentId in studentIds) {
      final doc = await _firestore.collection('students').doc(studentId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        studentsData.add({
          'id': studentId,
          'name': data['name'] ?? '',
          'school_id': data['school_id'] ?? '',
          'school_name': data['school_name'] ?? '',
        });
        final sId = data['school_id'] as String?;
        if (sId != null && sId.isNotEmpty && !schoolIds.contains(sId)) {
          schoolIds.add(sId);
        }
      }
    }

    final batch = _firestore.batch();
    
    batch.update(_firestore.collection('trips').doc(tripId), {
      'trip_name': name,
      'student_ids': studentIds,
      'school_ids': schoolIds,
    });

    // Rebuild manifest
    final manifestSnap = await _firestore.collection('trips').doc(tripId).collection('trip_manifest').get();
    for (var doc in manifestSnap.docs) {
      batch.delete(doc.reference);
    }

    for (var i = 0; i < studentsData.length; i++) {
      final sd = studentsData[i];
      final docRef = _firestore.collection('trips').doc(tripId).collection('trip_manifest').doc(sd['id']);
      batch.set(docRef, {
        'name': sd['name'],
        'school_id': sd['school_id'],
        'school_name': sd['school_name'],
        'stop_order': i + 1,
        'status': 'At Home',
      });
    }

    await batch.commit();
  }

  /// Permanently removes a student and clears their references from active trip manifests,
  /// maintaining their historical records in daily_sessions and ride_history.
  Future<void> removeStudentPermanently({required String studentId, required List<String> activeTripIds}) async {
    final batch = _firestore.batch();

    // 1. Delete from primary students collection
    batch.delete(_firestore.collection('students').doc(studentId));

    // 2. Clear out completely from active trip manifests so drivers see immediate updates
    for (String tripId in activeTripIds) {
      final manifestRef = _firestore.collection('trips').doc(tripId).collection('trip_manifest').doc(studentId);
      batch.delete(manifestRef);

      // Remove from flat tracking array inside the core trip document
      batch.update(_firestore.collection('trips').doc(tripId), {
        'student_ids': FieldValue.arrayRemove([studentId])
      });
    }

    await batch.commit();
  }
}
