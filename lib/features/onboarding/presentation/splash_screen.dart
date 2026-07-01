import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:safe_pick/features/auth/presentation/auth_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // Increased duration to 2.8 seconds to allow the full, elegant animation sequence to finish
    await Future.delayed(const Duration(milliseconds: 2800));
    
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final showOnboarding = !(prefs.getBool('onboarding_complete') ?? false);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            showOnboarding ? const OnboardingScreen() : const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slowed down the route transition slightly for a calmer feel
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Hero(
          tag: 'app_logo',
          child: SvgPicture.asset(
            'assets/images/logo.svg',
            height: 100,
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms, curve: Curves.easeOut)
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.0, 1.0),
              duration: 1000.ms,
              curve: Curves.easeOutCubic,
            )
            .slideY(
              begin: 0.05,
              end: 0,
              duration: 1000.ms,
              curve: Curves.easeOutCubic,
            )
            .shimmer(
              delay: 800.ms,
              duration: 1000.ms,
              color: Colors.white24,
            ),
      ),
    );
  }
}