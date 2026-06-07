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
  final _vehicleInputController = TextEditingController();
  final List<String> _vehicleNumbers = [];
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
          _nameController.text = (data['name'] ?? '').toString();
          _phoneController.text = (data['phone'] ?? '').toString();
          _vehicleNumbers
            ..clear()
            ..addAll(_extractVehicleNumbers(data));
          
          final gender = (data['gender'] ?? 'Male').toString();
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
        if (_vehicleNumbers.isEmpty) {
          throw 'Add at least one vehicle number.';
        }

        await ref.read(firestoreProvider).collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'gender': _selectedGender,
          'vehicle_numbers': _vehicleNumbers,
          'vehicle_number': _vehicleNumbers.first,
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

  List<String> _extractVehicleNumbers(Map<String, dynamic> data) {
    final rawVehicleNumbers = data['vehicle_numbers'];
    if (rawVehicleNumbers is List) {
      final parsed = rawVehicleNumbers
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    final legacyVehicleNumber = (data['vehicle_number'] ?? '').toString().trim();
    if (legacyVehicleNumber.isNotEmpty) {
      return [legacyVehicleNumber];
    }

    return [];
  }

  void _addVehicleNumber() {
    final value = _vehicleInputController.text.trim();
    if (value.isEmpty) return;

    if (_vehicleNumbers.any((vehicle) => vehicle.toLowerCase() == value.toLowerCase())) {
      _vehicleInputController.clear();
      return;
    }

    setState(() {
      _vehicleNumbers.add(value);
      _vehicleInputController.clear();
    });
  }

  void _startEditing() {
    _vehicleInputController.text = _vehicleNumbers.isNotEmpty ? _vehicleNumbers.first : '';
    setState(() => _isEditing = true);
  }

  Future<void> _cancelEditing() async {
    await _loadProfile();
    if (!mounted) return;

    _vehicleInputController.clear();
    setState(() => _isEditing = false);
  }

  void _removeVehicleNumber(int index) {
    setState(() {
      _vehicleNumbers.removeAt(index);
    });
  }

  Future<void> _handleSignOut() async {
    try {
      await ref.read(firebaseAuthProvider).signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Error signing out: $e');
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.errorRed, width: 2),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            color: AppTheme.errorRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you absolutely sure you want to permanently delete your account and all associated active vehicle profiles? This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textPrimary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.background,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(authServiceProvider).deleteDriverAccount();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Error deleting account: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleInputController.dispose();
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
                              _buildVehicleSummary(),
                            ],
                          ),
                        ).animate().fade(duration: 300.ms),
                        const SizedBox(height: 32),
                        
                        // Edit Details Action Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _startEditing,
                            icon: const Icon(Icons.edit_rounded, color: AppTheme.background),
                            label: const Text('Edit Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Sign Out & Delete Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton.icon(
                                  onPressed: _handleSignOut,
                                  icon: const Icon(Icons.logout_rounded, color: AppTheme.textPrimary),
                                  label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton.icon(
                                  onPressed: _handleDeleteAccount,
                                  icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.errorRed),
                                  label: const Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.errorRed)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppTheme.errorRed, width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vehicle Numbers',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16), // Increased spacing
                            TextFormField(
                              controller: _vehicleInputController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Add Vehicle Number',
                                prefixIcon: Icon(Icons.directions_car_rounded),
                              ),
                              onFieldSubmitted: (_) => _addVehicleNumber(),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 56,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _addVehicleNumber,
                                child: const Text('Add'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _vehicleNumbers.isEmpty
                                  ? 'No vehicles added yet.'
                                  : 'Current vehicles are shown below. The first one is saved as the primary vehicle.',
                              style: const TextStyle(color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 8),
                            if (_vehicleNumbers.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (var index = 0; index < _vehicleNumbers.length; index++)
                                    InputChip(
                                      label: Text(_vehicleNumbers[index]),
                                      onDeleted: () => _removeVehicleNumber(index),
                                    ),
                                ],
                              ),
                          ],
                        ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: _cancelEditing,
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

  Widget _buildVehicleSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.directions_car_outlined, color: AppTheme.primaryGold, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Vehicle Numbers',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_vehicleNumbers.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 40),
            child: Text(
              'Not Provided',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < _vehicleNumbers.length; index++)
                  Chip(
                    label: Text(_vehicleNumbers[index]),
                    backgroundColor: AppTheme.background,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
