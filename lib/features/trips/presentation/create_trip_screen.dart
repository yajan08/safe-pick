import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/trip_model.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  
  String _tripType = 'pickup';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submitTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final firestore = ref.read(firestoreProvider);
      final auth = ref.read(firebaseAuthProvider);
      final currentUser = auth.currentUser;

      if (currentUser == null) {
        throw 'Driver user must be logged in to create a trip.';
      }

      final docRef = firestore.collection('trips').doc();
      final tripId = docRef.id;
      final durationMins = int.parse(_durationController.text.trim());

      final newTrip = TripModel(
        tripId: tripId,
        driverUid: currentUser.uid,
        tripName: _nameController.text.trim(),
        tripType: _tripType,
        schoolIds: const ['sch_default_01'],
        status: 'inactive',
        estimatedDuration: '$durationMins mins',
      );

      await docRef.set(newTrip.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip "${newTrip.tripName}" created successfully!'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create trip: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Form Header Description
                Text(
                  'Set Up a Route',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter details to instantiate a new driving shift and manifest roster.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Trip Name Field
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Trip Name',
                    hintText: 'e.g. Route A Morning',
                    prefixIcon: Icon(Icons.directions_bus_outlined, color: AppTheme.textGrey),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name for the trip';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Trip Type Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _tripType,
                  decoration: const InputDecoration(
                    labelText: 'Trip Type',
                    prefixIcon: Icon(Icons.merge_type_rounded, color: AppTheme.textGrey),
                  ),
                  dropdownColor: AppTheme.surfaceDark,
                  iconEnabledColor: AppTheme.primaryGold,
                  items: const [
                    DropdownMenuItem(
                      value: 'pickup',
                      child: Text('Morning Pick-Up'),
                    ),
                    DropdownMenuItem(
                      value: 'dropoff',
                      child: Text('Afternoon Drop-Off'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _tripType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Duration Field
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Duration (Minutes)',
                    hintText: 'e.g. 45',
                    prefixIcon: Icon(Icons.timer_outlined, color: AppTheme.textGrey),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the estimated duration';
                    }
                    final intValue = int.tryParse(value);
                    if (intValue == null || intValue <= 0) {
                      return 'Please enter a valid positive duration in minutes';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTrip,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.bgBlack),
                          ),
                        )
                      : const Text('Create Trip'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
