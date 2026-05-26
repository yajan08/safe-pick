import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/trip_model.dart';
import '../data/trip_service.dart';
import '../data/trip_manifest_model.dart';
import '../../../core/services/auth_service.dart';

/// Future provider to fetch details of a specific trip.
final tripDetailsProvider = FutureProvider.family<TripModel, String>((ref, tripId) async {
  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore.collection('trips').doc(tripId).get();
  if (!doc.exists) {
    throw 'Trip not found';
  }
  return TripModel.fromJson(doc.data()!, doc.id);
});

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  bool _isStarting = false;
  bool _isSessionStarted = false;

  Future<void> _handleStartTrip() async {
    setState(() {
      _isStarting = true;
    });

    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.startDailySession(widget.tripId);
      
      setState(() {
        _isSessionStarted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily session started! MQTT location stream is active.'),
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
          _isStarting = false;
        });
      }
    }
  }

  Future<void> _showAddStudentDialog(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.bgBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.borderDark, width: 1),
              ),
              title: const Text(
                'Add Student to Roster',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Enter the 6-character alphanumeric student ID to add them to this trip manifest.',
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: const InputDecoration(
                        labelText: 'Student ID',
                        hintText: 'e.g. A9X2KF',
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length != 6) {
                          return 'Please enter a valid 6-character ID';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textWhite),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          
                          setState(() {
                            isSubmitting = true;
                          });

                          final studentId = controller.text.trim().toUpperCase();
                          final success = await _addStudentToManifest(studentId);

                          if (success && context.mounted) {
                            Navigator.of(context).pop();
                          } else {
                            setState(() {
                              isSubmitting = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: AppTheme.bgBlack,
                    minimumSize: const Size(80, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.bgBlack),
                          ),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _addStudentToManifest(String studentId) async {
    try {
      final firestore = ref.read(firestoreProvider);
      
      final studentDoc = await firestore.collection('students').doc(studentId).get();
      if (!studentDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Student ID "$studentId" not found in registration database.'),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false;
      }

      final studentData = studentDoc.data()!;
      final studentName = studentData['name'] as String? ?? 'Unknown';
      final studentSchoolId = studentData['school_id'] as String? ?? 'sch_default_01';

      final manifestDocs = await firestore
          .collection('trips')
          .doc(widget.tripId)
          .collection('trip_manifest')
          .get();
      
      final nextStopOrder = manifestDocs.docs.length + 1;

      final newManifestItem = TripManifestModel(
        studentId: studentId,
        schoolId: studentSchoolId,
        name: studentName,
        stopOrder: nextStopOrder,
        status: 'active',
        expectedTime: '07:30 AM',
      );

      await firestore
          .collection('trips')
          .doc(widget.tripId)
          .collection('trip_manifest')
          .doc(studentId)
          .set(newManifestItem.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$studentName added to manifest!'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add student: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripDetailsProvider(widget.tripId));
    final manifestAsync = ref.watch(tripManifestProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Manifest'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showAddStudentDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: tripAsync.when(
          data: (trip) {
            // Update local state if the trip's Firestore status is already active
            final isAlreadyActive = trip.status.toLowerCase() == 'active' || _isSessionStarted;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Area
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderDark, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.tripName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              trip.tripType.toLowerCase() == 'pickup'
                                  ? Icons.login_rounded
                                  : Icons.logout_rounded,
                              color: AppTheme.primaryGold,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              trip.tripType.toLowerCase() == 'pickup'
                                  ? 'Morning Pick-Up'
                                  : 'Afternoon Drop-Off',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textGrey,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.schedule_rounded,
                              color: AppTheme.textGrey,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              trip.estimatedDuration,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Start Trip Button
                        ElevatedButton(
                          onPressed: (isAlreadyActive || _isStarting)
                              ? null
                              : _handleStartTrip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAlreadyActive
                                ? AppTheme.borderDark
                                : AppTheme.primaryGold,
                            foregroundColor: isAlreadyActive
                                ? AppTheme.textMuted
                                : AppTheme.bgBlack,
                          ),
                          child: _isStarting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.bgBlack,
                                    ),
                                  ),
                                )
                              : Text(
                                  isAlreadyActive ? 'Trip In Progress' : 'Start Trip',
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Manifest Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Roster Manifest',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: manifestAsync.when(
                          data: (manifest) => Text(
                            '${manifest.length} Stops',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppTheme.primaryGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          loading: () => const Text('...'),
                          error: (_, _) => const Text('Error'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Manifest List
                Expanded(
                  child: manifestAsync.when(
                    data: (manifest) {
                      if (manifest.isEmpty) {
                        return _buildEmptyManifestState(theme);
                      }
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        itemCount: manifest.length,
                        itemBuilder: (context, index) {
                          final student = manifest[index];
                          return _buildStudentManifestCard(theme, student);
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                      ),
                    ),
                    error: (error, _) => _buildErrorState(theme, error.toString()),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
            ),
          ),
          error: (error, _) => _buildErrorState(theme, error.toString()),
        ),
      ),
    );
  }

  Widget _buildStudentManifestCard(ThemeData theme, TripManifestModel student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark, width: 1),
      ),
      child: Row(
        children: [
          // Stop Order Badge
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.borderDark,
            child: Text(
              '${student.stopOrder}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'School: ${student.schoolId}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGrey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.schedule_rounded,
                      color: AppTheme.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      student.expectedTime,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Placeholder QR Button
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            color: AppTheme.primaryGold,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('QR Scanner placeholder for ${student.name}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyManifestState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.format_list_bulleted_rounded, color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'Manifest Empty',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No student stops configured for this trip manifest.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error loading details',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.errorRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
