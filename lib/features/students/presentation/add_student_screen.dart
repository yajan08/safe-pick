
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/student_model.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  final StudentModel? student;

  const AddStudentScreen({super.key, this.student});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _gradeController;
  late final TextEditingController _schoolNameController;
  late final TextEditingController _noteController;
  
  bool _fetchingLocation = false;
  bool _isSubmitting = false;
  GeoPoint? _capturedLocation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student?.name ?? '');
    _gradeController = TextEditingController(text: widget.student?.grade ?? '');
    _schoolNameController = TextEditingController(text: widget.student?.schoolName ?? '');
    _noteController = TextEditingController(text: widget.student?.note ?? '');
    _capturedLocation = widget.student?.homeLocation;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _schoolNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }



  Future<void> _captureLocation() async {
    setState(() {
      _fetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable GPS.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Enable them in settings.';
      } 

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      setState(() {
        _capturedLocation = GeoPoint(position.latitude, position.longitude);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS coordinates captured successfully!'),
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
          _fetchingLocation = false;
        });
      }
    }
  }

  Future<void> _submitStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_capturedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set the home location using current GPS coordinates.'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
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
        throw 'Parent user must be logged in to register a student.';
      }

      final isEditing = widget.student != null;
      final studentId = isEditing 
          ? widget.student!.studentId 
          : await ref.read(authServiceProvider).generateSequentialStudentId();
      
      final studentData = StudentModel(
        studentId: studentId,
        parentUid: currentUser.uid,
        schoolId: isEditing ? widget.student!.schoolId : 'sch_default_01',
        name: _nameController.text.trim(),
        grade: _gradeController.text.trim(),
        schoolName: _schoolNameController.text.trim(),
        note: _noteController.text.trim(),
        homeLocation: _capturedLocation,
        status: isEditing ? widget.student!.status : 'active',
        lastAttendanceStatus: isEditing ? widget.student!.lastAttendanceStatus : 'At Home',
        stats: isEditing ? widget.student!.stats : const {
          'total_trips': 0,
          'attendance_rate': 1.0,
        },
      );

      if (isEditing) {
        await firestore.collection('students').doc(studentId).update(studentData.toJson());
      } else {
        await firestore.collection('students').doc(studentId).set(studentData.toJson());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Student ${studentData.name} updated!' : 'Student ${studentData.name} registered! ID: $studentId'),
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
            content: Text('Failed to save student: $e'),
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
    final isEditing = widget.student != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Student' : 'Add Student'),
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
                // Form Header description
                Text(
                  isEditing ? 'Update Details' : 'Register a Child',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fade(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 8),
                Text(
                  'Provide student details and record their primary pickup/dropoff home location.',
                  style: theme.textTheme.bodyMedium,
                ).animate().fade(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1),
                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter student name',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the student\'s name';
                    }
                    return null;
                  },
                ).animate().fade(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),

                // Grade Field
                TextFormField(
                  controller: _gradeController,
                  decoration: const InputDecoration(
                    labelText: 'Grade / Class',
                    hintText: 'e.g. Grade 5, Grade A',
                    prefixIcon: Icon(Icons.school_outlined, color: AppTheme.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the grade/class';
                    }
                    return null;
                  },
                ).animate().fade(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),

                // School Name Field
                TextFormField(
                  controller: _schoolNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'School Name',
                    hintText: 'e.g. Springfield Elementary',
                    prefixIcon: Icon(Icons.account_balance_outlined, color: AppTheme.textSecondary),
                  ),
                ).animate().fade(duration: 400.ms, delay: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),

                // Note Field
                TextFormField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Special Note',
                    hintText: 'e.g. Needs front seat, allergies, etc.',
                    prefixIcon: Icon(Icons.note_alt_outlined, color: AppTheme.textSecondary),
                  ),
                ).animate().fade(duration: 400.ms, delay: 500.ms).slideY(begin: 0.1),
                const SizedBox(height: 30),

                // GPS Location Capture Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _capturedLocation != null ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                            color: _capturedLocation != null ? AppTheme.successGreen : AppTheme.warningOrange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Home Location GPS',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _capturedLocation != null
                                      ? 'Coordinates captured!'
                                      : 'No coordinates set',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: _capturedLocation != null ? AppTheme.successGreen : AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_capturedLocation != null)
                            const Icon(Icons.check_circle_outline_rounded, color: AppTheme.successGreen),
                        ],
                      ),
                      if (_capturedLocation != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Lat: ${_capturedLocation!.latitude.toStringAsFixed(6)}\nLong: ${_capturedLocation!.longitude.toStringAsFixed(6)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchingLocation ? null : _captureLocation,
                        icon: _fetchingLocation
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.background),
                                ),
                              )
                            : const Icon(Icons.my_location_rounded, size: 18),
                        label: Text(_fetchingLocation ? 'Fetching GPS...' : 'Set Home Location (Current GPS)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.border,
                          foregroundColor: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(duration: 400.ms, delay: 600.ms).slideY(begin: 0.1),
                const SizedBox(height: 40),

                // Register Student Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitStudent,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.background),
                          ),
                        )
                      : Text(isEditing ? 'Update Details' : 'Register Student'),
                ).animate().fade(duration: 400.ms, delay: 700.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
