import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../students/data/student_ride_log_model.dart';
import '../../../../core/theme/app_theme.dart';

class AdminReportsTab extends ConsumerStatefulWidget {
  const AdminReportsTab({super.key});

  @override
  ConsumerState<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends ConsumerState<AdminReportsTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String? _studentId;
  List<StudentRideLogModel> _logs = [];

  Future<void> _searchStudent() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _studentId = _searchController.text.trim();
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .doc(_studentId)
          .collection('ride_history')
          .orderBy('date', descending: true)
          .limit(20)
          .get();

      setState(() {
        _logs = snap.docs.map((d) => StudentRideLogModel.fromJson(d.data(), d.id)).toList();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _generateReport() {
    if (_studentId == null || _logs.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Student Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student ID: $_studentId', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total Trips Recorded: ${_logs.length}'),
            const SizedBox(height: 8),
            const Text('Attendance Rate: ~95% (Sample)'), // In real app, calculate from actual data stats
            const SizedBox(height: 16),
            const Text('Screenshot this summary for records.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Enter Student ID (e.g. SP1001)',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _searchStudent(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSearching ? null : _searchStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Search'),
              ),
            ],
          ),
        ),
        if (_studentId != null && _logs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Results for $_studentId', style: const TextStyle(fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  onPressed: _generateReport,
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Report'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A237E)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: _studentId == null 
              ? const Center(child: Text('Search for a student to view their audit timeline.', style: TextStyle(color: Colors.grey)))
              : _logs.isEmpty 
                  ? const Center(child: Text('No ride history found for this student.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return _TimelineNode(log: log, isLast: index == _logs.length - 1);
                      },
                    ),
        ),
      ],
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final StudentRideLogModel log;
  final bool isLast;

  const _TimelineNode({required this.log, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: log.status == 'Absent' ? Colors.orange : const Color(0xFF1A237E),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 60, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(log.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(log.status.toUpperCase(), style: TextStyle(color: log.status == 'Absent' ? Colors.orange : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Trip: ${log.tripName} • Driver: ${log.driverName}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
