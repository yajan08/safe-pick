// ignore_for_file: deprecated_member_use
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_service.dart';
import '../../auth/data/user_model.dart';
import '../../trips/data/daily_session_model.dart';
import '../../students/data/student_model.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

final adminStatsProvider = StreamProvider<Map<String, int>>((ref) {
  final firestore = ref.watch(firestoreProvider);

  // Emit immediately, then refresh every 15 seconds for near-real-time stats.
  Stream<Map<String, int>> statsStream() async* {
    while (true) {
      try {
        final driversCount = await firestore.collection('users').where('role', isEqualTo: 'driver').count().get();
        final studentsCount = await firestore.collection('students').count().get();
        final activeTrips = await firestore.collection('daily_sessions').where('status', isEqualTo: 'in_progress').count().get();

        yield {
          'total_drivers': driversCount.count ?? 0,
          'total_students': studentsCount.count ?? 0,
          'active_trips_today': activeTrips.count ?? 0,
          'absent_today': 0,
        };
      } catch (e) {
        yield {'total_drivers': 0, 'total_students': 0, 'active_trips_today': 0, 'absent_today': 0};
      }
      await Future.delayed(const Duration(seconds: 15));
    }
  }

  return statsStream();
});

final adminLiveTripsProvider = StreamProvider<List<DailySessionModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('daily_sessions')
      .where('status', isEqualTo: 'in_progress')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => DailySessionModel.fromJson(doc.data(), doc.id)).toList());
});

final adminUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .orderBy('created_at', descending: true)
      .limit(100) // limit to 100 for stream performance
      .snapshots()
      .map((snap) => snap.docs.map((doc) => UserModel.fromJson(doc.data())).toList());
});

final adminStudentsProvider = StreamProvider<List<StudentModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('students')
      .limit(100)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => StudentModel.fromJson(doc.data(), doc.id)).toList());
});

class AdminService {
  AdminService();
}
