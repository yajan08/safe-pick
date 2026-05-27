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
  String _email = '';
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user != null) {
        _email = user.email ?? '';
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
          setState(() => _isEditing = false);
        }
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Failed to update profile: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.border, width: 1),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'No',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: AppTheme.background,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(authServiceProvider).signOut();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) SnackBarUtils.showError(context, 'Error signing out: $e');
      }
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Profile'),
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
                          child: const Icon(Icons.person_rounded, size: 50, color: AppTheme.primaryGold),
                        ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack),
                      ),
                      const SizedBox(height: 32),

                      if (!_isEditing) ...[
                        // Read-only User Details Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Full Name', _nameController.text, Icons.person_outline_rounded),
                              const Divider(color: AppTheme.border, height: 24),
                              _buildDetailRow('Email Address', _email, Icons.email_outlined),
                              const Divider(color: AppTheme.border, height: 24),
                              _buildDetailRow('Phone Number', _phoneController.text, Icons.phone_outlined),
                              const Divider(color: AppTheme.border, height: 24),
                              _buildDetailRow('Gender', _selectedGender, Icons.wc_rounded),
                              const Divider(color: AppTheme.border, height: 24),
                              _buildDetailRow('Vehicle Number', _vehicleController.text, Icons.directions_car_outlined),
                            ],
                          ),
                        ).animate().fade(duration: 300.ms),
                        const SizedBox(height: 32),
                        
                        // Edit Details Action Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _isEditing = true),
                            icon: const Icon(Icons.edit_rounded, color: AppTheme.background),
                            label: const Text('Edit Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Sign Out Button
                        SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _handleSignOut,
                            icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
                            label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.errorRed)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.errorRed, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Editable Input Fields
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                        const SizedBox(height: 20),

                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
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
                        ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _vehicleController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Vehicle Number',
                            prefixIcon: Icon(Icons.directions_car_rounded),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: () {
                                    _loadProfile(); // Revert edits
                                    setState(() => _isEditing = false);
                                  },
                                  child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveProfile,
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 24, width: 24,
                                          child: CircularProgressIndicator(color: AppTheme.background, strokeWidth: 2.5),
                                        )
                                      : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ).animate().fade(delay: 500.ms),
                      ]
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryGold, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'Not Provided' : value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
