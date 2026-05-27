import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:safe_pick/features/students/presentation/parent_live_tracking_screen.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/student_model.dart';
import '../../profile/presentation/parent_profile_screen.dart';
import '../../../core/widgets/shimmer_loading.dart';

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
        title: Image.asset(
          'assets/images/light_logo.jpg',
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
              return _buildEmptyState(context, theme);
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
                  SizedBox(height: students.length == 1 ? 8 : 12),
                  
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
                            _buildSquareStatusAndEtaCards(theme, selectedStudent),
                            const SizedBox(height: 16),
                            _buildMapCard(context, theme, selectedStudent),
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
                const ShimmerCard(height: 140),
                const ShimmerCard(height: 100),
                const ShimmerCard(height: 100),
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

  Widget _buildSquareStatusAndEtaCards(ThemeData theme, StudentModel student) {
    Color statusColor;
    IconData statusIcon;

    switch (student.currentStatus) {
      case 'In Van':
        statusColor = AppTheme.warningOrange;
        statusIcon = Icons.directions_bus_rounded;
        break;
      case 'At School':
        statusColor = AppTheme.primaryGold;
        statusIcon = Icons.school_rounded;
        break;
      case 'Absent':
        statusColor = AppTheme.errorRed;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'At Home':
      default:
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.home_rounded;
        break;
    }

    // Est Time displays either the student.estimatedArrival value or status-based fallback
    String etaText = student.estimatedArrival ?? '';
    if (etaText.isEmpty) {
      switch (student.currentStatus) {
        case 'In Van':
          etaText = '15 mins';
          break;
        case 'At Home':
          etaText = 'Arrived';
          break;
        case 'Absent':
          etaText = 'N/A';
          break;
        case 'At School':
        default:
          etaText = 'Not Started';
          break;
      }
    }

    return Row(
      children: [
        // Card 1: Current Status
        Expanded(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(statusIcon, color: statusColor, size: 36),
                  const SizedBox(height: 12),
                  const Text(
                    'Status',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      student.currentStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Card 2: Est. Time
        Expanded(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time_rounded, color: AppTheme.primaryGold, size: 36),
                  const SizedBox(height: 12),
                  const Text(
                    'Est. Arrival',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      etaText,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fade(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildMapCard(BuildContext context, ThemeData theme, StudentModel student) {
    final isInVan = student.currentStatus == 'In Van';

    return GestureDetector(
      onTap: () {
        if (isInVan) {
          // Navigate to the new tracking screen!
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ParentLiveTrackingScreen(student: student),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip not started yet or student not in van.'),
              backgroundColor: AppTheme.textSecondary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: isInVan ? AppTheme.surface : AppTheme.border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isInVan ? AppTheme.primaryGold.withValues(alpha: 0.5) : AppTheme.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_rounded,
                size: 48,
                color: isInVan ? AppTheme.primaryGold : AppTheme.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'Live Tracking Map',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isInVan ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
              ),
              if (!isInVan)
                Text(
                  'Map available when trip starts',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                ),
            ],
          ),
        ),
      ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
    );
  }


  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Add a student to your account in the Profile screen to start tracking.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ParentProfileScreen(),
                    ),
                  );
                },
                child: const Text('Go to Profile'),
              ),
            ),
          ],
        ).animate().fade(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
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
