import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';

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
  final _vehicleNumberController = TextEditingController();

  String _selectedRole = 'Parent';
  String _selectedGender = 'Male';
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

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
        SnackBarUtils.showSuccess(context, 'Account registered successfully!');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.toString());
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
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/images/light_logo.jpg',
                    height: 100,
                  ),
                ).animate().fade().slideY(begin: -0.1),
                const SizedBox(height: 16),

                // Welcome Text
                Text(
                  'Join SafePick',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fade().slideY(begin: -0.1),
                const SizedBox(height: 8),
                Text(
                  'Register to track rides and manage check-ins',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ).animate().fade(delay: 100.ms).slideY(begin: -0.1),
                const SizedBox(height: 36),

                // Registration Form Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Role Dropdown Selection
                          DropdownButtonFormField<String>(
                            initialValue: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Select Role',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            dropdownColor: AppTheme.surface,
                            style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textPrimary),
                            items: const [
                              DropdownMenuItem(
                                value: 'Parent',
                                child: Text('Parent'),
                              ),
                              DropdownMenuItem(
                                value: 'Driver',
                                child: Text('Driver'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedRole = value;
                                });
                              }
                            },
                          ).animate().fade(delay: 150.ms),
                          const SizedBox(height: 18),

                          // Full Name Input
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Enter your full name',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              if (value.trim().length < 3) {
                                return 'Name must be at least 3 characters';
                              }
                              return null;
                            },
                          ).animate().fade(delay: 200.ms),
                          const SizedBox(height: 18),
                          
                          // Gender Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.wc_rounded),
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
                                setState(() {
                                  _selectedGender = value;
                                });
                              }
                            },
                          ).animate().fade(delay: 250.ms),
                          const SizedBox(height: 18),

                          // Dynamic Vehicle Number for Driver
                          AnimatedSize(
                            duration: 300.ms,
                            curve: Curves.easeInOut,
                            child: isDriver
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 18.0),
                                    child: TextFormField(
                                      controller: _vehicleNumberController,
                                      textCapitalization: TextCapitalization.characters,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'Vehicle Number',
                                        hintText: 'e.g. MH12AB1234',
                                        prefixIcon: Icon(Icons.directions_car_rounded),
                                      ),
                                      validator: (value) {
                                        if (isDriver && (value == null || value.trim().isEmpty)) {
                                          return 'Please enter your vehicle number';
                                        }
                                        return null;
                                      },
                                    ).animate().fade(),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // Phone Number Input
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              hintText: 'Enter your phone number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              // Basic international phone regex
                              final phoneRegExp = RegExp(r'^\+?[0-9]{10,14}$');
                              if (!phoneRegExp.hasMatch(value.trim().replaceAll(' ', ''))) {
                                return 'Please enter a valid phone number';
                              }
                              return null;
                            },
                          ).animate().fade(delay: 300.ms),
                          const SizedBox(height: 18),

                          // Email Input
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'Enter your email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegExp = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              );
                              if (!emailRegExp.hasMatch(value.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ).animate().fade(delay: 350.ms),
                          const SizedBox(height: 18),

                          // Password Input
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Create a password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey,
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
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ).animate().fade(delay: 400.ms),
                          const SizedBox(height: 28),

                          // Submit Sign Up Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignUp,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.background,
                                        ),
                                      ),
                                    )
                                  : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ).animate().fade(delay: 450.ms).scale(begin: const Offset(0.95, 0.95)),
                        ],
                      ),
                    ),
                  ),
                ).animate().fade(delay: 150.ms).slideY(begin: 0.1),
                const SizedBox(height: 24),

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
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
