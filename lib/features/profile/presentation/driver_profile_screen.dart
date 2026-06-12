import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';

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

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Action Failed', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold, fontSize: 22)),
        content: Text(message, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.textPrimary, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
            ),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
          _vehicleInputController.clear(); // Clear any stale input
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
      _showErrorDialog('Failed to load profile details. Please check your connection.');
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
          throw 'Please add at least one vehicle number.';
        }

        await ref.read(firestoreProvider).collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'gender': _selectedGender,
          'vehicle_numbers': _vehicleNumbers,
          'vehicle_number': _vehicleNumbers.first,
        });
        
        // Silent success: instantly return to read-only view
        if (mounted) {
          setState(() => _isEditing = false);
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to save profile: $e');
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
    final value = _vehicleInputController.text.trim().toUpperCase();
    if (value.isEmpty) return;

    if (_vehicleNumbers.any((vehicle) => vehicle.toUpperCase() == value)) {
      _vehicleInputController.clear();
      return;
    }

    setState(() {
      _vehicleNumbers.add(value);
      _vehicleInputController.clear();
    });
  }

  void _setPrimaryVehicle(int index) {
    if (index == 0) return;
    setState(() {
      final selectedVehicle = _vehicleNumbers.removeAt(index);
      _vehicleNumbers.insert(0, selectedVehicle);
    });
  }

  void _startEditing() {
    _vehicleInputController.clear(); // Explicitly clear the field
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 24),
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.textPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(0, 48),
            ),
            child: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(firebaseAuthProvider).signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showErrorDialog('Error signing out. Please try again.');
    }
  }

  Future<void> _handleDeleteAccount() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool canDelete = false;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.errorRed, width: 2),
              ),
              title: const Text(
                'Delete Account',
                style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w900, fontSize: 24),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you absolutely sure you want to permanently delete your account and all associated active vehicle profiles? This action cannot be undone.',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      setState(() {
                        canDelete = confirmController.text == 'Delete' && passwordController.text.isNotEmpty;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Type "Delete" to confirm:', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Delete',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setState(() {
                        canDelete = val == 'Delete' && passwordController.text.isNotEmpty;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: canDelete ? () => Navigator.of(context).pop(passwordController.text) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canDelete ? AppTheme.errorRed : AppTheme.errorRed.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('DELETE PERMANENTLY', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );

    if (result == null || result.isEmpty) return;

    try {
      await ref.read(authServiceProvider).deleteDriverAccount(result);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _showErrorDialog('Error deleting account: $e');
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
        title: Text(_isEditing ? 'Edit Profile' : 'Driver Profile', style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: AppTheme.background,
        elevation: 0,
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Subdued Header
                      Center(
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.1),
                          child: const Icon(Icons.person_rounded, size: 48, color: AppTheme.primaryGold),
                        ).animate().scale(delay: 100.ms, curve: Curves.easeOutCubic),
                      ),
                      const SizedBox(height: 24),

                      if (!_isEditing) ...[
                        // ─── READ-ONLY VIEW ───
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.border.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Full Name', _nameController.text, Icons.badge_outlined),
                              const Divider(color: AppTheme.border, height: 32, thickness: 0.5),
                              _buildDetailRow('Email Address', _email, Icons.email_outlined),
                              const Divider(color: AppTheme.border, height: 32, thickness: 0.5),
                              _buildDetailRow('Phone Number', _phoneController.text, Icons.phone_outlined),
                              const Divider(color: AppTheme.border, height: 32, thickness: 0.5),
                              _buildVehicleSummary(),
                            ],
                          ),
                        ).animate().fade(duration: 300.ms),
                        
                        const SizedBox(height: 40),
                        
                        // Action Buttons Stack
                        SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _startEditing,
                            icon: const Icon(Icons.edit_rounded, size: 24),
                            label: const Text('EDIT PROFILE DETAILS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGold,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _handleSignOut,
                            icon: const Icon(Icons.logout_rounded, size: 24),
                            label: const Text('SIGN OUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              side: BorderSide(color: AppTheme.border.withValues(alpha: 0.5), width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _handleDeleteAccount,
                            icon: const Icon(Icons.delete_forever_rounded, size: 24),
                            label: const Text('DELETE ACCOUNT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorRed,
                              side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.5), width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                      ] else ...[
                        // ─── EDIT VIEW ───
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.border.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                              ),
                              const SizedBox(height: 20),

                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                              ),
                              const SizedBox(height: 20),

                              DropdownButtonFormField<String>(
                                initialValue: _selectedGender,
                                decoration: const InputDecoration(
                                  labelText: 'Gender',
                                  prefixIcon: Icon(Icons.wc_rounded),
                                ),
                                dropdownColor: AppTheme.surface,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                items: const [
                                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _selectedGender = v);
                                },
                              ),
                              const SizedBox(height: 32),

                              const Text(
                                'ASSIGNED VEHICLES',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _vehicleInputController,
                                      textCapitalization: TextCapitalization.characters,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      decoration: const InputDecoration(
                                        labelText: 'Vehicle Plate',
                                        hintText: 'e.g. MH12AB1234',
                                        prefixIcon: Icon(Icons.directions_car_rounded),
                                      ),
                                      onFieldSubmitted: (_) => _addVehicleNumber(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    height: 56,
                                    width: 90,
                                    child: ElevatedButton(
                                      onPressed: _addVehicleNumber,
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(0, 56), 
                                        padding: EdgeInsets.zero,
                                        backgroundColor: AppTheme.textPrimary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.w900)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (_vehicleNumbers.isEmpty)
                                const Text(
                                  'No vehicles linked. Please add at least one.',
                                  style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _vehicleNumbers.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _vehicleNumbers[index],
                                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary),
                                              ),
                                              if (index == 0)
                                                const Text(
                                                  'Primary Vehicle',
                                                  style: TextStyle(color: AppTheme.primaryGoldDark, fontSize: 12, fontWeight: FontWeight.w800),
                                                )
                                              else
                                                GestureDetector(
                                                  onTap: () => _setPrimaryVehicle(index),
                                                  child: const Text(
                                                    'Set as Primary',
                                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_rounded, size: 28),
                                            color: AppTheme.errorRed,
                                            onPressed: () => _removeVehicleNumber(index),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ).animate().fade(delay: 100.ms).slideY(begin: 0.05),

                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: _cancelEditing,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 56), 
                                    foregroundColor: AppTheme.textPrimary,
                                    side: BorderSide(color: AppTheme.border.withValues(alpha: 0.5), width: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('CANCEL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(0, 56), 
                                    backgroundColor: AppTheme.primaryGold,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                      : const Text('SAVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
        Icon(icon, color: AppTheme.primaryGold, size: 26),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'Not Provided' : value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSummary() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.directions_car_rounded, color: AppTheme.primaryGold, size: 26),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ASSIGNED VEHICLES',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              if (_vehicleNumbers.isEmpty)
                const Text(
                  'Not Provided',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _vehicleNumbers.map((vehicle) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        vehicle,
                        style: const TextStyle(
                          color: AppTheme.primaryGoldDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}