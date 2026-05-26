import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../students/data/student_model.dart';
import '../data/trip_model.dart';
import '../data/trip_manifest_model.dart';
import '../../../core/utils/snackbar_utils.dart';

class EditTripScreen extends ConsumerStatefulWidget {
  final TripModel trip;
  final List<TripManifestModel> initialManifest;

  const EditTripScreen({
    super.key,
    required this.trip,
    required this.initialManifest,
  });

  @override
  ConsumerState<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends ConsumerState<EditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _durationController;
  late TextEditingController _vehicleController;
  
  late String _tripType;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  final List<StudentModel> _roster = [];
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip.tripName);
    _durationController = TextEditingController(text: widget.trip.estimatedDuration.replaceAll(RegExp(r'[^0-9]'), ''));
    _vehicleController = TextEditingController();
    _tripType = widget.trip.tripType.toLowerCase() == 'pickup' ? 'pickup' : 'dropoff';
    
    // Parse time
    try {
      if (widget.trip.approxStartTime.isNotEmpty) {
        final timeParts = widget.trip.approxStartTime.split(' ');
        final isPM = timeParts.length > 1 && timeParts[1].toUpperCase() == 'PM';
        final hm = timeParts[0].split(':');
        int h = int.parse(hm[0]);
        final m = int.parse(hm[1]);
        if (isPM && h < 12) h += 12;
        if (!isPM && h == 12) h = 0;
        _selectedTime = TimeOfDay(hour: h, minute: m);
      }
    } catch (_) {}

    _initRoster();
    _loadDriverProfile();
  }

  void _initRoster() {
    for (final m in widget.initialManifest) {
      _roster.add(StudentModel(
        studentId: m.studentId,
        parentUid: '',
        name: m.name,
        schoolId: m.schoolId,
        schoolName: m.schoolName,
        grade: '',
        status: 'active',
        stats: const {},
      ));
    }
  }

  Future<void> _loadDriverProfile() async {
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user != null) {
        final doc = await ref.read(firestoreProvider).collection('users').doc(user.uid).get();
        if (doc.exists) {
          _vehicleController.text = doc.data()?['vehicle_number'] ?? '';
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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

  Future<void> _openStudentSelector() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Select Students',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(color: AppTheme.border, height: 1),
                    Expanded(
                      child: FutureBuilder(
                        future: ref.read(firestoreProvider).collection('students').get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
                          }
                          if (snapshot.hasError) {
                            return const Center(child: Text('Error loading students', style: TextStyle(color: AppTheme.errorRed)));
                          }
                          
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Center(child: Text('No students found.'));
                          }

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final student = StudentModel.fromJson(doc.data(), doc.id);
                              final isSelected = _roster.any((s) => s.studentId == student.studentId);

                              return CheckboxListTile(
                                activeColor: AppTheme.primaryGold,
                                checkColor: AppTheme.background,
                                title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(student.studentId),
                                value: isSelected,
                                onChanged: (value) {
                                  setStateSheet(() {
                                    if (value == true) {
                                      _roster.add(student);
                                    } else {
                                      _roster.removeWhere((s) => s.studentId == student.studentId);
                                    }
                                  });
                                  setState(() {}); 
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Done'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _submitTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTime == null) {
      SnackBarUtils.showError(context, 'Please pick an approximate start time.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final firestore = ref.read(firestoreProvider);
      
      final docRef = firestore.collection('trips').doc(widget.trip.tripId);
      final durationMins = int.parse(_durationController.text.trim());
      final formattedTime = _selectedTime!.format(context);

      final batch = firestore.batch();
      
      batch.update(docRef, {
        'trip_name': _nameController.text.trim(),
        'trip_type': _tripType,
        'estimated_duration': '$durationMins mins',
        'approx_start_time': formattedTime,
      });

      // Clear existing manifest
      final existingManifest = await docRef.collection('trip_manifest').get();
      for (final doc in existingManifest.docs) {
        batch.delete(doc.reference);
      }

      // Write new roster to manifest
      for (int i = 0; i < _roster.length; i++) {
        final student = _roster[i];
        final manifestRef = docRef.collection('trip_manifest').doc(student.studentId);
        final manifestModel = TripManifestModel(
          studentId: student.studentId,
          stopOrder: i + 1,
          expectedTime: formattedTime,
          status: 'pending',
          schoolId: student.schoolId,
          schoolName: student.schoolName,
          name: student.name,
        );
        batch.set(manifestRef, manifestModel.toJson());
      }

      await batch.commit();

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Trip "${_nameController.text.trim()}" updated!',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to update trip: $e');
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
        title: const Text('Edit Trip'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
            : Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  children: [
                    Text(
                      'Edit Route',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fade().slideY(begin: 0.1),
                    const SizedBox(height: 8),
                    Text(
                      'Modify details and roster for this template.',
                      style: theme.textTheme.bodyMedium,
                    ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Trip Name',
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

                    DropdownButtonFormField<String>(
                      initialValue: _tripType,
                      decoration: const InputDecoration(
                        labelText: 'Trip Type',
                        prefixIcon: Icon(Icons.merge_type_rounded, color: AppTheme.textSecondary),
                      ),
                      dropdownColor: AppTheme.surface,
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

                    TextFormField(
                      controller: _vehicleController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Number',
                        prefixIcon: Icon(Icons.directions_car_rounded, color: AppTheme.textSecondary),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ).animate().fade(delay: 350.ms).slideY(begin: 0.1),

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
                      'Edit Roster',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _openStudentSelector,
                        icon: const Icon(Icons.group_add_rounded, color: AppTheme.primaryGold),
                        label: const Text(
                          'Select Students',
                          style: TextStyle(color: AppTheme.primaryGold, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryGold, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
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
                            'No students added yet.\nSelect students to build your manifest.',
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
                      : Text('Save Updates (${_roster.length} Students)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
