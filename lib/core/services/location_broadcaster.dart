import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'mqtt_service.dart';

final locationBroadcasterProvider = Provider<LocationBroadcaster>((ref) {
  final broadcaster = LocationBroadcaster();
  ref.onDispose(() {
    broadcaster.dispose();
  });
  return broadcaster;
});

/// Handles the driver-side GPS → MQTT publish loop.
///
/// Usage:
///   final broadcaster = LocationBroadcaster();
///   await broadcaster.start(sessionId: '...', driverUid: '...');
///   // … driver drives …
///   await broadcaster.stop();
class LocationBroadcaster {
  final MqttService _mqtt = MqttService();
  StreamSubscription<Position>? _positionSub;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  /// Requests location permission, connects MQTT and starts the GPS stream.
  Future<bool> start({
    required String sessionId,
    required String driverUid,
  }) async {
    if (_isRunning) return true;

    // ── 1. Check / request location permissions ──────────────────────────
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      debugPrint('[Broadcaster] Location permission denied — cannot broadcast.');
      return false;
    }

    // ── 2. Connect to EMQX ───────────────────────────────────────────────
    final connected = await _mqtt.connect('driver_$driverUid');
    if (!connected) {
      debugPrint('[Broadcaster] MQTT connection failed.');
      return false;
    }

    // ── 3. Start streaming GPS → broker ──────────────────────────────────
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,         // metres — skip updates for static van
      timeLimit: Duration(seconds: 3),
    );

    final topic = MqttService.telemetryTopic(sessionId);

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          (position) {
            final payload = TelemetryPayload(
              latitude:  position.latitude,
              longitude: position.longitude,
              speed:     position.speed,
            );
            _mqtt.publish(topic, payload);
          },
          onError: (e) => debugPrint('[Broadcaster] GPS stream error: $e'),
        );

    _isRunning = true;
    debugPrint('[Broadcaster] Started for session $sessionId');
    return true;
  }

  /// Stops GPS streaming and disconnects cleanly from MQTT.
  Future<void> stop() async {
    if (!_isRunning) return;
    await _positionSub?.cancel();
    _positionSub = null;
    _mqtt.disconnect();
    _isRunning = false;
    debugPrint('[Broadcaster] Stopped and disconnected.');
  }

  void dispose() {
    stop();
    _mqtt.dispose();
  }
}
