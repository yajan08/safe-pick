import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for input formatters
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../domain/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_gate.dart'; 

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  // --- Login Controllers ---
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginObscurePass = true;
  bool _isLoginLoading = false;
  String? _loginError;

  // --- Sign Up Controllers & State ---
  int _signupStep = 0; // 0: Basic Info, 1: Credentials
  
  final _signupFormKeyStep0 = GlobalKey<FormState>();
  final _signupFormKeyStep1 = GlobalKey<FormState>();
  
  final _signupNameCtrl = TextEditingController();
  final _signupPhoneCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPassCtrl = TextEditingController();
  final _signupConfirmPassCtrl = TextEditingController();
  final _vehicleNumberCtrl = TextEditingController();

  final String _selectedRole = 'Parent';
  String _selectedGender = 'Male';
  bool _signupObscurePass = true;
  bool _signupObscureConfirmPass = true;
  bool _isSignupLoading = false;
  String? _signupError;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _slideAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _animController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _signupNameCtrl.dispose();
    _signupPhoneCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPassCtrl.dispose();
    _signupConfirmPassCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    super.dispose();
  }

  void _toggleView() {
    FocusScope.of(context).unfocus();
    if (_animController.isCompleted) {
      _animController.reverse(); // Drive back to Login
      // Reset signup step silently after transition
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() { _signupStep = 0; _signupError = null; });
      });
    } else {
      _animController.forward(); // Drive to Sign Up
    }
  }

  // --- Authentication Handlers ---
  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() { _isLoginLoading = true; _loginError = null; });
    
    try {
      await ref.read(authServiceProvider).signIn(
        _loginEmailCtrl.text.trim(),
        _loginPassCtrl.text,
      );
      _routeToAuthGate();
    } catch (e) {
      if (mounted) setState(() => _loginError = 'Login failed. Please verify your credentials and try again.');
    } finally {
      if (mounted) setState(() => _isLoginLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    if (!_signupFormKeyStep1.currentState!.validate()) return;
    setState(() { _isSignupLoading = true; _signupError = null; });
    
    try {
      await ref.read(authServiceProvider).signUp(
        email: _signupEmailCtrl.text.trim(),
        password: _signupPassCtrl.text,
        name: _signupNameCtrl.text.trim(),
        phone: _signupPhoneCtrl.text.trim(),
        role: _selectedRole,
        gender: _selectedGender,
        vehicleNumber: _selectedRole == 'Driver' ? _vehicleNumberCtrl.text.trim() : null,
      );
      _routeToAuthGate();
    } catch (e) {
      if (mounted) setState(() => _signupError = 'Signup failed. Please try again or check your connection.');
    } finally {
      if (mounted) setState(() => _isSignupLoading = false);
    }
  }

  void _routeToAuthGate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      body: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          final progress = _slideAnimation.value;
          
          return Stack(
            children: [
              // 1. Full-Screen Cinematic Parallax Background
              Positioned.fill(
                child: CustomPaint(
                  painter: _TransportScenePainter(progress: progress),
                ),
              ),

              // 2. Sliding Login Form
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(-progress * size.width, 0),
                  child: Opacity(
                    opacity: 1.0 - (progress * 1.5).clamp(0.0, 1.0),
                    child: IgnorePointer(
                      ignoring: progress > 0.1,
                      child: _buildLoginForm(context),
                    ),
                  ),
                ),
              ),

              // 3. Sliding Sign Up Form
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(size.width - (progress * size.width), 0),
                  child: Opacity(
                    opacity: ((progress - 0.2) * 1.25).clamp(0.0, 1.0),
                    child: IgnorePointer(
                      ignoring: progress < 0.9,
                      child: _buildSignUpWizard(context),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // LOGIN UI
  // ==========================================
  Widget _buildLoginForm(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 140.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SvgPicture.asset('assets/images/logo.svg', height: 72),
              const SizedBox(height: 24),
              Text('Welcome Back', style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Secure school transport tracking', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 32),

              Container(
                decoration: _glassDecoration(),
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _loginFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _loginEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) => v!.isEmpty ? 'Enter email' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _loginPassCtrl,
                        obscureText: _loginObscurePass,
                        onFieldSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_loginObscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.textMuted, size: 20),
                            onPressed: () => setState(() => _loginObscurePass = !_loginObscurePass),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter password' : null,
                      ),
                      if (_loginError != null) ...[
                        const SizedBox(height: 20),
                        _buildErrorBanner(_loginError!),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoginLoading ? null : _handleLogin,
                        child: _isLoginLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign In'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?", style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed: _toggleView,
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGoldDark, textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SIGN UP WIZARD UI
  // ==========================================
  Widget _buildSignUpWizard(BuildContext context) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 140.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SvgPicture.asset('assets/images/logo.svg', height: 64),
              const SizedBox(height: 20),
              Text('Join SafePick', style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Register to track rides and manage check-ins', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 32),

              Container(
                decoration: _glassDecoration(),
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Wizard Header with Back Button
                    Row(
                      children: [
                        _signupStep > 0
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                              onPressed: () => setState(() { _signupStep--; _signupError = null; }),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                          : const SizedBox(width: 18),
                        Expanded(
                          child: Text(
                            'Step ${_signupStep + 1} of 2',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 18), // Balance alignment
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Wizard Content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _buildWizardStep(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?', style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed: _toggleView,
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGoldDark, textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWizardStep() {
    switch (_signupStep) {
      case 0:
        return Form(
          key: _signupFormKeyStep0,
          child: Column(
            key: const ValueKey('step0'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_rounded, size: 20)),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _selectedGender = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _signupNameCtrl,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
                validator: (v) => v!.trim().isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _signupPhoneCtrl,
                keyboardType: TextInputType.number, // Numerical keypad
                inputFormatters: [LengthLimitingTextInputFormatter(10)], // Max 10 digits
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined, size: 20)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your phone number';
                  if (v.trim().length < 10) return 'Enter a valid 10-digit number';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_signupFormKeyStep0.currentState!.validate()) setState(() => _signupStep = 1);
                },
                child: const Text('Next'),
              ),
            ],
          ),
        );
      case 1:
      default:
        final isDriver = _selectedRole == 'Driver';
        return Form(
          key: _signupFormKeyStep1,
          child: Column(
            key: const ValueKey('step1'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _signupEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined, size: 20)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _signupPassCtrl,
                obscureText: _signupObscurePass,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_signupObscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.textMuted, size: 20),
                    onPressed: () => setState(() => _signupObscurePass = !_signupObscurePass),
                  ),
                ),
                validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _signupConfirmPassCtrl,
                obscureText: _signupObscureConfirmPass,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_signupObscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.textMuted, size: 20),
                    onPressed: () => setState(() => _signupObscureConfirmPass = !_signupObscureConfirmPass),
                  ),
                ),
                validator: (v) => v != _signupPassCtrl.text ? 'Passwords do not match' : null,
              ),
              if (isDriver) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehicleNumberCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Vehicle Number', hintText: 'e.g. MH12AB1234', prefixIcon: Icon(Icons.directions_car_rounded, size: 20)),
                  validator: (v) => isDriver && v!.trim().isEmpty ? 'Required for drivers' : null,
                ),
              ],
              if (_signupError != null) ...[
                const SizedBox(height: 20),
                _buildErrorBanner(_signupError!),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSignupLoading ? null : _handleSignUp,
                child: _isSignupLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Account'),
              ),
            ],
          ),
        );
    }
  }

  // --- Shared UI Helpers ---
  BoxDecoration _glassDecoration() {
    return BoxDecoration(
      color: AppTheme.surfaceCard.withValues(alpha: 0.90),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8)),
      ],
      border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
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
          Expanded(child: Text(message, style: const TextStyle(color: AppTheme.errorRed, fontSize: 13))),
        ],
      ),
    ).animate().fade().slideX(begin: 0.1, end: 0);
  }
}

