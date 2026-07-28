import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../trips/data/daily_session_model.dart';
import '../data/student_ride_log_model.dart';
import '../../auth/domain/auth_service.dart';

final historyServiceProvider = Provider<HistoryService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return HistoryService(firestore);
});

class HistoryService {
  final FirebaseFirestore _firestore;

  HistoryService(this._firestore);

  /// Fetch driver history for a specific date
  Future<List<DailySessionModel>> getDriverHistoryByDate(String driverUid, String dateString) async {
    final query = await _firestore
        .collection('daily_sessions')
        .where('driver_uid', isEqualTo: driverUid)
        .where('date', isEqualTo: dateString)
        .orderBy('start_time', descending: true)
        .get();

    return query.docs.map((doc) => DailySessionModel.fromJson(doc.data(), doc.id)).toList();
  }

  /// Fetch student history for a specific date across all trips they took
  Future<List<StudentRideLogModel>> getStudentHistoryByDate(String studentId, String dateString) async {
    final query = await _firestore
        .collection('students')
        .doc(studentId)
        .collection('ride_history')
        .where('date', isEqualTo: dateString)
        .orderBy('boarded_at', descending: true)
        .get();

    return query.docs.map((doc) => StudentRideLogModel.fromJson(doc.data(), doc.id)).toList();
  }

  /// Bulk fetch ALL history for a student (for local filtering/processing)
  Future<List<StudentRideLogModel>> getAllStudentHistory(String studentId) async {
    final query = await _firestore
        .collection('students')
        .doc(studentId)
        .collection('ride_history')
        .orderBy('boarded_at', descending: true)
        .get();

    return query.docs.map((doc) => StudentRideLogModel.fromJson(doc.data(), doc.id)).toList();
  }

  /// Fetch specific trip snapshot data (before/after statuses, timestamps, etc.)
  Future<Map<String, dynamic>> getTripSnapshotData(String sessionId) async {
    final doc = await _firestore.collection('daily_sessions').doc(sessionId).get();
    if (!doc.exists || doc.data() == null) {
      throw 'Session not found';
    }

    final data = doc.data()!;
    return {
      'start_time': data['start_time'],
      'end_time': data['end_time'],
      'initial_statuses': data['initial_statuses'] ?? {},
      'final_statuses': data['final_statuses'] ?? {},
      'is_redo': data['is_redo'] ?? false,
      'previous_session_id': data['previous_session_id'],
    };
  }
}
