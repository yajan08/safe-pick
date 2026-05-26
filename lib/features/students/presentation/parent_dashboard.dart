import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/student_model.dart';
import 'add_student_screen.dart';

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
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => StudentModel.fromJson(doc.data(), doc.id))
          .toList());
});

/// State provider for the currently selected student ID
final selectedStudentIdProvider = StateProvider<String?>((ref) => null);

class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.border, width: 1),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'No',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: AppTheme.background,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final studentsAsync = ref.watch(parentStudentsProvider);
    final selectedId = ref.watch(selectedStudentIdProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _handleSignOut(context, ref),
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
                ref.read(selectedStudentIdProvider.notifier).state = students.first.studentId;
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
                    child: SingleChildScrollView(
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
                          _buildMapCard(context, theme, selectedStudent),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
            ),
          ),
          error: (error, stackTrace) => _buildErrorState(theme, error.toString()),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddStudentScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_rounded),
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
                  ref.read(selectedStudentIdProvider.notifier).state = newValue;
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
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddStudentScreen(student: student),
                ),
              );
            },
            icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryGold),
            tooltip: 'Edit Details',
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

  Widget _buildMapCard(BuildContext context, ThemeData theme, StudentModel student) {
    final isInVan = student.lastAttendanceStatus == 'In Van';

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isInVan ? 'Opening Live Tracking Map... (Coming Soon)' : 'Trip not started yet.',
            ),
            backgroundColor: isInVan ? AppTheme.primaryGold : AppTheme.textSecondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
