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

class AdminParentDetailScreen extends ConsumerStatefulWidget {
  final UserModel parent;

  const AdminParentDetailScreen({super.key, required this.parent});

  @override
  ConsumerState<AdminParentDetailScreen> createState() => _AdminParentDetailScreenState();
}

class _AdminParentDetailScreenState extends ConsumerState<AdminParentDetailScreen> {
  bool _isLoading = false;

  Future<void> _handleRemove() async {
    final TextEditingController controller = TextEditingController();
    bool canDelete = false;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.background,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.3), width: 1),
              ),
              title: const Text(
                'Remove Parent',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to remove ${widget.parent.name}? This will permanently delete their active profile. Their children will remain in the database unless removed separately.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Type "Delete" to confirm:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Delete',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        canDelete = val == 'Delete';
                      });
                    },
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.all(16),
              actionsAlignment: MainAxisAlignment.end,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canDelete ? AppTheme.errorRed : AppTheme.errorRed.withValues(alpha: 0.3),
                    foregroundColor: AppTheme.background,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: canDelete ? () => Navigator.pop(context, true) : null,
                  child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          }
        );
      },
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.parent.uid).delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Parent removed successfully'),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove: $e'),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final childrenAsync = ref.watch(parentChildrenProvider(widget.parent.uid));

    final formatter = DateFormat('MMM d, yyyy');
    final isInactive =
        widget.parent.status == 'suspended' || widget.parent.status == 'inactive';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22, color: AppTheme.errorRed),
            tooltip: 'Remove Parent',
            onPressed: _isLoading ? null : () => _handleRemove(),
          ),
          const SizedBox(width: 8),
        ],
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
                    widget.parent.name,
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
                    widget.parent.phone.isNotEmpty ? widget.parent.phone : 'N/A',
                  ),
                  Divider(
                    color: AppTheme.border.withValues(alpha: 0.3),
                    height: 24,
                  ),
                  _buildDetailRow(
                    theme,
                    Icons.calendar_today_rounded,
                    'Joined',
                    formatter.format(widget.parent.createdAt!),
                  ),
                  Divider(
                    color: AppTheme.border.withValues(alpha: 0.3),
                    height: 24,
                  ),
                  _buildDetailRow(
                    theme,
                    Icons.badge_rounded,
                    'UID',
                    widget.parent.uid,
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
