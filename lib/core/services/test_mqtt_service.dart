import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart';

class TestMqttService {
  Future<void> testConnection() async {
    final client = MqttServerClient.withPort(
      'x6ee8611.ala.asia-southeast1.emqxsl.com',
      'test_driver_123',
      8883,
    );

    client.secure = true;
    client.logging(on: true);
    client.keepAlivePeriod = 60;

    // Load CA certificate
    try {
      final certData = await rootBundle.load('assets/certs/emqxsl-ca.crt');
      final certBytes = certData.buffer.asUint8List();
      
      final SecurityContext context = SecurityContext(withTrustedRoots: true);
      context.setTrustedCertificatesBytes(certBytes);
      client.securityContext = context;
    } catch (e) {
      debugPrint('Failed to load CA certificate: $e');
      debugPrint('====== MQTT TEST FAILED ======');
      return;
    }

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('test_driver_123')
        .authenticateAs('safepick_app_client', 'Emqxpassword@1')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      debugPrint('Connecting to EMQX...');
      await client.connect();
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        debugPrint('====== MQTT TEST SUCCESS ======');
        client.disconnect();
      } else {
        debugPrint('Connection failed with state: ${client.connectionStatus?.state}');
        debugPrint('====== MQTT TEST FAILED ======');
      }
    } catch (e) {
      debugPrint('Error connecting to MQTT: $e');
      debugPrint('====== MQTT TEST FAILED ======');
    }
  }
}
