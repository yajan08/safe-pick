import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/domain/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_gate.dart';
import '../data/student_model.dart';
import 'add_student_screen.dart';
import 'student_detail_screen.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/safe_pick_dialog.dart';

/// Provider that streams all active students for the current parent.
final profileStudentsProvider = StreamProvider<List<StudentModel>>((ref) {
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

class ParentProfileScreen extends ConsumerWidget {
  const ParentProfileScreen({super.key});

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => SafePickDialog(
        title: 'Sign Out',
        description: 'Are you sure you want to sign out?',
        primaryActionLabel: 'Sign Out',
        onPrimaryAction: () => Navigator.of(context).pop(true),
        secondaryActionLabel: 'Cancel',
        onSecondaryAction: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An error occurred. Please check your connection and try again.'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool canDelete = false;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafePickDialog(
              title: 'Delete Account',
              isDestructive: true,
              isPrimaryActionEnabled: canDelete,
              primaryActionLabel: 'Delete',
              onPrimaryAction: () => Navigator.of(context).pop(passwordController.text),
              secondaryActionLabel: 'Cancel',
              onSecondaryAction: () => Navigator.of(context).pop(null),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Are you absolutely sure you want to permanently delete your account and all associated active student profiles? This action cannot be undone.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (_) {
                      setState(() {
                        canDelete = confirmController.text == 'Delete' && passwordController.text.isNotEmpty;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Type "Delete" to confirm:', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Delete',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        canDelete = val == 'Delete' && passwordController.text.isNotEmpty;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null || result.isEmpty) return;

    try {
      await ref.read(authServiceProvider).deleteParentAccount(result);
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('We encountered an issue deleting your account. Please try again.'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;
    final studentsAsync = ref.watch(profileStudentsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: AppTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── User Info Card ──
              _buildUserInfoCard(context, ref, theme, currentUser),
              const SizedBox(height: 32),

              // ── Section Header: My Children ──
              Text(
                'My Children',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppTheme.textPrimary,
                ),
              )
                  .animate()
                  .fade(delay: 150.ms, duration: 400.ms, curve: Curves.easeOutCubic)
                  .slideX(begin: -0.02, curve: Curves.easeOutCubic),
              const SizedBox(height: 16),

              // ── Children List ──
              studentsAsync.when(
                data: (students) {
                  if (students.isEmpty) {
                    return _buildEmptyChildState(theme);
                  }
                  return Column(
                    children: students
                        .asMap()
                        .entries
                        .map((entry) => _buildChildTile(context, theme, entry.value, entry.key))
                        .toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: ShimmerList(itemCount: 3, itemHeight: 88),
                ),
                error: (error, _) => Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Failed to load children.\n$error',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.errorRed,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Add New Child Button ──
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddStudentScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: AppTheme.background,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Add New Child',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fade(delay: 300.ms, duration: 400.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.05, curve: Curves.easeOutCubic),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, WidgetRef ref, ThemeData theme, dynamic currentUser) {
    final email = currentUser?.email ?? 'N/A';
    final displayName = currentUser?.displayName ?? 'Parent';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.1),
            child: const Icon(Icons.person_rounded, size: 40, color: AppTheme.primaryGold),
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            displayName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),

          // Email
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Parent Account',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.primaryGold,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          const Divider(height: 1, thickness: 1, color: AppTheme.border),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _handleSignOut(context, ref),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign Out'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: AppTheme.border),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _handleDeleteAccount(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete Account'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 500.ms, curve: Curves.easeOutCubic).slideY(begin: -0.02);
  }

  Widget _buildChildTile(BuildContext context, ThemeData theme, StudentModel student, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StudentDetailScreen(student: student),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.4), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Child Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.1),
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Name & Grade
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Grade ${student.grade}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Student ID Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                child: Text(
                  student.studentId,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.border, size: 24),
            ],
          ),
        ),
      ),
    ).animate().fade(
          delay: Duration(milliseconds: 150 + (index * 80)),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        ).slideX(begin: 0.02, curve: Curves.easeOutCubic);
  }

  Widget _buildEmptyChildState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.child_care_rounded, color: AppTheme.primaryGold.withValues(alpha: 0.8), size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            'No children registered',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your first child.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fade(delay: 200.ms, duration: 500.ms).scale(
          begin: const Offset(0.98, 0.98),
          curve: Curves.easeOutCubic,
        );
  }
}