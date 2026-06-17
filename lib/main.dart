import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/splash_screen.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized prior to Firebase boots
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
