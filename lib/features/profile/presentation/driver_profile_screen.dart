import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';

class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  String _selectedGender = 'Male';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user != null) {
        final doc = await ref.read(firestoreProvider).collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _vehicleController.text = data['vehicle_number'] ?? '';
          
          final gender = data['gender'] ?? 'Male';
          if (['Male', 'Female', 'Other'].contains(gender)) {
            _selectedGender = gender;
          }
        }
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Failed to load profile');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user != null) {
        await ref.read(firestoreProvider).collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'gender': _selectedGender,
          'vehicle_number': _vehicleController.text.trim(),
        });
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'Profile updated successfully!');
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Failed to update profile: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold)))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, size: 50, color: AppTheme.primaryGold),
                        ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack),
                      ),
                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.wc_rounded),
                        ),
                        dropdownColor: AppTheme.surface,
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedGender = v);
                        },
                      ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _vehicleController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Number',
                          prefixIcon: Icon(Icons.directions_car_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
                      const SizedBox(height: 48),

                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 24, width: 24,
                                  child: CircularProgressIndicator(color: AppTheme.background, strokeWidth: 2.5),
                                )
                              : const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ).animate().fade(delay: 600.ms),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
