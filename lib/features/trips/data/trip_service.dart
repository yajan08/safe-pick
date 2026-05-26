import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import 'trip_manifest_model.dart';

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

      await docRef.set(sessionData);
      
      // Update the active trip's status to active in Firestore (optional helper)
      await _firestore.collection('trips').doc(tripId).update({'status': 'active'});

      return sessionId;
    } catch (e) {
      throw 'Failed to start trip: $e';
    }
  }
}
