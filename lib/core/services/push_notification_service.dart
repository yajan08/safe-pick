import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // 1. Set the background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request permissions
    await _requestPermission();

    // 3. Get the token and save it to Firestore
    await _saveTokenToDatabase();

    // 4. Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) {
      _saveTokenToDatabase(newToken);
    });

    // 5. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // Optional: show a local notification here if needed using flutter_local_notifications
      }
    });
  }

  Future<void> _requestPermission() async {
    // For Android 13+, request POST_NOTIFICATIONS permission
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        debugPrint('Notification permissions denied.');
        return;
      }
    }

    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _saveTokenToDatabase([String? token]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final fcmToken = token ?? await _fcm.getToken();
      if (fcmToken != null) {
        debugPrint('Saving FCM Token: $fcmToken');
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': fcmToken,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }
}
