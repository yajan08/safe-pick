import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class MapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<Position> positionStream({int distanceFilter = 10}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: distanceFilter,
      ),
    );
  }

  Future<LocationPermission> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Let the caller handle UI to ask user to enable.
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Starts publishing the device position to `users/{uid}/current_location`.
  /// Returns the StreamSubscription so the caller can cancel when appropriate.
  StreamSubscription<Position> startPublishingLocation(String uid,
      {int distanceFilter = 10}) {
    final stream = positionStream(distanceFilter: distanceFilter);
    final sub = stream.listen((pos) async {
      try {
        await _firestore.collection('users').doc(uid).set({
          'current_location': GeoPoint(pos.latitude, pos.longitude),
          'location_updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        // swallow - caller can observe failures elsewhere
      }
    });
    return sub;
  }
}
