import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/student_model.dart';

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

class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
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

    return Scaffold(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Text
              Text(
                'Your Children',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Monitor transport status and attendance logs below.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Students List
              Expanded(
                child: studentsAsync.when(
                  data: (students) {
                    if (students.isEmpty) {
                      return _buildEmptyState(theme);
                    }
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return _buildStudentCard(context, theme, student);
                      },
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, ThemeData theme, StudentModel student) {
    final isActive = student.status.toLowerCase() == 'active';
    final totalTrips = student.stats['total_trips'] ?? 0;
    final attendanceRate = (student.stats['attendance_rate'] ?? 0.0) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.15),
              child: const Icon(
                Icons.child_care_rounded,
                color: AppTheme.primaryGold,
              ),
            ),
            title: Text(
              student.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Grade: ${student.grade}',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.successGreen.withValues(alpha: 0.15)
                    : AppTheme.errorRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                student.status.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isActive ? AppTheme.successGreen : AppTheme.errorRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Divider(color: AppTheme.borderDark, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol(theme, 'Total Trips', '$totalTrips'),
                        _buildStatCol(theme, 'Attendance', '${attendanceRate.toStringAsFixed(0)}%'),
                        _buildStatCol(theme, 'School ID', student.schoolId.toUpperCase()),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelLarge,
        ),
      ],
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
            'Please contact your school administrator to register your child.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
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
