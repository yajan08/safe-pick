import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  final client = MqttServerClient.withPort('x6ee8611.ala.asia-southeast1.emqxsl.com', 'test_client_publish', 8883);
  client.secure = true;
  client.securityContext = SecurityContext.defaultContext;
  client.onBadCertificate = (dynamic cert) => true;
  
  client.logging(on: true);
  
  final connMess = MqttConnectMessage()
      .withClientIdentifier('test_client_publish')
      .authenticateAs('safepick_app_client', 'Emqxpassword@1')
      .startClean();
  
  client.connectionMessage = connMess;

  try {
    stdout.writeln('Connecting...');
    await client.connect();
  } catch (e) {
    stdout.writeln('Exception: $e');
    client.disconnect();
    return;
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    stdout.writeln('Connected! Publishing message...');
    
    final topic = 'safepick/trips/test/telemetry';
    final builder = MqttClientPayloadBuilder();
    builder.addString('{"lat": 1.0, "lng": 2.0}');
    
    // Subscribe first to see if we get our own message
    client.subscribe(topic, MqttQos.atMostOnce);
    
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      stdout.writeln('Received: $pt from topic: ${c[0].topic}');
    });

    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    
    await Future.delayed(Duration(seconds: 5));
    client.disconnect();
    stdout.writeln('Disconnected.');
  } else {
    stdout.writeln('Failed to connect, status: ${client.connectionStatus}');
  }
}
