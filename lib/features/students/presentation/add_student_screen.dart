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
        currentStatus: isEditing ? widget.student!.currentStatus : 'At Home',
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
    final hasLocation = _capturedLocation != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          isEditing ? 'Edit Profile' : 'Add Child',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // --- Scrollable Form Area ---
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Description
                    Text(
                      'Provide student details and secure their primary home location for routing.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                    ).animate().fade(duration: 400.ms).slideY(begin: 0.05),
                    
                    const SizedBox(height: 24),

                    // Clean, Unified Form Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Enter student name',
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter student name';
                              }
                              return null;
                            },
                          ).animate().fade(delay: 50.ms),
                          const SizedBox(height: 16),

                          // Grade Field
                          TextFormField(
                            controller: _gradeController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Grade / Class',
                              hintText: 'e.g. Grade 5, Class A',
                              prefixIcon: Icon(Icons.school_outlined, size: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter grade';
                              }
                              return null;
                            },
                          ).animate().fade(delay: 100.ms),
                          const SizedBox(height: 16),

                          // School Name Field
                          TextFormField(
                            controller: _schoolNameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'School Name',
                              hintText: 'e.g. Springfield Elementary',
                              prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
                            ),
                          ).animate().fade(delay: 150.ms),
                          const SizedBox(height: 16),

                          // Note Field
                          TextFormField(
                            controller: _noteController,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Special Notes',
                              hintText: 'e.g. Needs front seat, allergies, etc.',
                              prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                            ),
                          ).animate().fade(delay: 200.ms),
                        ],
                      ),
                    ).animate().fade().slideY(begin: 0.05),

                    const SizedBox(height: 24),

                    // Smart GPS Location Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: hasLocation 
                            ? AppTheme.successGreen.withValues(alpha: 0.03) 
                            : AppTheme.warningOrange.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: hasLocation 
                              ? AppTheme.successGreen.withValues(alpha: 0.3)
                              : AppTheme.warningOrange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: hasLocation 
                                      ? AppTheme.successGreen.withValues(alpha: 0.1)
                                      : AppTheme.warningOrange.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  hasLocation ? Icons.check_circle_rounded : Icons.gps_off_rounded,
                                  color: hasLocation ? AppTheme.successGreen : AppTheme.warningOrange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Home Location',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hasLocation ? 'GPS coordinates secured' : 'Required for accurate routing',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (hasLocation) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                '${_capturedLocation!.latitude.toStringAsFixed(6)}, ${_capturedLocation!.longitude.toStringAsFixed(6)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'monospace',
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _fetchingLocation ? null : _captureLocation,
                              icon: _fetchingLocation
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(
                                      hasLocation ? Icons.update_rounded : Icons.my_location_rounded, 
                                      size: 18,
                                    ),
                              label: Text(_fetchingLocation 
                                  ? 'Fetching Signal...' 
                                  : hasLocation ? 'Update Coordinates' : 'Capture Current Location'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: hasLocation ? AppTheme.textPrimary : AppTheme.warningOrange,
                                side: BorderSide(
                                  color: hasLocation 
                                      ? AppTheme.border 
                                      : AppTheme.warningOrange.withValues(alpha: 0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 150.ms).slideY(begin: 0.05),
                  ],
                ),
              ),
            ),
          ),

          // --- Fixed Bottom Section ---
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              border: Border(top: BorderSide(color: AppTheme.border.withValues(alpha: 0.3))),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
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
                      : Text(
                          isEditing ? 'Save Changes' : 'Register Student',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ).animate().fade(delay: 200.ms),
            ),
          ),
        ],
      ),
    );
  }
}