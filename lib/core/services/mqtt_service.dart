import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

final mqttServiceProvider = Provider<MqttService>((ref) => MqttService());

class MqttService {
  MqttServerClient? _client;
  bool _isConnected = false;
  String? _currentClientId;

  // Configuration
  static const String _broker = 'x6ee8611.ala.asia-southeast1.emqxsl.com';
  static const int _port = 8883;
  static const String _username = 'safepick_app_client';
  static const String _password = 'Emqxpassword@1';

  /// Initializes and connects to the EMQX broker securely.
  Future<void> connect(String clientId) async {
    if (_isConnected && _currentClientId == clientId) return;

    _currentClientId = clientId;
    _client = MqttServerClient.withPort(_broker, clientId, _port);
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 60;
    _client!.autoReconnect = true;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.secure = true;
    
    try {
      final SecurityContext context = SecurityContext.defaultContext;
      final certBytes = await rootBundle.load('assets/certs/emqxsl-ca.crt');
      context.setTrustedCertificatesBytes(certBytes.buffer.asUint8List());
      _client!.securityContext = context;
    } catch (e) {
      print('MQTT SSL Setup Error: $e');
      // If the dummy cert is used, it might fail in production, but we catch it to avoid crash
    }

    final connMess = MqttConnectMessage()
        .authenticateAs(_username, _password)
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    
    _client!.connectionMessage = connMess;

    try {
      await _client!.connect();
    } catch (e) {
      print('MQTT Connection Exception: $e');
      _disconnectCleanly();
    }
  }

  void _onConnected() {
    _isConnected = true;
    print('MQTT Connected as $_currentClientId');
  }

  void _onDisconnected() {
    _isConnected = false;
    print('MQTT Disconnected');
  }

  void _onSubscribed(String topic) {
    print('MQTT Subscribed to $topic');
  }

  void _disconnectCleanly() {
    _client?.disconnect();
    _isConnected = false;
  }

  void disconnect() {
    _disconnectCleanly();
  }

  String _getTopic(String sessionId) => 'safepick/trips/$sessionId/telemetry';

  /// Publishes location data for the driver pipeline.
  void publishLocation(String sessionId, double lat, double lng, double speed) {
    if (!_isConnected || _client == null) return;
    
    final topic = _getTopic(sessionId);
    final payload = jsonEncode({
      'latitude': lat,
      'longitude': lng,
      'speed': speed,
    });
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    
    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  /// Streams location data for the parent pipeline.
  Stream<Map<String, dynamic>> streamLocation(String sessionId) {
    if (!_isConnected || _client == null) {
      return const Stream.empty();
    }
    
    final topic = _getTopic(sessionId);
    _client!.subscribe(topic, MqttQos.atLeastOnce);
    
    return _client!.updates!.expand((List<MqttReceivedMessage<MqttMessage>> messages) {
      return messages.map((MqttReceivedMessage<MqttMessage> message) {
        final MqttPublishMessage recMess = message.payload as MqttPublishMessage;
        final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        try {
          final Map<String, dynamic> data = jsonDecode(pt);
          return data;
        } catch (e) {
          print('MQTT Payload Parse Error: $e');
          return <String, dynamic>{};
        }
      });
    }).where((data) => data.isNotEmpty);
  }
}