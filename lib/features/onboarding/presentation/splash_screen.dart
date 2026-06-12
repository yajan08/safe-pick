import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:safe_pick/features/auth/presentation/auth_screen.dart';
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
            showOnboarding ? const OnboardingScreen() : const AuthScreen(),
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- Phase 2: The Full Logo (Symbol + Text) ---
            // This waits in the background, then fades and slides up elegantly
            Hero(
              tag: 'app_logo',
              child: SvgPicture.asset(
                'assets/images/logo.svg',
                height: 100,
              ),
            )
                .animate(delay: 1200.ms) // Wait for the initial van symbol to finish
                .fadeIn(duration: 600.ms, curve: Curves.easeIn)
                .slideY(
                  begin: 0.05, 
                  end: 0, 
                  duration: 600.ms, 
                  curve: Curves.easeOut,
                ) // Subtle upward lift
                .shimmer(
                  delay: 400.ms, 
                  duration: 1000.ms, 
                  color: Colors.white24,
                ),

            // --- Phase 1: The Initial Van Symbol ---
            // Fades in immediately, scales slightly, then fades out
            Image.asset(
              'assets/images/applogo.png',
              height: 85, // Slightly smaller to create an expanding effect when it swaps
            )
                .animate()
                .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.easeOutCubic,
                )
                // Crossfade out exactly as the full logo fades in
                .fadeOut(delay: 1200.ms, duration: 500.ms, curve: Curves.easeIn), 
          ],
        ),
      ),
    );
  }
}