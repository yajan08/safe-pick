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
  
  String _tripType = 'Morning';
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
          status: _tripType.toLowerCase() == 'morning' ? 'At Home' : 'At School',
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

  Widget _buildTypeToggle(String title, IconData icon, String value) {
    final isSelected = _tripType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tripType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGold : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGold : AppTheme.border,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Create New Route', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- SECTION 1: Trip Details ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Step 1: Route Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Trip Name Field (Large and Clear)
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              labelText: 'Route Name',
                              hintText: 'e.g. Route A, Morning DPS',
                              prefixIcon: Icon(Icons.directions_bus_outlined, size: 28),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a name for the route';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          Text(
                            'Shift Type',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Massive Toggle Buttons instead of Dropdown
                          Row(
                            children: [
                              Expanded(child: _buildTypeToggle('Morning', Icons.wb_sunny_rounded, 'Morning')),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTypeToggle('Afternoon', Icons.nights_stay_rounded, 'Afternoon')),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: 0.05),

                    const SizedBox(height: 24),

                    // --- SECTION 2: Student Roster ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Step 2: Add Students',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Text(
                                  'Count: ${_roster.length}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Search Bar & Add Button
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                  decoration: const InputDecoration(
                                    labelText: 'Student ID',
                                    hintText: 'SP1005',
                                    prefixIcon: Icon(Icons.badge_rounded, size: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 56,
                                width: 90, // Fixed width for massive hit target
                                child: ElevatedButton(
                                  onPressed: _isSearching ? null : _searchStudent,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: _isSearching 
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.person_add_rounded, size: 24),
                                          Text('ADD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),

                          // Roster List
                          if (_roster.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.people_outline_rounded, size: 48, color: AppTheme.border),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No students added.\nEnter an ID above and press ADD.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ).animate().fade(delay: 100.ms)
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _roster.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final s = _roster[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.15),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(color: AppTheme.primaryGoldDark, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.name, 
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                            ),
                                            Text(
                                              'ID: ${s.studentId}',
                                              style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Large, explicitly red delete target
                                      IconButton(
                                        icon: const Icon(Icons.delete_rounded, size: 28),
                                        color: AppTheme.errorRed.withValues(alpha: 0.8),
                                        onPressed: () {
                                          setState(() {
                                            _roster.remove(s);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ).animate().fade().slideX(begin: 0.05);
                              },
                            ),
                        ],
                      ),
                    ).animate().fade(delay: 100.ms).slideY(begin: 0.05),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // --- SECTION 3: Fixed Bottom Action ---
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                border: Border(top: BorderSide(color: AppTheme.border.withValues(alpha: 0.5))),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitTrip,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.background),
                            ),
                          )
                        : Text(
                            'Save Route (${_roster.length} Students)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}