// ==========================================
// CINEMATIC PARALLAX PAINTER
// ==========================================
class _TransportScenePainter extends CustomPainter {
  final double progress; 
  _TransportScenePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double groundY = h - 90; 
    final double scale = w / 400.0; 

    // 1. Static Sky Gradient
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFF0F9FF), Color(0x99BAE6FD)], 
      ).createShader(Rect.fromLTWH(0, 0, w, groundY));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, groundY), skyPaint);

    // 2. Parallax Sky Elements
    double skyPan = progress * w * 0.3; 
    canvas.save();
    canvas.translate(-skyPan, 0);
    canvas.drawCircle(Offset(w * 0.85, 120), 14 * scale, Paint()..color = const Color(0xE6FDE047));
    canvas.drawCircle(Offset(w * 0.85, 120), 9 * scale, Paint()..color = const Color(0xFFFACC15));
    
    final Paint cloudPaint = Paint()..color = const Color(0x99E0F2FE);
    _drawCloud(canvas, w * 0.25, 90, scale, cloudPaint);
    _drawCloud(canvas, w * 0.70, 160, scale, cloudPaint);
    _drawCloud(canvas, w * 1.3, 100, scale, cloudPaint);
    canvas.restore();

    // 3. Dynamic Moving World
    canvas.save();
    canvas.translate(-progress * w, 0);

    final Paint roadPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF475569), Color(0xFF334155)],
      ).createShader(Rect.fromLTWH(0, groundY, w * 2, h - groundY));
    canvas.drawRect(Rect.fromLTWH(0, groundY, w * 2, h - groundY), roadPaint);
    canvas.drawRect(Rect.fromLTWH(0, groundY - 2, w * 2, 3), Paint()..color = const Color(0xFF1E293B).withValues(alpha: 0.4));
    
    final Paint dashPaint = Paint()..color = const Color(0xCCFACC15)..strokeWidth = 2 * scale..strokeCap = StrokeCap.round;
    double dashOffset = (progress * w * 3) % (45 * scale);
    for (double i = -dashOffset; i < w * 2; i += (45 * scale)) {
      canvas.drawLine(Offset(i, groundY + (h - groundY) * 0.35), Offset(i + (25 * scale), groundY + (h - groundY) * 0.35), dashPaint);
    }

    // Scene 1: Login
    _drawEntity(canvas, w * 0.05, groundY, scale, _drawSchool);
    _drawEntity(canvas, w * 0.28, groundY, scale, (c) => _drawTree(c, 1.0));
    _drawEntity(canvas, w * 0.38, groundY, scale, _drawKid);
    _drawEntity(canvas, w * 0.82, groundY, scale, _drawHouse);
    _drawEntity(canvas, w * 0.94, groundY, scale, _drawParent);

    // Scene 2: Sign Up
    _drawEntity(canvas, w * 1.15, groundY, scale, (c) => _drawTree(c, 1.2)); 
    _drawEntity(canvas, w * 1.35, groundY, scale, _drawHouseVariant); 
    _drawEntity(canvas, w * 1.65, groundY, scale, (c) => _drawTree(c, 0.9));
    _drawEntity(canvas, w * 1.80, groundY, scale, _drawKidAndParent); 

    // 4. The Bus 
    double busScreenAnchor = w * 0.48; 
    double busWorldX = busScreenAnchor + (progress * w);
    
    double bobbingOffset = sin(progress * pi * 12) * 0.5 * scale; 
    
    _drawEntity(canvas, busWorldX, groundY + bobbingOffset, scale, _drawBus);

    canvas.restore();
  }

  void _drawEntity(Canvas canvas, double x, double y, double scale, Function(Canvas) drawFn) {
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale, scale);
    drawFn(canvas);
    canvas.restore();
  }

  void _drawCloud(Canvas canvas, double cx, double cy, double scale, Paint paint) {
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 44 * scale, height: 18 * scale), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 18 * scale, cy - 4 * scale), width: 34 * scale, height: 18 * scale), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 16 * scale, cy - 2 * scale), width: 30 * scale, height: 16 * scale), paint);
  }

  void _drawSchool(Canvas canvas) {
    final bld = Paint()..color = const Color(0xFFE0F2FE);
    final roof = Paint()..color = const Color(0xFF7DD3FC);
    final winDark = Paint()..color = const Color(0xFFBAE6FD);
    final winLight = Paint()..color = const Color(0xCCFDE047);

    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, -40, 62, 40), const Radius.circular(2)), bld);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, -45, 72, 8), const Radius.circular(2)), roof);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(23, -20, 12, 20), const Radius.circular(2)), roof);
    canvas.drawCircle(const Offset(33, -10), 1.5, Paint()..color = const Color(0xFF0EA5E9));
    
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(11, -33, 9, 9), const Radius.circular(1)), winDark);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, -33, 9, 9), const Radius.circular(1)), winDark);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(37, -33, 9, 9), const Radius.circular(1)), winLight);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(50, -33, 9, 9), const Radius.circular(1)), winDark);
  }

  void _drawTree(Canvas canvas, double sizeMult) {
    final trunk = Paint()..color = const Color(0xFF92400E);
    final leavesMain = Paint()..color = const Color(0xFF4ADE80);
    final leavesAccent = Paint()..color = const Color(0xFF22C55E);

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, -16 * sizeMult, 4, 16 * sizeMult), const Radius.circular(1)), trunk);
    canvas.drawOval(Rect.fromLTWH(-7, -40 * sizeMult, 18, 26 * sizeMult), leavesMain);
    canvas.drawOval(Rect.fromLTWH(-4.5, -45 * sizeMult, 13, 18 * sizeMult), leavesAccent);
  }

  void _drawKid(Canvas canvas) {
    final skin = Paint()..color = const Color(0xFFFEF08A);
    final shirt = Paint()..color = const Color(0xFF6366F1);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, -10, 4, 10), const Radius.circular(2)), skin);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9, -10, 4, 10), const Radius.circular(2)), skin);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, -22, 10, 12), const Radius.circular(2.5)), shirt);
    canvas.drawCircle(const Offset(8, -28), 6, skin);
  }

  void _drawHouse(Canvas canvas) {
    final bld = Paint()..color = const Color(0xFFE0F2FE);
    final roof = Paint()..color = const Color(0xFF7DD3FC);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, -32, 42, 32), const Radius.circular(2)), bld);
    canvas.drawPath(Path()..moveTo(-2, -32)..lineTo(44, -32)..lineTo(21, -52)..close(), roof);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, -22, 10, 22), const Radius.circular(2)), roof);
  }

  void _drawHouseVariant(Canvas canvas) {
    final bld = Paint()..color = const Color(0xFFF1F5F9);
    final roof = Paint()..color = const Color(0xFFF43F5E);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, -38, 50, 38), const Radius.circular(2)), bld);
    canvas.drawPath(Path()..moveTo(-4, -38)..lineTo(54, -38)..lineTo(25, -60)..close(), roof);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, -20, 10, 20), const Radius.circular(2)), Paint()..color = const Color(0xFF94A3B8));
  }

  void _drawParent(Canvas canvas) {
    final skin = Paint()..color = const Color(0xFFFEF08A);
    final shirt = Paint()..color = const Color(0xFFF472B6);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, -10, 4, 10), const Radius.circular(2)), skin);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9, -10, 4, 10), const Radius.circular(2)), skin);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, -22, 10, 12), const Radius.circular(2.5)), shirt);
    canvas.drawCircle(const Offset(8, -28), 6, skin);
  }

  void _drawKidAndParent(Canvas canvas) {
    _drawParent(canvas);
    canvas.save();
    canvas.translate(16, 0); 
    _drawKid(canvas);
    canvas.restore();
  }

  void _drawBus(Canvas canvas) {
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, -35, 82, 30), const Radius.circular(4)), Paint()..color = const Color(0xFFFACC15));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(64, -32, 18, 22), const Radius.circular(3)), Paint()..color = const Color(0xFFEAB308));
    
    final winPaint = Paint()..color = const Color(0xFFBAE6FD);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(66, -30, 13, 14), const Radius.circular(2)), winPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, -32, 10, 8), const Radius.circular(1.5)), winPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(19, -32, 10, 8), const Radius.circular(1.5)), winPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(33, -32, 10, 8), const Radius.circular(1.5)), winPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(47, -32, 10, 8), const Radius.circular(1.5)), winPaint);
    
    canvas.drawRect(const Rect.fromLTWH(0, -25, 82, 3), Paint()..color = const Color(0x331E293B));
    canvas.drawRect(const Rect.fromLTWH(0, -17, 82, 3), Paint()..color = const Color(0x331E293B));
    
    final tire = Paint()..color = const Color(0xFF1E293B);
    final rim = Paint()..color = const Color(0xFF64748B);
    canvas.drawCircle(const Offset(18, -3), 8, tire);
    canvas.drawCircle(const Offset(18, -3), 4, rim);
    canvas.drawCircle(const Offset(66, -3), 8, tire);
    canvas.drawCircle(const Offset(66, -3), 4, rim);
  }

  @override
  bool shouldRepaint(covariant _TransportScenePainter oldDelegate) => oldDelegate.progress != progress;
}
