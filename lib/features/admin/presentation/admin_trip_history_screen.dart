import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../trips/data/daily_session_model.dart';
import '../../trips/data/trip_model.dart';
import 'admin_dashboard_screen.dart' show kAdminNavy;

final tripHistoryProvider = FutureProvider.family<List<DailySessionModel>, String>((ref, tripId) async {
  final firestore = FirebaseFirestore.instance;
  final snap = await firestore
      .collection('daily_sessions')
      .where('trip_id', isEqualTo: tripId)
      .orderBy('start_time', descending: true)
      .get();
      
  return snap.docs.map((doc) => DailySessionModel.fromJson(doc.data(), doc.id)).toList();
});

class AdminTripHistoryScreen extends ConsumerStatefulWidget {
  final TripModel trip;

  const AdminTripHistoryScreen({super.key, required this.trip});

  @override
  ConsumerState<AdminTripHistoryScreen> createState() => _AdminTripHistoryScreenState();
}

class _AdminTripHistoryScreenState extends ConsumerState<AdminTripHistoryScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(tripHistoryProvider(widget.trip.tripId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        foregroundColor: kAdminNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Trip History',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.5,
                color: kAdminNavy,
              ),
            ),
            Text(
              widget.trip.tripName,
              style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded, color: kAdminNavy, size: 22),
            tooltip: 'Filter by Date',
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDateRange: _selectedDateRange,
                builder: (context, child) {
                  return Theme(
                    data: theme.copyWith(
                      colorScheme: theme.colorScheme.copyWith(
                        primary: kAdminNavy,
                        onPrimary: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (range != null) {
                setState(() => _selectedDateRange = range);
              }
            },
          ),
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded, color: AppTheme.errorRed, size: 22),
              tooltip: 'Clear Filter',
              onPressed: () => setState(() => _selectedDateRange = null),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: historyAsync.when(
        data: (sessions) {
          final filteredSessions = sessions.where((s) {
            if (_selectedDateRange == null) return true;
            final date = s.startTime ?? DateTime.tryParse(s.date);
            if (date == null) return false;
            final start = _selectedDateRange!.start;
            final end = _selectedDateRange!.end.add(const Duration(days: 1));
            return date.isAfter(start.subtract(const Duration(seconds: 1))) && date.isBefore(end);
          }).toList();

          if (filteredSessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    _selectedDateRange == null ? 'No sessions recorded yet.' : 'No sessions found in this date range.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: filteredSessions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final session = filteredSessions[index];
              return _buildSessionCard(session, theme);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: kAdminNavy)),
        error: (e, _) => Center(child: Text('Error loading history: $e')),
      ),
    );
  }

  Widget _buildSessionCard(DailySessionModel session, ThemeData theme) {
    final formatter = DateFormat('MMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');
    
    final displayDate = session.startTime != null ? formatter.format(session.startTime!) : session.date;
    final isMorning = widget.trip.tripType.toLowerCase() == 'morning';
    final isCompleted = session.status == 'completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayDate,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? AppTheme.successGreen.withValues(alpha: 0.1) 
                      : AppTheme.warningOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'In Progress',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isCompleted ? AppTheme.successGreen : AppTheme.warningOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (session.isRedo) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'REDO SESSION',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildTimelineRow(
            theme,
            icon: Icons.play_circle_fill_rounded,
            label: 'Started',
            time: session.startTime != null ? timeFormatter.format(session.startTime!) : '--:--',
            iconColor: isMorning ? AppTheme.primaryGold : AppTheme.successGreen,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 9.0, top: 4, bottom: 4),
            child: Container(
              height: 12,
              width: 2,
              color: AppTheme.border.withValues(alpha: 0.5),
            ),
          ),
          _buildTimelineRow(
            theme,
            icon: Icons.stop_circle_rounded,
            label: 'Ended',
            time: session.endTime != null ? timeFormatter.format(session.endTime!) : '--:--',
            iconColor: AppTheme.textSecondary,
          ),
          
          if (session.finalStatuses != null && session.finalStatuses!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: AppTheme.border.withValues(alpha: 0.3), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.people_alt_rounded, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Manifest Size: ${session.finalStatuses!.length}',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineRow(ThemeData theme, {required IconData icon, required String label, required String time, required Color iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          time,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
