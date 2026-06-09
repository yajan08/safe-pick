import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Added controller

  String _selectedRole = 'Parent';
  String _selectedGender = 'Male';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true; // Added state for confirm password
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Added disposal
    _vehicleNumberController.dispose();
    super.dispose();
  }

  // Used for the Driver role
  final _vehicleNumberController = TextEditingController();

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        phone: _phoneController.text,
        role: _selectedRole,
        gender: _selectedGender,
        vehicleNumber: _selectedRole == 'Driver' ? _vehicleNumberController.text : null,
      );

      // On success, AuthGate handles routing automatically.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account registered successfully!'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDriver = _selectedRole == 'Driver';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // --- Scrollable Form Area ---
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Hero(
                      tag: 'app_logo',
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        height: 64, 
                      ),
                    ).animate().fade().slideY(begin: -0.05),
                    
                    const SizedBox(height: 16),

                    Text(
                      'Join SafePick',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fade().slideY(begin: -0.05),
                    
                    const SizedBox(height: 6),
                    
                    Text(
                      'Register to track rides and manage check-ins',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ).animate().fade(delay: 50.ms).slideY(begin: -0.05),
                    
                    const SizedBox(height: 24),

                    // Clean, Bordered Form Container
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Role & Gender Row
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedRole,
                                    decoration: const InputDecoration(
                                      labelText: 'Role',
                                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                                    ),
                                    dropdownColor: AppTheme.surface,
                                    style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary),
                                    items: const [
                                      DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                                      DropdownMenuItem(value: 'Driver', child: Text('Driver')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedRole = value);
                                      }
                                    },
                                  ).animate().fade(delay: 70.ms),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedGender,
                                    decoration: const InputDecoration(
                                      labelText: 'Gender',
                                      prefixIcon: Icon(Icons.wc_rounded, size: 20),
                                    ),
                                    dropdownColor: AppTheme.surface,
                                    style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary),
                                    items: const [
                                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedGender = value);
                                      }
                                    },
                                  ).animate().fade(delay: 90.ms),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),

                            // Dynamic Vehicle Number for Driver
                            AnimatedSize(
                              duration: 300.ms,
                              curve: Curves.easeInOut,
                              child: isDriver
                                  ? Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: TextFormField(
                                        controller: _vehicleNumberController,
                                        textCapitalization: TextCapitalization.characters,
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          labelText: 'Vehicle Number',
                                          hintText: 'e.g. MH12AB1234',
                                          prefixIcon: Icon(Icons.directions_car_rounded, size: 20),
                                        ),
                                        validator: (value) {
                                          if (isDriver && (value == null || value.trim().isEmpty)) {
                                            return 'Please enter vehicle number';
                                          }
                                          return null;
                                        },
                                      ).animate().fade(),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // Full Name Input
                            TextFormField(
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'Enter your full name',
                                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Please enter your name';
                                if (value.trim().length < 3) return 'Name must be at least 3 characters';
                                return null;
                              },
                            ).animate().fade(delay: 110.ms),
                            
                            const SizedBox(height: 16),

                            // Phone Number Input
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                hintText: 'Enter your phone number',
                                prefixIcon: Icon(Icons.phone_outlined, size: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Please enter your phone number';
                                final phoneRegExp = RegExp(r'^\+?[0-9]{10,14}$');
                                if (!phoneRegExp.hasMatch(value.trim().replaceAll(' ', ''))) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                            ).animate().fade(delay: 130.ms),
                            
                            const SizedBox(height: 16),

                            // Email Input
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'Enter your email',
                                prefixIcon: Icon(Icons.email_outlined, size: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Please enter your email';
                                final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                if (!emailRegExp.hasMatch(value.trim())) return 'Enter a valid email address';
                                return null;
                              },
                            ).animate().fade(delay: 150.ms),
                            
                            const SizedBox(height: 16),

                            // Password Input
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Create a password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                                if (value == null || value.isEmpty) return 'Please enter a password';
                                if (value.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                            ).animate().fade(delay: 170.ms),

                            const SizedBox(height: 16),

                            // Confirm Password Input (NEW)
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleSignUp(),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: 'Re-enter your password',
                                prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: AppTheme.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please confirm your password';
                                if (value != _passwordController.text) return 'Passwords do not match';
                                return null;
                              },
                            ).animate().fade(delay: 190.ms),

                          ],
                        ),
                      ),
                    ).animate().fade(delay: 90.ms).slideY(begin: 0.05),
                    
                    const SizedBox(height: 24), 
                  ],
                ),
              ),
            ),
          ),

          // --- Fixed Bottom Section ---
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              border: Border(top: BorderSide(color: AppTheme.border.withValues(alpha: 0.3))),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Submit Sign Up Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.background),
                              ),
                            )
                          : const Text('Create Account'),
                    ),
                  ).animate().fade(delay: 200.ms).scale(begin: const Offset(0.98, 0.98)),
                  
                  const SizedBox(height: 12),

                  // Log In Navigation Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(delay: 220.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}