import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class MqttService {
  late MqttServerClient client;

  Future<bool> connect(String clientId) async {
    // Replace with your EMQX URI (e.g., broker.emqx.io or your private cloud URI)
    client = MqttServerClient('YOUR_EMQX_BROKER_URL', clientId);
    
    client.port = 1883; // Standard MQTT port (use 8883 for WSS/Secure)
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    
    // Create connection message
    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        // Add auth if you configured it in EMQX:
        // .authenticateAs('username', 'password')
        .startClean() 
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;

    try {
      debugPrint('Connecting to EMQX Broker...');
      await client.connect();
    } on NoConnectionException catch (e) {
      debugPrint('MQTT Client disconnected: $e');
      client.disconnect();
      return false;
    } on SocketException catch (e) {
      debugPrint('MQTT Socket exception: $e');
      client.disconnect();
      return false;
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      debugPrint('EMQX Connected Successfully!');
      return true;
    } else {
      debugPrint('EMQX Connection failed, state is ${client.connectionStatus!.state}');
      client.disconnect();
      return false;
    }
  }

  void onDisconnected() {
    debugPrint('EMQX Disconnected');
  }
}