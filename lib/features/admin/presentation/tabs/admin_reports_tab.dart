import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/admin_service.dart';
import '../../services/pdf_report_service.dart';
import '../../../students/data/student_model.dart';
import '../../../students/data/student_ride_log_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../admin_dashboard_screen.dart';

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
    return students.where((s) => s.name.toLowerCase().contains(q) || s.studentId.toLowerCase().contains(q)).toList();
  }

  Future<void> _loadRideLogs(String studentId) async {
    setState(() => _isLoadingLogs = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students').doc(studentId)
          .collection('ride_history')
          .orderBy('date', descending: true)
          .limit(50)
          .get();
      setState(() => _logs = snap.docs.map((d) => StudentRideLogModel.fromJson(d.data(), d.id)).toList());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoadingLogs = false);
    }
  }

  Future<void> _downloadPdf() async {
    if (_selectedStudent == null || _isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);
    try {
      await PdfReportService.generateStudentReport(context, _selectedStudent!, _logs);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF Error: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _showReport() {
    if (_selectedStudent == null) return;
    final totalTrips = _selectedStudent!.stats['total_trips'] ?? _logs.length;
    final absences = _logs.where((l) => l.status == 'Absent').length;
    final rate = _logs.isNotEmpty ? ((_logs.length - absences) / _logs.length * 100).toStringAsFixed(1) : 'N/A';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.analytics_rounded, color: kAdminNavy, size: 22),
            SizedBox(width: 10),
            Expanded(child: Text('Student Report', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReportLine(label: 'Student', value: _selectedStudent!.name),
            _ReportLine(label: 'ID', value: _selectedStudent!.studentId),
            _ReportLine(label: 'School', value: _selectedStudent!.schoolName.isNotEmpty ? _selectedStudent!.schoolName : '—'),
            _ReportLine(label: 'Grade', value: _selectedStudent!.grade.isNotEmpty ? _selectedStudent!.grade : '—'),
            const Divider(height: 28),
            _ReportLine(label: 'Total Trips', value: '$totalTrips'),
            _ReportLine(label: 'Attendance Rate', value: '$rate%'),
            _ReportLine(label: 'Total Absences', value: '$absences'),
            _ReportLine(label: 'Current Status', value: _selectedStudent!.currentStatus),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: kAdminNavy))),
        ],
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search students by name or ID…',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.4))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.4))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kAdminNavy, width: 1.5)),
            ),
          ),
        ),
        Expanded(
          child: studentsAsync.when(
            data: (all) {
              final students = _filterStudents(all);
              if (students.isEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.school_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(_searchQuery.isNotEmpty ? 'No students match.' : 'No students.', style: TextStyle(color: Colors.grey[500])),
                ]));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: students.length,
                itemBuilder: (ctx, i) {
                  final s = students[i];
                  return _StudentTile(student: s, onTap: () {
                    setState(() => _selectedStudent = s);
                    _loadRideLogs(s.studentId);
                  }).animate().fade(delay: Duration(milliseconds: 25 * i.clamp(0, 12))).slideX(begin: 0.02);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: kAdminNavy)),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
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
                  IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => setState(() { _selectedStudent = null; _logs.clear(); })),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_selectedStudent!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${_selectedStudent!.studentId} • ${_selectedStudent!.schoolName}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ]),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showReport,
                    icon: const Icon(Icons.summarize_rounded, size: 16, color: kAdminNavy),
                    label: const Text('Stats', style: TextStyle(color: kAdminNavy, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kAdminNavy.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Timeline
            Expanded(
              child: _isLoadingLogs
                  ? const Center(child: CircularProgressIndicator(color: kAdminNavy))
                  : _logs.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.history_rounded, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('No ride history.', style: TextStyle(color: Colors.grey[500])),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 80), // extra bottom for FAB
                          itemCount: _logs.length,
                          itemBuilder: (_, i) => _TimelineNode(log: _logs[i], isLast: i == _logs.length - 1),
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
              icon: _isGeneratingPdf
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: Text(_isGeneratingPdf ? 'Generating…' : 'Download PDF'),
            ).animate().fade().slideY(begin: 0.3),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Private widgets (unchanged from before, moved here for completeness)
// ──────────────────────────────────────────────────────────────────────────────

class _StudentTile extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onTap;
  const _StudentTile({required this.student, required this.onTap});

  Color get _statusColor {
    switch (student.currentStatus) {
      case 'In Van': return Colors.orange;
      case 'At School': return kAdminNavy;
      case 'Absent': return AppTheme.errorRed;
      default: return AppTheme.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(radius: 20, backgroundColor: _statusColor.withValues(alpha: 0.08), child: Icon(Icons.school_rounded, color: _statusColor, size: 20)),
        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text('${student.studentId} • ${student.currentStatus}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
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
      case 'Absent': return AppTheme.warningOrange;
      case 'At School': return kAdminNavy;
      case 'At Home': return AppTheme.successGreen;
      default: return Colors.grey;
    }
  }

  String _fmtTime(DateTime? dt) => dt != null ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}' : 'N/A';

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 24, child: Column(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle)),
          if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey[200])),
        ])),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(log.date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _dotColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Text(log.status.toUpperCase(), style: TextStyle(color: _dotColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ]),
              const SizedBox(height: 4),
              Text('${log.tripName} • ${log.driverName}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 2),
              Text('Boarded: ${_fmtTime(log.boardedAt)}  •  Alighted: ${_fmtTime(log.alightedAt)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              if (log.vehicleNumber.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 2), child: Text('Vehicle: ${log.vehicleNumber}', style: TextStyle(color: Colors.grey[400], fontSize: 11))),
            ]),
          ),
        ),
      ]),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis, textAlign: TextAlign.end)),
      ]),
    );
  }
}
