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
  final _searchController = TextEditingController();
  
  String _tripType = 'pickup';
  bool _isSubmitting = false;
  bool _isSearching = false;

  final List<StudentModel> _roster = [];

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
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

    if (_roster.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please link at least one student.')),
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

      final schoolIds = _roster.map((s) => s.schoolId).where((id) => id.isNotEmpty).toSet().toList();

      final newTrip = TripModel(
        tripId: tripId,
        driverUid: currentUser.uid,
        tripName: _nameController.text.trim(),
        tripType: _tripType,
        studentIds: _roster.map((s) => s.studentId).toList(),
        schoolIds: schoolIds,
        status: 'inactive',
      );

      final batch = firestore.batch();
      batch.set(docRef, newTrip.toJson());

      // Write roster to manifest
      for (int i = 0; i < _roster.length; i++) {
        final student = _roster[i];
        final manifestRef = docRef.collection('trip_manifest').doc(student.studentId);
        final manifestModel = TripManifestModel(
          studentId: student.studentId,
          schoolId: student.schoolId,
          name: student.name,
          schoolName: student.schoolName,
          stopOrder: i + 1,
          status: _tripType.toLowerCase() == 'pickup' || _tripType.toLowerCase() == 'morning' ? 'At Home' : 'At School',
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      const SizedBox(height: 32),

                      const Divider(color: AppTheme.border),
                      const SizedBox(height: 16),
                      Text(
                        'Link Students',
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
                                labelText: 'Enter exact Student ID',
                                hintText: 'e.g. SP1005',
                                prefixIcon: Icon(Icons.fingerprint_rounded, color: AppTheme.textSecondary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSearching ? null : _searchStudent,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(100, 56), // Override double.infinity to prevent layout crashes in Row
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isSearching 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Link'),
                            ),
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
                              'No students added yet.\nEnter exact ID to link a student.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                            ),
                          ),
                        ).animate().fade(delay: 700.ms)
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _roster.length,
                          itemBuilder: (context, index) {
                            final s = _roster[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
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
                              ),
                            );
                          },
                        ),
                    ],
                  ),
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
