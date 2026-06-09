import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import 'sign_up_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // AuthGate handles redirection automatically.
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // 1. Literal, Subtle Background Illustration (Bus, Kid, Road)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.35,
            child: CustomPaint(
              painter: _TransportScenePainter(),
            ).animate().fade(duration: 800.ms).slideY(begin: -0.1, end: 0, curve: Curves.easeOut),
          ),

          // 2. Main Scrollable Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40), 

                    // --- Branding Section ---
                    Hero(
                      tag: 'app_logo',
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        height: 72,
                      ),
                    ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack).fade(),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Welcome Back',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Secure school transport tracking',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 40),

                    // --- Login Form Card ---
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email Input
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  hintText: 'Enter your registered email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 20),

                              // Password Input
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _handleLogin(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                      color: AppTheme.textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) return 'Password is too short';
                                  return null;
                                },
                              ),

                              // Error Banner
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorRed.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.errorRed,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fade().slideX(begin: 0.1, end: 0),
                              ],

                              const SizedBox(height: 32),

                              // Submit Button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text('Sign In'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(delay: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: 32),

                    // --- Sign Up Link ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const SignUpScreen()),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryGoldDark,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ).animate().fade(delay: 600.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A Custom Painter that draws a subtle, stylized school transport scene.
class _TransportScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Colors kept very transparent to remain elegant and not overpower the UI
    final Paint solidBrand = Paint()..color = AppTheme.primaryGold.withValues(alpha: 0.15);
    final Paint softBrand = Paint()..color = AppTheme.primaryGold.withValues(alpha: 0.08);
    final Paint darkNeutral = Paint()..color = AppTheme.textSecondary.withValues(alpha: 0.05);

    // 1. Sky/Base Gradient
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryGoldLight.withValues(alpha: 0.10),
          AppTheme.background.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    final double groundY = size.height * 0.75;

    // 2. Simple Stylized Trees in Background
    // Tree 1
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.15, groundY - 60, 30, 60), const Radius.circular(15)),
      softBrand,
    );
    // Tree 2
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.8, groundY - 45, 20, 45), const Radius.circular(10)),
      softBrand,
    );

    // 3. The Road
    canvas.drawRect(Rect.fromLTWH(0, groundY, size.width, size.height - groundY), darkNeutral);
    
    // Road Dashed Lines
    final Paint dashPaint = Paint()
      ..color = AppTheme.surface.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, groundY + 15), Offset(i + 20, groundY + 15), dashPaint);
    }

    // 4. Stylized School Bus Silhouette
    final double busX = size.width * 0.35;
    final double busY = groundY - 50;
    
    // Bus Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(busX, busY, 120, 45), const Radius.circular(8)),
      solidBrand,
    );
    // Bus Front Snout
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(busX + 110, busY + 15, 25, 30), const Radius.circular(6)),
      solidBrand,
    );
    
    // Bus Windows (Negative space / darker)
    final Paint windowPaint = Paint()..color = AppTheme.background.withValues(alpha: 0.6);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(busX + 10, busY + 8, 20, 18), const Radius.circular(3)), windowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(busX + 35, busY + 8, 20, 18), const Radius.circular(3)), windowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(busX + 60, busY + 8, 20, 18), const Radius.circular(3)), windowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(busX + 85, busY + 8, 20, 18), const Radius.circular(3)), windowPaint);
    
    // Bus Wheels
    final Paint wheelPaint = Paint()..color = AppTheme.textPrimary.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(busX + 30, busY + 45), 12, wheelPaint);
    canvas.drawCircle(Offset(busX + 105, busY + 45), 12, wheelPaint);

    // 5. Stylized Student / Kid waiting
    final double kidX = size.width * 0.75;
    final double kidY = groundY - 35;
    
    // Head
    canvas.drawCircle(Offset(kidX + 8, kidY), 6, solidBrand);
    // Body (Backpack silhouette)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(kidX, kidY + 8, 16, 20), const Radius.circular(4)),
      solidBrand,
    );
    // Legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(kidX + 2, kidY + 28, 4, 10), const Radius.circular(2)),
      solidBrand,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(kidX + 10, kidY + 28, 4, 10), const Radius.circular(2)),
      solidBrand,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}