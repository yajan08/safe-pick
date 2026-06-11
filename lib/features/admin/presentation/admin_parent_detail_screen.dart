import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/user_model.dart';
import '../../students/data/student_model.dart';
import '../../profile/presentation/student_detail_screen.dart';
import 'admin_dashboard_screen.dart' show kAdminNavy, kAdminNavyLight;

final parentChildrenProvider =
    FutureProvider.family<List<StudentModel>, String>((ref, parentId) async {
      final firestore = FirebaseFirestore.instance;
      final snap = await firestore
          .collection('students')
          .where('parent_id', isEqualTo: parentId)
          .get();

      return snap.docs
          .map((doc) => StudentModel.fromJson(doc.data(), doc.id))
          .toList();
    });

class AdminParentDetailScreen extends ConsumerWidget {
  final UserModel parent;

  const AdminParentDetailScreen({super.key, required this.parent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final childrenAsync = ref.watch(parentChildrenProvider(parent.uid));

    final formatter = DateFormat('MMM d, yyyy');
    final isInactive =
        parent.status == 'suspended' || parent.status == 'inactive';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        foregroundColor: kAdminNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Parent Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.5,
            color: kAdminNavy,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Parent Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.border.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.blueGrey.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.blueGrey,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    parent.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isInactive
                          ? AppTheme.errorRed.withValues(alpha: 0.1)
                          : AppTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isInactive ? 'SUSPENDED' : 'ACTIVE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isInactive
                            ? AppTheme.errorRed
                            : AppTheme.successGreen,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    theme,
                    Icons.phone_rounded,
                    'Phone',
                    parent.phone.isNotEmpty ? parent.phone : 'N/A',
                  ),
                  Divider(
                    color: AppTheme.border.withValues(alpha: 0.3),
                    height: 24,
                  ),
                  _buildDetailRow(
                    theme,
                    Icons.calendar_today_rounded,
                    'Joined',
                    formatter.format(parent.createdAt!),
                  ),
                  Divider(
                    color: AppTheme.border.withValues(alpha: 0.3),
                    height: 24,
                  ),
                  _buildDetailRow(
                    theme,
                    Icons.badge_rounded,
                    'UID',
                    parent.uid,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Text(
              'Children',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: kAdminNavy,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 16),

            childrenAsync.when(
              data: (children) {
                if (children.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.border.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Center(
                      child: Text('No children registered for this parent.'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: children.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final child = children[index];
                    return _buildChildCard(context, theme, child);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: kAdminNavy),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildChildCard(
    BuildContext context,
    ThemeData theme,
    StudentModel child,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudentDetailScreen(student: child),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.face_rounded,
                color: AppTheme.primaryGold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grade: ${child.grade}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
