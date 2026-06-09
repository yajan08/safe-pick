import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../students/data/student_model.dart';
import '../../students/presentation/add_student_screen.dart';
import '../../trips/data/trip_service.dart';

/// Screen showing full student details with QR code for the parent.
class StudentDetailScreen extends ConsumerStatefulWidget {
  final StudentModel student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> {
  bool _isLoading = false;

  Future<void> _handleRemove() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.3), width: 1),
        ),
        title: const Text(
          'Remove Student',
          style: TextStyle(
            color: AppTheme.errorRed,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        content: Text(
          'Are you sure you want to remove ${widget.student.name}? This will permanently delete their active profile.',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
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
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.background,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final firestore = ref.read(firestoreProvider);
        
        // Find all trips where this student is assigned
        final tripsSnap = await firestore
            .collection('trips')
            .where('student_ids', arrayContains: widget.student.studentId)
            .get();
            
        final activeTripIds = tripsSnap.docs.map((doc) => doc.id).toList();

        // Call the deep clean method
        await ref.read(tripServiceProvider).removeStudentPermanently(
          studentId: widget.student.studentId,
          activeTripIds: activeTripIds,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Student removed successfully'),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context); // Go back to profile
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          widget.student.name,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 22, color: AppTheme.primaryGold),
            tooltip: 'Edit Details',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddStudentScreen(student: widget.student),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : Column(
              children: [
                // ── Scrollable Content ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildQrCodeCard(theme),
                        const SizedBox(height: 20),

                        _buildDetailsCard(theme),
                        const SizedBox(height: 20),

                        _buildLocationCard(theme),
                        
                        if (widget.student.note.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildNoteCard(theme),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Sticky Bottom Action Bar ──
                _buildStickyActionButtons(theme),
              ],
            ),
      ),
    );
  }

  Widget _buildQrCodeCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Student QR Code',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          // QR Code 
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: QrImageView(
              data: widget.student.studentId,
              version: QrVersions.auto,
              size: 160,
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
          const SizedBox(height: 20),
          
          // Student ID Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.2)),
            ),
            child: Text(
              widget.student.studentId,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Text(
            'Share this code with your driver for quick check-in',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textMuted,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms, curve: Curves.easeOutCubic).scale(
      begin: const Offset(0.98, 0.98), curve: Curves.easeOutCubic,
    );
  }

  Widget _buildDetailsCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Details',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildDetailRow(theme, Icons.person_rounded, 'Name', widget.student.name),
          Divider(color: AppTheme.border.withValues(alpha: 0.3), height: 24, thickness: 1),
          
          _buildDetailRow(theme, Icons.school_rounded, 'Grade', widget.student.grade),
          Divider(color: AppTheme.border.withValues(alpha: 0.3), height: 24, thickness: 1),
          
          _buildDetailRow(
            theme,
            Icons.account_balance_rounded,
            'School',
            widget.student.schoolName.isNotEmpty ? widget.student.schoolName : 'Not set',
          ),
          Divider(color: AppTheme.border.withValues(alpha: 0.3), height: 24, thickness: 1),
          
          _buildDetailRow(
            theme,
            Icons.circle,
            'Status',
            widget.student.currentStatus,
            valueColor: widget.student.currentStatus == 'At Home'
                ? AppTheme.successGreen
                : widget.student.currentStatus == 'In Van'
                    ? AppTheme.warningOrange
                    : AppTheme.primaryGold,
          ),
        ],
      ),
    ).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.02, curve: Curves.easeOutCubic);
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryGold, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, 
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textMuted,
                  letterSpacing: 0.2,
                )
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(ThemeData theme) {
    final hasLocation = widget.student.homeLocation != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasLocation 
                ? AppTheme.successGreen.withValues(alpha: 0.1) 
                : AppTheme.textMuted.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasLocation ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
              color: hasLocation ? AppTheme.successGreen : AppTheme.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Home Location',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasLocation
                      ? 'Lat: ${widget.student.homeLocation!.latitude.toStringAsFixed(4)}, Lng: ${widget.student.homeLocation!.longitude.toStringAsFixed(4)}'
                      : 'Not set',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: hasLocation ? AppTheme.textPrimary : AppTheme.textMuted,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          if (hasLocation)
             const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20)
          else
             const Icon(Icons.warning_rounded, color: AppTheme.warningOrange, size: 20),
        ],
      ),
    ).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.02, curve: Curves.easeOutCubic);
  }

  Widget _buildNoteCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryGold.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.note_alt_rounded, color: AppTheme.primaryGold, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Special Note',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.student.note,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 300.ms, duration: 400.ms).slideY(begin: 0.02, curve: Curves.easeOutCubic);
  }

  Widget _buildStickyActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          top: BorderSide(color: AppTheme.border.withValues(alpha: 0.3), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _isLoading ? null : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddStudentScreen(student: widget.student),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: AppTheme.background,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Edit Details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading ? null : () => _handleRemove(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Remove Student',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 400.ms, duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic);
  }
}