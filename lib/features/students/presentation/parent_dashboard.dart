import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/student_model.dart';
import '../../profile/presentation/parent_profile_screen.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/services/telemetry_consumer.dart';
import '../../../core/services/mqtt_service.dart';
import 'live_tracking_map_screen.dart';
import '../../../core/utils/snackbar_utils.dart';

/// Real-time stream provider that fetches all students linked to the logged-in parent.
final parentStudentsProvider = StreamProvider<List<StudentModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final currentUser = ref.watch(firebaseAuthProvider).currentUser;

  if (currentUser == null) {
    return Stream.value(const []);
  }

  return firestore
      .collection('students')
      .where('parent_uid', isEqualTo: currentUser.uid)
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => StudentModel.fromJson(doc.data(), doc.id))
          .toList());
});

/// State provider for the currently selected student ID
class SelectedStudentIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void updateStudent(String? id) => state = id;
}

final selectedStudentIdProvider = NotifierProvider<SelectedStudentIdNotifier, String?>(
  SelectedStudentIdNotifier.new,
);

class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final studentsAsync = ref.watch(parentStudentsProvider);
    final selectedId = ref.watch(selectedStudentIdProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: SvgPicture.asset(
          'assets/images/logo.svg',
          height: 32,
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ParentProfileScreen(),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.15),
                child: const Icon(Icons.person_rounded, color: AppTheme.primaryGold, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: studentsAsync.when(
          data: (students) {
            if (students.isEmpty) {
              return _buildEmptyState(theme);
            }

            // Auto-select the first child if none is selected
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (selectedId == null && students.isNotEmpty) {
                ref.read(selectedStudentIdProvider.notifier).updateStudent(students.first.studentId);
              }
            });

            final selectedStudent = students.firstWhere(
              (s) => s.studentId == selectedId,
              orElse: () => students.first,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Child Selector Header
                  _buildHeader(context, ref, theme, students, selectedStudent),
                  const SizedBox(height: 24),
                  
                  // Dashboard Content for Selected Student
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: SingleChildScrollView(
                        key: ValueKey<String>(selectedStudent.studentId),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProfileCard(context, theme, selectedStudent),
                            const SizedBox(height: 16),
                            _buildStatusCard(theme, selectedStudent),
                            const SizedBox(height: 16),
                            _buildEtaCard(theme, selectedStudent),
                            const SizedBox(height: 16),
                            _buildMapCard(context, ref, theme, selectedStudent),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoading(width: 100, height: 16),
                const SizedBox(height: 8),
                const ShimmerLoading(width: double.infinity, height: 48),
                const SizedBox(height: 24),
                const ShimmerCard(),
                const ShimmerCard(),
                const ShimmerCard(),
              ],
            ),
          ),
          error: (error, stackTrace) => _buildErrorState(theme, error.toString()),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, ThemeData theme, List<StudentModel> students, StudentModel selected) {
    if (students.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Child',
            style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            selected.name,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ).animate().fade().slideY(begin: -0.1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Child',
          style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected.studentId,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryGold),
              items: students.map((StudentModel student) {
                return DropdownMenuItem<String>(
                  value: student.studentId,
                  child: Text(
                    student.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ref.read(selectedStudentIdProvider.notifier).updateStudent(newValue);
                }
              },
            ),
          ),
        ),
      ],
    ).animate().fade().slideY(begin: -0.1);
  }

  Widget _buildProfileCard(BuildContext context, ThemeData theme, StudentModel student) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.15),
            child: const Icon(Icons.person_rounded, color: AppTheme.primaryGold, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ID: ${student.studentId}',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.schoolName.isNotEmpty ? student.schoolName : 'No School Set',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                ),
                Text(
                  'Grade: ${student.grade}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

        ],
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildStatusCard(ThemeData theme, StudentModel student) {
    Color statusColor;
    IconData statusIcon;

    switch (student.lastAttendanceStatus) {
      case 'In Van':
        statusColor = AppTheme.warningOrange;
        statusIcon = Icons.directions_bus_rounded;
        break;
      case 'At School':
        statusColor = AppTheme.primaryGold;
        statusIcon = Icons.school_rounded;
        break;
      case 'At Home':
      default:
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.home_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.textSecondary),
                ),
                Text(
                  student.lastAttendanceStatus,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildEtaCard(ThemeData theme, StudentModel student) {
    String etaText;
    switch (student.lastAttendanceStatus) {
      case 'In Van':
        etaText = 'ETA: 15 mins';
        break;
      case 'At Home':
        etaText = 'Already at Home';
        break;
      case 'At School':
      default:
        etaText = 'Trip not started yet';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.textPrimary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time_rounded, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              etaText,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 300.ms).slideY(begin: 0.1);
  }

  /// The map card shows a live telemetry readout when the student is In Van.
  /// It subscribes via [parentTelemetryProvider] using the active session_id
  /// stored on the student document. When the status changes away from 'In Van'
  /// Riverpod disposes the provider and TelemetryConsumer disconnects cleanly.
  Widget _buildMapCard(BuildContext context, WidgetRef ref, ThemeData theme, StudentModel student) {
    // The active session id is stored on the student doc (set by TripService fan-out).
    final sessionId = student.stats['active_session_id'] as String? ?? '';
    final isTripActive = sessionId.isNotEmpty;
    // Subscribe to MQTT when there is an active session
    final telemetryAsync = isTripActive
        ? ref.watch(parentTelemetryProvider(sessionId))
        : const AsyncValue<TelemetryPayload?>.data(null);

    return GestureDetector(
      onTap: () {
        if (isTripActive) {
          // Navigate to full-screen live tracking map
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LiveTrackingMapScreen(
                student: student,
                sessionId: sessionId,
              ),
            ),
          );
        } else {
          SnackBarUtils.showInfo(context, 'Live tracking is available once the trip starts.');
        }
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: isTripActive ? AppTheme.surface : AppTheme.border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isTripActive ? AppTheme.primaryGold.withValues(alpha: 0.5) : AppTheme.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isTripActive ? Icons.gps_fixed_rounded : Icons.map_rounded,
                size: 40,
                color: isTripActive ? AppTheme.primaryGold : AppTheme.textMuted,
              ),
              const SizedBox(height: 10),
              Text(
                isTripActive ? 'Live Tracking Active' : 'Live Tracking Map',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isTripActive ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              if (isTripActive) ...[      
                telemetryAsync.when(
                  data: (payload) => payload != null
                      ? Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGold.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on, color: AppTheme.primaryGold, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${payload.latitude.toStringAsFixed(5)}, ${payload.longitude.toStringAsFixed(5)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Speed: ${(payload.speed * 3.6).toStringAsFixed(1)} km/h',
                                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Waiting for GPS signal…',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                        ),
                  loading: () => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGold)),
                      const SizedBox(width: 8),
                      Text('Connecting to van…', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted)),
                    ],
                  ),
                  error: (e, _) => Text('Signal error: $e', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.errorRed)),
                ),
                const SizedBox(height: 10),
                // Tap CTA
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Open Full Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[                
                Text(
                  'Map available when trip starts',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ],
          ),
        ),
      ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
    );
  }


  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.child_care_rounded,
              color: AppTheme.primaryGold,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No students linked yet.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a child using the button below.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fade(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
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
            'Failed to load students',
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
