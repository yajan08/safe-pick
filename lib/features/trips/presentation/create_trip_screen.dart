import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../students/data/student_model.dart';
import '../data/trip_model.dart';
import '../data/trip_manifest_model.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _searchController = TextEditingController();
  
  String _tripType = 'pickup';
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;
  bool _isSearching = false;

  final List<StudentModel> _roster = [];

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGold,
              onPrimary: AppTheme.background,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _searchStudent() async {
    final query = _searchController.text.trim().toUpperCase();
    if (query.isEmpty) return;

    if (_roster.any((s) => s.studentId == query)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student is already in the roster.')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final firestore = ref.read(firestoreProvider);
      final doc = await firestore.collection('students').doc(query).get();
      
      if (doc.exists && doc.data() != null) {
        final student = StudentModel.fromJson(doc.data()!, doc.id);
        setState(() {
          _roster.add(student);
          _searchController.clear();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student ID not found.'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching student: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _submitTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an approximate start time.')),
      );
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
      final formattedTime = _selectedTime!.format(context);

      final newTrip = TripModel(
        tripId: tripId,
        driverUid: currentUser.uid,
        tripName: _nameController.text.trim(),
        tripType: _tripType,
        schoolIds: const ['sch_default_01'],
        status: 'inactive',
        estimatedDuration: '$durationMins mins',
        approxStartTime: formattedTime,
      );

      final batch = firestore.batch();
      batch.set(docRef, newTrip.toJson());

      // Write roster to manifest
      for (int i = 0; i < _roster.length; i++) {
        final student = _roster[i];
        final manifestRef = docRef.collection('trip_manifest').doc(student.studentId);
        final manifestModel = TripManifestModel(
          studentId: student.studentId,
          stopOrder: i + 1,
          expectedTime: formattedTime, // Simplified for now
          status: 'pending',
          schoolId: student.schoolId,
          name: student.name,
        );
        batch.set(manifestRef, manifestModel.toJson());
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip "${newTrip.tripName}" created with ${_roster.length} students!'),
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  children: [
                    // Form Header Description
                    Text(
                      'Set Up a Route',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fade().slideY(begin: 0.1),
                    const SizedBox(height: 8),
                    Text(
                      'Enter details to instantiate a new driving shift and build your roster.',
                      style: theme.textTheme.bodyMedium,
                    ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
                    const SizedBox(height: 32),

                    // Trip Name Field
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Trip Name',
                        hintText: 'e.g. Route A Morning',
                        prefixIcon: Icon(Icons.directions_bus_outlined, color: AppTheme.textSecondary),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name for the trip';
                        }
                        return null;
                      },
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                    const SizedBox(height: 20),

                    // Trip Type Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _tripType,
                      decoration: const InputDecoration(
                        labelText: 'Trip Type',
                        prefixIcon: Icon(Icons.merge_type_rounded, color: AppTheme.textSecondary),
                      ),
                      dropdownColor: AppTheme.surface,
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
                    ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                    const SizedBox(height: 20),

                    // Time Picker & Duration Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(16),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Time',
                                prefixIcon: Icon(Icons.access_time_rounded, color: AppTheme.textSecondary),
                              ),
                              child: Text(
                                _selectedTime?.format(context) ?? 'Select Time',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: _selectedTime != null ? AppTheme.textPrimary : AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duration (Mins)',
                              hintText: 'e.g. 45',
                              prefixIcon: Icon(Icons.timer_outlined, color: AppTheme.textSecondary),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final intValue = int.tryParse(value);
                              if (intValue == null || intValue <= 0) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: 32),

                    const Divider(color: AppTheme.border),
                    const SizedBox(height: 16),
                    Text(
                      'Build Roster',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Student ID',
                              hintText: 'Enter 6-char ID',
                              prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isSearching ? null : _searchStudent,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          child: _isSearching 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Add'),
                        ),
                      ],
                    ).animate().fade(delay: 600.ms).slideY(begin: 0.1),
                    const SizedBox(height: 24),

                    if (_roster.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Center(
                          child: Text(
                            'No students added yet.\nSearch by ID to build your manifest.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                          ),
                        ),
                      ).animate().fade(delay: 700.ms)
                    else
                      ..._roster.map((s) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, color: AppTheme.primaryGold),
                        ),
                        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(s.studentId),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppTheme.errorRed),
                          onPressed: () {
                            setState(() {
                              _roster.remove(s);
                            });
                          },
                        ),
                      )),
                  ],
                ),
              ),

              // Submit Button Area
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppTheme.background,
                  border: Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTrip,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.background),
                          ),
                        )
                      : Text('Save Trip (${_roster.length} Students)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
