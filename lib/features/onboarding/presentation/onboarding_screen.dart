import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_gate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLastPage = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top action bar (Skip button)
            Container(
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 16.0, top: 16.0),
              child: TextButton(
                onPressed: () => _completeOnboarding(context),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // PageView content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _isLastPage = (index == 2);
                  });
                },
                children: const [
                  OnboardingPage(
                    iconData: Icons.directions_bus_rounded,
                    title: 'Welcome to SafePick',
                    description: 'The premium school van tracking system for parents and drivers.',
                  ),
                  OnboardingPage(
                    iconData: Icons.security_rounded,
                    title: 'Secure Accounts',
                    description: 'Log in with verified credentials to manage your trips and view student manifests.',
                  ),
                  OnboardingPage(
                    iconData: Icons.verified_user_rounded,
                    title: 'Verified Check-Ins',
                    description: 'Link students securely and guarantee their safety with every ride.',
                  ),
                ],
              ),
            ),

            // Bottom control section
            Container(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 3,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppTheme.primaryGold,
                      dotColor: AppTheme.border,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 4,
                      spacing: 8,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: _isLastPage
                        ? ElevatedButton(
                            onPressed: () => _completeOnboarding(context),
                            child: const Text('Get Started'),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Text('Next'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final IconData iconData; // Using Icons as placeholder for illustrations
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.iconData,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            // Placeholder: When the user provides SVG illustrations, 
            // they can replace this Icon widget with SvgPicture.asset(...)
            child: Icon(
              iconData,
              size: 120,
              color: AppTheme.primaryGold,
            ),
          ),
          const SizedBox(height: 64),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
