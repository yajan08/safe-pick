import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/splash_screen.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized prior to Firebase boots
  WidgetsFlutterBinding.ensureInitialized();
  

  // Initialize Firebase connection (Firebase Auth)
  // In Phase 3, you will configure your specific firebase_options.dart using FlutterFire CLI.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // We log the initialization error. In case the config files (e.g. google-services.json)
    // are missing, the AuthGate will handle the error gracefully via StreamProvider catch states.
    debugPrint("Firebase initialization warning/error: $e");
  }

  runApp(
    ProviderScope(
      child: const SafePickApp(),
    ),
  );
}

class SafePickApp extends StatelessWidget {
  const SafePickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafePick',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Automatically switch between Light and Dark mode
      home: const SplashScreen(),
    );
  }
}
