import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EMQX Cloud (Serverless, Mumbai) — Direct TLS/SSL over port 8883
// ─────────────────────────────────────────────────────────────────────────────
const _kBrokerHost = 'x6ee8611.ala.asia-southeast1.emqxsl.com';
const _kBrokerPort = 8883;
const _kUsername   = 'safepick_app_client';
const _kPassword   = 'Emqxpassword@1';
const _kCertAsset  = 'assets/certs/emqxsl-ca.crt';
const _kKeepAlive  = 30;
const _kMaxReconnectAttempts = 5;
const _kReconnectDelaySeconds = 3;

/// Compact telemetry payload model.
class TelemetryPayload {
  final double latitude;
  final double longitude;
  final double speed;

  const TelemetryPayload({
    required this.latitude,
    required this.longitude,
    required this.speed,
  });

  factory TelemetryPayload.fromJson(Map<String, dynamic> json) {
    return TelemetryPayload(
      latitude:  (json['latitude']  as num? ?? 0.0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0.0).toDouble(),
      speed:     (json['speed']     as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude':  latitude,
    'longitude': longitude,
    'speed':     speed,
  };
}

/// Production-grade MQTT service for SafePick.
///
/// Lifecycle:
///   1. Call [connect] with a unique clientId before publishing or subscribing.
///   2. Use [publish] to push telemetry (driver side).
///   3. Use [subscribe] + listen to [telemetryStream] (parent side).
///   4. Call [disconnect] when done (pause/end trip or child leaves van).
class MqttService {
  MqttServerClient? _client;
  final StreamController<TelemetryPayload> _telemetryController =
      StreamController<TelemetryPayload>.broadcast();

  bool _isConnected = false;
  bool _isDisposing = false;
  int  _reconnectAttempts = 0;

  /// Exposed broadcast stream of incoming telemetry payloads.
  Stream<TelemetryPayload> get telemetryStream => _telemetryController.stream;
  bool get isConnected => _isConnected;

  // ─────────────────────────────────────────────────────────────────────────
  // Connection
  // ─────────────────────────────────────────────────────────────────────────

  /// Connects to EMQX over TLS/SSL. Returns [true] on success.
  Future<bool> connect(String clientId) async {
    _isDisposing = false;

    try {
      // Load the CA certificate from Flutter assets and build a SecurityContext.
      final certBytes = await rootBundle.load(_kCertAsset);
      final securityContext = SecurityContext.defaultContext;
      try {
        securityContext.setTrustedCertificatesBytes(certBytes.buffer.asUint8List());
      } catch (_) {
        // Already trusted — safe to ignore "TrustAnchorAlreadyExists" errors
        // that happen if connect() is called more than once in a session.
      }

      _client = MqttServerClient.withPort(_kBrokerHost, clientId, _kBrokerPort);
      _client!.onBadCertificate = (dynamic cert) => true;
      _client!
        ..secure          = true
        ..securityContext = securityContext
        ..keepAlivePeriod = _kKeepAlive
        ..autoReconnect   = false          // We manage reconnect manually for better control
        ..onDisconnected  = _onDisconnected
        ..onConnected     = _onConnected
        ..logging(on: kDebugMode);

      final connMsg = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(_kUsername, _kPassword)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      _client!.connectionMessage = connMsg;

      debugPrint('[MQTT] Connecting as $clientId …');
      await _client!.connect();
    } on NoConnectionException catch (e) {
      debugPrint('[MQTT] NoConnectionException: $e');
      _isConnected = false;
      return false;
    } on SocketException catch (e) {
      debugPrint('[MQTT] SocketException: $e');
      _isConnected = false;
      return false;
    } catch (e) {
      debugPrint('[MQTT] Unexpected connect error: $e');
      _isConnected = false;
      return false;
    }

    if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
      _reconnectAttempts = 0;
      _isConnected = true;
      // Wire incoming messages to the telemetry stream.
      _client!.updates?.listen(_onMessage);
      return true;
    }

    debugPrint('[MQTT] Connection failed — state: ${_client!.connectionStatus?.state}');
    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Publish (Driver → broker)
  // ─────────────────────────────────────────────────────────────────────────

  /// Publishes [payload] to [topic] using QoS 0 (fire-and-forget) for low latency.
  void publish(String topic, TelemetryPayload payload) {
    if (!_isConnected || _client == null) return;

    final builder = MqttClientPayloadBuilder()
      ..addString(jsonEncode(payload.toJson()));

    _client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    debugPrint('[MQTT] Published to $topic: ${jsonEncode(payload.toJson())}');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Subscribe (Parent ← broker)
  // ─────────────────────────────────────────────────────────────────────────

  /// Subscribes to [topic] and routes incoming payloads to [telemetryStream].
  void subscribe(String topic) {
    if (!_isConnected || _client == null) return;
    _client!.subscribe(topic, MqttQos.atMostOnce);
    debugPrint('[MQTT] Subscribed to $topic');
  }

  /// Unsubscribes from [topic].
  void unsubscribe(String topic) {
    if (_client == null) return;
    _client!.unsubscribe(topic);
    debugPrint('[MQTT] Unsubscribed from $topic');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Disconnect
  // ─────────────────────────────────────────────────────────────────────────

  /// Cleanly disconnects from the broker.
  void disconnect() {
    _isDisposing = true;
    _isConnected = false;
    _client?.disconnect();
    debugPrint('[MQTT] Disconnected cleanly.');
  }

  /// Call when the owning widget/service is being destroyed.
  void dispose() {
    disconnect();
    _telemetryController.close();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Callbacks
  // ─────────────────────────────────────────────────────────────────────────

  void _onConnected() {
    _isConnected = true;
    _reconnectAttempts = 0;
    debugPrint('[MQTT] Connected ✓');
  }

  void _onDisconnected() {
    _isConnected = false;
    debugPrint('[MQTT] Disconnected — disposing=$_isDisposing');

    // Auto-reconnect with exponential-like back-off unless we chose to disconnect.
    if (!_isDisposing && _reconnectAttempts < _kMaxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = _kReconnectDelaySeconds * _reconnectAttempts;
      debugPrint('[MQTT] Reconnecting in ${delay}s (attempt $_reconnectAttempts)…');
      Future.delayed(Duration(seconds: delay), () {
        if (!_isDisposing) {
          final id = _client?.clientIdentifier ?? 'safepick_reconnect';
          connect(id);
        }
      });
    }
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final msg in messages) {
      final pub = msg.payload as MqttPublishMessage;
      final raw = MqttPublishPayload.bytesToStringAsString(pub.payload.message);
      debugPrint('[MQTT] Received on ${msg.topic}: $raw');
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _telemetryController.add(TelemetryPayload.fromJson(json));
      } catch (e) {
        debugPrint('[MQTT] Failed to parse payload: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Topic Helper
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the canonical telemetry topic for a given session.
  static String telemetryTopic(String sessionId) =>
      'safepick/trips/$sessionId/telemetry';
}