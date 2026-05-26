import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mqtt_service.dart';

/// Riverpod provider that exposes live telemetry for the parent dashboard.
///
/// Usage — pass the active session_id:
///   ref.watch(parentTelemetryProvider('SESSION_ID'))
final parentTelemetryProvider =
    StreamProvider.family<TelemetryPayload?, String>((ref, sessionId) {
  final consumer = TelemetryConsumer();

  // Start connection in the background; stream will deliver payloads as they arrive.
  consumer.connect(sessionId: sessionId).then((ok) {
    if (!ok) debugPrint('[TelemetryConsumer] Could not connect for session $sessionId');
  });

  // Clean disconnect when the provider is no longer watched.
  ref.onDispose(consumer.dispose);

  return consumer.stream;
});

/// Manages the parent-side MQTT subscribe connection.
class TelemetryConsumer {
  final MqttService _mqtt = MqttService();
  String? _topic;

  // Expose a broadcast stream so multiple listeners are safe.
  Stream<TelemetryPayload?> get stream => _mqtt.telemetryStream;

  Future<bool> connect({required String sessionId}) async {
    // Use a timestamp suffix to keep client IDs unique per session even if the
    // app is reopened quickly, avoiding "client already connected" broker rejections.
    final clientId = 'parent_${sessionId}_${DateTime.now().millisecondsSinceEpoch}';
    _topic = MqttService.telemetryTopic(sessionId);

    final connected = await _mqtt.connect(clientId);
    if (connected) {
      _mqtt.subscribe(_topic!);
      debugPrint('[TelemetryConsumer] Subscribed to $_topic');
    }
    return connected;
  }

  void dispose() {
    if (_topic != null) _mqtt.unsubscribe(_topic!);
    _mqtt.dispose();
    debugPrint('[TelemetryConsumer] Disposed.');
  }
}
