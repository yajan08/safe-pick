import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/data/user_model.dart';
import '../../trips/data/daily_session_model.dart';
import '../../trips/data/trip_model.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return AdminService(firestore);
});

final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = ref.watch(adminServiceProvider);
  return service.getHighLevelStats();
});

final liveTripsProvider = StreamProvider<List<DailySessionModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('daily_sessions')
      .where('status', isEqualTo: 'in_progress')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => DailySessionModel.fromJson(doc.data(), doc.id)).toList());
});

class AdminService {
  final FirebaseFirestore _firestore;

  AdminService(this._firestore);

  Future<Map<String, int>> getHighLevelStats() async {
    final now = DateTime.now();
    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final driversCount = await _firestore.collection('users').where('role', isEqualTo: 'driver').count().get();
    final studentsCount = await _firestore.collection('students').count().get();
    
    // Fallback if index missing: just query all live sessions and count
    final activeTrips = await _firestore
        .collection('daily_sessions')
        .where('status', isEqualTo: 'in_progress')
        .count()
        .get();

    return {
      'total_drivers': driversCount.count ?? 0,
      'total_students': studentsCount.count ?? 0,
      'active_trips_today': activeTrips.count ?? 0,
      'absent_today': 0, // In a real app, query ride_history logs for 'Absent' statuses today
    };
  }

  Future<List<UserModel>> getPaginatedUsers(DocumentSnapshot? lastDoc, int limit, {String? role}) async {
    Query query = _firestore.collection('users').orderBy('created_at', descending: true);
    if (role != null && role != 'All') {
      query = _firestore.collection('users')
          .where('role', isEqualTo: role.toLowerCase())
          .orderBy('created_at', descending: true);
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    
    final snap = await query.limit(limit).get();
    return snap.docs.map((d) => UserModel.fromJson(d.data() as Map<String, dynamic>)).toList();
  }
}
