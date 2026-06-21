import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/admin_service.dart';
import '../../domain/pdf_report_service.dart';
import '../../../students/data/student_model.dart';
import '../../../students/data/student_ride_log_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../admin_dashboard_screen.dart';
import '../../../../core/widgets/safe_pick_dialog.dart';

class AdminReportsTab extends ConsumerStatefulWidget {
  const AdminReportsTab({super.key});

  @override
  ConsumerState<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends ConsumerState<AdminReportsTab> {
  String _searchQuery = '';
  StudentModel? _selectedStudent;
  List<StudentRideLogModel> _logs = [];
  bool _isLoadingLogs = false;
  bool _isGeneratingPdf = false;

  List<StudentModel> _filterStudents(List<StudentModel> students) {
    if (_searchQuery.isEmpty) return students;
    final q = _searchQuery.toLowerCase();
    return students
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.studentId.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _loadRideLogs(String studentId) async {
    setState(() => _isLoadingLogs = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .collection('ride_history')
          .orderBy('date', descending: true)
          .limit(50)
          .get();
      setState(
        () => _logs = snap.docs
            .map((d) => StudentRideLogModel.fromJson(d.data(), d.id))
            .toList(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLogs = false);
    }
  }

  Future<void> _downloadPdf() async {
    if (_selectedStudent == null || _isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);
    try {
      await PdfReportService.generateStudentReport(
        context,
        _selectedStudent!,
        _logs,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _showReport() {
    if (_selectedStudent == null) return;
    final totalTrips = _selectedStudent!.stats['total_trips'] ?? _logs.length;
    final absences = _logs.where((l) => l.status == 'Absent').length;
    final rate = _logs.isNotEmpty
        ? ((_logs.length - absences) / _logs.length * 100).toStringAsFixed(1)
        : 'N/A';

    showDialog(
      context: context,
      builder: (_) => SafePickDialog(
        title: 'Student Report',
        titleIcon: const Icon(Icons.analytics_rounded, color: kAdminNavy, size: 20),
        primaryActionLabel: 'Close',
        primaryActionColor: kAdminNavy,
        onPrimaryAction: () => Navigator.pop(context),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReportLine(label: 'Student', value: _selectedStudent!.name),
            _ReportLine(label: 'ID', value: _selectedStudent!.studentId),
            _ReportLine(
              label: 'School',
              value: _selectedStudent!.schoolName.isNotEmpty
                  ? _selectedStudent!.schoolName
                  : '—',
            ),
            _ReportLine(
              label: 'Grade',
              value: _selectedStudent!.grade.isNotEmpty
                  ? _selectedStudent!.grade
                  : '—',
            ),
            Divider(height: 24, color: AppTheme.border.withValues(alpha: 0.25)),
            _ReportLine(label: 'Total Trips', value: '$totalTrips'),
            _ReportLine(label: 'Attendance Rate', value: '$rate%'),
            _ReportLine(label: 'Total Absences', value: '$absences'),
            _ReportLine(
              label: 'Current Status',
              value: _selectedStudent!.currentStatus,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(adminStudentsProvider);

    if (_selectedStudent != null) return _buildAuditView();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Search students by name or ID…',
              hintStyle: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.5),
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppTheme.textMuted.withValues(alpha: 0.6),
                size: 20,
              ),
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.border.withValues(alpha: 0.25),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.border.withValues(alpha: 0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kAdminNavy, width: 1.5),
              ),
            ),
          ),
        ),
        Expanded(
          child: studentsAsync.when(
            data: (all) {
              final students = _filterStudents(all);
              if (students.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 44,
                        color: AppTheme.textMuted.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No students match.'
                            : 'No students available.',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: students.length,
                itemBuilder: (ctx, i) {
                  final s = students[i];
                  return _StudentTile(
                        student: s,
                        onTap: () {
                          setState(() => _selectedStudent = s);
                          _loadRideLogs(s.studentId);
                        },
                      )
                      .animate()
                      .fade(delay: Duration(milliseconds: 20 * i.clamp(0, 12)))
                      .slideX(begin: 0.015);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: kAdminNavy,
                strokeWidth: 2.5,
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditView() {
    return Stack(
      children: [
        Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 22),
                    onPressed: () => setState(() {
                      _selectedStudent = null;
                      _logs.clear();
                    }),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedStudent!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${_selectedStudent!.studentId} • ${_selectedStudent!.schoolName}',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showReport,
                    icon: const Icon(
                      Icons.summarize_rounded,
                      size: 15,
                      color: kAdminNavy,
                    ),
                    label: const Text(
                      'Stats',
                      style: TextStyle(
                        color: kAdminNavy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: kAdminNavy.withValues(alpha: 0.25),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Timeline
            Expanded(
              child: _isLoadingLogs
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: kAdminNavy,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 44,
                            color: AppTheme.textMuted.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No ride history found.',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        8,
                        24,
                        84,
                      ), // extra bottom for FAB
                      itemCount: _logs.length,
                      itemBuilder: (_, i) => _TimelineNode(
                        log: _logs[i],
                        isLast: i == _logs.length - 1,
                      ),
                    ),
            ),
          ],
        ),

        // ── PDF FAB ───────────────────────────────────────────────────────
        if (_logs.isNotEmpty)
          Positioned(
            bottom: 16,
            right: 20,
            child: FloatingActionButton.extended(
              heroTag: 'pdf_fab',
              onPressed: _isGeneratingPdf ? null : _downloadPdf,
              backgroundColor: kAdminNavy,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: _isGeneratingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: Text(
                _isGeneratingPdf ? 'Generating…' : 'Download PDF',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ).animate().fade().slideY(begin: 0.2),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Private widgets
// ──────────────────────────────────────────────────────────────────────────────

class _StudentTile extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onTap;
  const _StudentTile({required this.student, required this.onTap});

  Color get _statusColor {
    switch (student.currentStatus) {
      case 'In Van':
        return AppTheme.warningOrange;
      case 'At School':
        return kAdminNavy;
      case 'Absent':
        return AppTheme.errorRed;
      default:
        return AppTheme.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: _statusColor.withValues(alpha: 0.08),
          child: Icon(Icons.school_rounded, color: _statusColor, size: 18),
        ),
        title: Text(
          student.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
            letterSpacing: -0.1,
          ),
        ),
        subtitle: Text(
          '${student.studentId} • ${student.currentStatus}',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.textMuted.withValues(alpha: 0.4),
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final StudentRideLogModel log;
  final bool isLast;
  const _TimelineNode({required this.log, required this.isLast});

  Color get _dotColor {
    switch (log.status) {
      case 'Absent':
        return AppTheme.warningOrange;
      case 'At School':
        return kAdminNavy;
      case 'At Home':
        return AppTheme.successGreen;
      default:
        return AppTheme.textMuted.withValues(alpha: 0.5);
    }
  }

  String _fmtTime(DateTime? dt) => dt != null
      ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
      : 'N/A';

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: AppTheme.border.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log.date,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _dotColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.status.toUpperCase(),
                          style: TextStyle(
                            color: _dotColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${log.tripName} • ${log.driverName}',
                    style: TextStyle(
                      color: AppTheme.textMuted.withValues(alpha: 0.9),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Boarded: ${_fmtTime(log.boardedAt)}   •   Alighted: ${_fmtTime(log.alightedAt)}',
                    style: TextStyle(
                      color: AppTheme.textMuted.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (log.vehicleNumber.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Vehicle: ${log.vehicleNumber}',
                        style: TextStyle(
                          color: AppTheme.textMuted.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportLine extends StatelessWidget {
  final String label;
  final String value;
  const _ReportLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
