import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../students/data/student_model.dart';
import '../../students/presentation/add_student_screen.dart';

/// Screen showing full student details with QR code for the parent.
class StudentDetailScreen extends ConsumerWidget {
  final StudentModel student;

  const StudentDetailScreen({super.key, required this.student});

  Future<void> _handleRemove(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text(
          'Remove Student',
          style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove ${student.name}? This will mark their profile as inactive.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.background,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(firestoreProvider)
            .collection('students')
            .doc(student.studentId)
            .update({'status': 'inactive'});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student removed successfully'),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context); // Go back to profile
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove: $e'),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(student.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryGold),
            tooltip: 'Edit Details',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddStudentScreen(student: student),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // QR Code Card
              _buildQrCodeCard(theme),
              const SizedBox(height: 24),

              // Student Details Card
              _buildDetailsCard(theme),
              const SizedBox(height: 24),

              // Location Card
              _buildLocationCard(theme),
              const SizedBox(height: 24),

              // Note Card (if note exists)
              if (student.note.isNotEmpty) ...[
                _buildNoteCard(theme),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              _buildActionButtons(context, ref, theme),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCodeCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(
            'Student QR Code',
            style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          // QR Code with white background for scanability
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: QrImageView(
              data: student.studentId,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF1A1A1A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Student ID Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
            ),
            child: Text(
              student.studentId,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share this code with your driver for quick check-in',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildDetailsCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Details',
            style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(theme, Icons.person_rounded, 'Name', student.name),
          const Divider(color: AppTheme.border, height: 24),
          _buildDetailRow(theme, Icons.school_rounded, 'Grade', student.grade),
          const Divider(color: AppTheme.border, height: 24),
          _buildDetailRow(
            theme,
            Icons.account_balance_rounded,
            'School',
            student.schoolName.isNotEmpty ? student.schoolName : 'Not set',
          ),
          const Divider(color: AppTheme.border, height: 24),
          _buildDetailRow(
            theme,
            Icons.circle,
            'Status',
            student.currentStatus,
            valueColor: student.currentStatus == 'At Home'
                ? AppTheme.successGreen
                : student.currentStatus == 'In Van'
                    ? AppTheme.warningOrange
                    : AppTheme.primaryGold,
          ),
        ],
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildDetailRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGold, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(ThemeData theme) {
    final hasLocation = student.homeLocation != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(
            hasLocation ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
            color: hasLocation ? AppTheme.successGreen : AppTheme.textMuted,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Home Location',
                  style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  hasLocation
                      ? 'Lat: ${student.homeLocation!.latitude.toStringAsFixed(4)}, Lng: ${student.homeLocation!.longitude.toStringAsFixed(4)}'
                      : 'Not set',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: hasLocation ? AppTheme.textPrimary : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            hasLocation ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: hasLocation ? AppTheme.successGreen : AppTheme.warningOrange,
            size: 20,
          ),
        ],
      ),
    ).animate().fade(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildNoteCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.note_alt_rounded, color: AppTheme.primaryGold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Special Note',
                  style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  student.note,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Edit Button
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddStudentScreen(student: student),
              ),
            );
          },
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Edit Details'),
        ),
        const SizedBox(height: 12),
        // Remove Button
        OutlinedButton.icon(
          onPressed: () => _handleRemove(context, ref),
          icon: const Icon(Icons.person_remove_rounded, color: AppTheme.errorRed),
          label: const Text('Remove Student'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.errorRed,
            side: const BorderSide(color: AppTheme.errorRed, width: 1.5),
          ),
        ),
      ],
    ).animate().fade(delay: 400.ms).slideY(begin: 0.05);
  }
}
