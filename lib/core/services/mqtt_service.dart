import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart';

class MqttService {
  MqttServerClient? client;

  // --- ADD THESE TWO LINES FOR PARENT LISTENING ---
  final StreamController<Map<String, dynamic>> _telemetryController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get telemetryStream => _telemetryController.stream;

  /// Connects to the EMQX broker. Returns true if successful.
  Future<bool> connect(String clientId) async {
    client = MqttServerClient.withPort(
      'x6ee8611.ala.asia-southeast1.emqxsl.com',
      clientId,
      8883,
    );

    client!.setProtocolV311(); 
    client!.secure = true;
    client!.logging(on: false); // Turned off extreme logging so terminal stays clean
    client!.keepAlivePeriod = 60;

    // Load CA certificate
    try {
      final certData = await rootBundle.load('assets/certs/emqxsl-ca.crt');
      final certBytes = certData.buffer.asUint8List();
      
      final SecurityContext context = SecurityContext(withTrustedRoots: true);
      context.setTrustedCertificatesBytes(certBytes);
      client!.securityContext = context;
    } catch (e) {
      debugPrint('Failed to load CA certificate: $e');
      return false;
    }

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs('safepick_app_client', 'Emqxpassword@1')
        .startClean();

    client!.connectionMessage = connMessage;

    try {
      debugPrint('Connecting to EMQX Broker as $clientId...');
      await client!.connect();
    } catch (e) {
      debugPrint('Error connecting to MQTT: $e');
      client!.disconnect();
      return false;
    }

    if (client!.connectionStatus?.state == MqttConnectionState.connected) {
      debugPrint('====== EMQX CONNECTED SUCCESSFULLY ======');
      
      // --- ADD THIS LISTENER TO CATCH INCOMING DATA ---
      client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final payloadString = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        try {
          final data = jsonDecode(payloadString) as Map<String, dynamic>;
          _telemetryController.add(data); // Pushes data to the Parent UI
        } catch (e) {
          debugPrint('Error parsing payload: $e');
        }
      });
      // ------------------------------------------------

      return true;
    } else {
      debugPrint('Connection failed with state: ${client!.connectionStatus?.state}');
      client!.disconnect();
      return false;
    }
  }

  /// Publishes GPS coordinates to the specific session topic
  void publishLocation(String sessionId, double lat, double lng, double speed) {
    if (client == null || client!.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('Cannot publish: MQTT not connected');
      return;
    }

    final topic = 'safepick/trips/$sessionId/telemetry';
    final payload = {
      'latitude': lat,
      'longitude': lng,
      'speed': speed,
    };
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(payload));

    client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    debugPrint('📍 Published Location to $topic');
  }

  /// Parent App: Subscribes to the live trip data
  void subscribeToTrip(String sessionId) {
    if (client == null || client!.connectionStatus?.state != MqttConnectionState.connected) return;
    final topic = 'safepick/trips/$sessionId/telemetry';
    client!.subscribe(topic, MqttQos.atMostOnce);
    debugPrint('🎧 Subscribed to listening channel: $topic');
  }

  /// Cleanly ends the connection
  void disconnect() {
    client?.disconnect();
    debugPrint('====== EMQX DISCONNECTED ======');
  }
}