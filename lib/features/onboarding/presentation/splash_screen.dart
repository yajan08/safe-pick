import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/presentation/auth_gate.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for the animation to play
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final showOnboarding = !(prefs.getBool('onboarding_complete') ?? false);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            showOnboarding ? const OnboardingScreen() : const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Hero(
          tag: 'app_logo',
          child: Image.asset(
            'assets/images/light_logo.jpg',
            height: 100,
          ),
        ).animate()
         .fadeIn(duration: 400.ms)
         .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), duration: 500.ms, curve: Curves.easeOut)
         .shimmer(delay: 500.ms, duration: 800.ms, color: Colors.white24),
      ),
    );
  }
}
