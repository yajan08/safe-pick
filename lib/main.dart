import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized prior to Firebase boots
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check onboarding state
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = !(prefs.getBool('onboarding_complete') ?? false);

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
    // ProviderScope is required to initialize and manage Riverpod state
    ProviderScope(
      child: SafePickApp(showOnboarding: showOnboarding),
    ),
  );
}

class SafePickApp extends StatelessWidget {
  final bool showOnboarding;
  
  const SafePickApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafePick',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Automatically switch between Light and Dark mode
      home: showOnboarding ? const OnboardingScreen() : const AuthGate(),
    );
  }
}
