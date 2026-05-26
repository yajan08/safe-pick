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
  late TextEditingController _vehicleController;
  final _studentIdAddController = TextEditingController();
  
  late String _tripType;
  bool _isSubmitting = false;
  bool _isAddingStudent = false;

  final List<StudentModel> _roster = [];
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip.tripName);
    _vehicleController = TextEditingController();
    _tripType = widget.trip.tripType.toLowerCase() == 'pickup' ? 'pickup' : 'dropoff';
    
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
    _vehicleController.dispose();
    _studentIdAddController.dispose();
    super.dispose();
  }

  Future<void> _linkStudentById() async {
    final studentId = _studentIdAddController.text.trim();
    if (studentId.isEmpty) {
      SnackBarUtils.showError(context, 'Please enter a Student ID.');
      return;
    }

    if (_roster.any((s) => s.studentId.toLowerCase() == studentId.toLowerCase())) {
      SnackBarUtils.showError(context, 'Student is already added to this trip.');
      return;
    }

    setState(() {
      _isAddingStudent = true;
    });

    try {
      final doc = await ref.read(firestoreProvider).collection('students').doc(studentId).get();
      if (!doc.exists) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Student ID "$studentId" not found.');
        }
        return;
      }

      final student = StudentModel.fromJson(doc.data()!, doc.id);
      if (mounted) {
        setState(() {
          _roster.add(student);
          _studentIdAddController.clear();
        });
        SnackBarUtils.showSuccess(context, 'Linked ${student.name} successfully.');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to fetch student: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingStudent = false;
        });
      }
    }
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
      
      final docRef = firestore.collection('trips').doc(widget.trip.tripId);
      final durationMins = widget.trip.estimatedDuration;
      final formattedTime = widget.trip.approxStartTime;

      final batch = firestore.batch();
      
      batch.update(docRef, {
        'trip_name': _nameController.text.trim(),
        'trip_type': _tripType,
        'estimated_duration': durationMins,
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

                    const SizedBox(height: 20),

                    const Divider(color: AppTheme.border),
                    const SizedBox(height: 16),
                    Text(
                      'Edit Roster',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: 16),

                    // Add Student by ID Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _studentIdAddController,
                            decoration: const InputDecoration(
                              labelText: 'Link Student by ID',
                              hintText: 'e.g. SP1001',
                              prefixIcon: Icon(Icons.person_add_alt_1_rounded, color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isAddingStudent ? null : _linkStudentById,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGold,
                              foregroundColor: AppTheme.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isAddingStudent
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.background),
                                    ),
                                  )
                                : const Text('Link'),
                          ),
                        ),
                      ],
                    ).animate().fade(delay: 450.ms).slideY(begin: 0.1),
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
