import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/history_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../students/data/student_model.dart';
import '../../students/data/student_ride_log_model.dart';

final studentHistoryProvider = FutureProvider.family<List<StudentRideLogModel>, String>((ref, studentId) async {
  final historyService = ref.watch(historyServiceProvider);
  return historyService.getAllStudentHistory(studentId);
});

class StudentHistoryScreen extends ConsumerStatefulWidget {
  final StudentModel student;

  const StudentHistoryScreen({super.key, required this.student});

  @override
  ConsumerState<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends ConsumerState<StudentHistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsyncValue = ref.watch(studentHistoryProvider(widget.student.studentId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Trip History',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              widget.student.name,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Clear 2-part Date Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              border: Border(bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.3))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    label: 'Start Date',
                    selectedDate: _startDate,
                    onTap: () => _pickDate(isStart: true),
                    onClear: () => setState(() => _startDate = null),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateSelector(
                    label: 'End Date',
                    selectedDate: _endDate,
                    onTap: () => _pickDate(isStart: false),
                    onClear: () => setState(() => _endDate = null),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: historyAsyncValue.when(
        data: (logs) {
          // Local Filtering
          final filteredLogs = logs.where((log) {
            if (_startDate == null && _endDate == null) return true;
            
            final logDate = log.boardedAt ?? log.alightedAt ?? DateTime.tryParse(log.date);
            if (logDate == null) return false;

            if (_startDate != null) {
              final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
              if (logDate.isBefore(start)) return false;
            }
            if (_endDate != null) {
              final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
              if (logDate.isAfter(end)) return false;
            }
            return true;
          }).toList();

          if (filteredLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    (_startDate == null && _endDate == null) ? 'No trip history available.' : 'No trips found in this date range.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: filteredLogs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final log = filteredLogs[index];
              return _buildHistoryCard(theme, log);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
        error: (e, st) => Center(child: Text('Failed to load history: $e')),
      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector({
    required String label, 
    required DateTime? selectedDate, 
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);
    final hasDate = selectedDate != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          border: Border.all(
            color: hasDate ? AppTheme.primaryGold.withValues(alpha: 0.5) : AppTheme.border.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.primaryGold),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDate ? DateFormat('MMM d, yyyy').format(selectedDate) : 'Select',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasDate ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontWeight: hasDate ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
              )
            else
              const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final theme = Theme.of(context);
    
    // Determine reasonable constraints
    final initialDate = isStart 
        ? (_startDate ?? DateTime.now()) 
        : (_endDate ?? DateTime.now());
        
    final firstDate = isStart ? DateTime(2020) : (_startDate ?? DateTime(2020));
    final lastDate = isStart ? (_endDate ?? DateTime.now().add(const Duration(days: 1))) : DateTime.now().add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDatePickerMode: DatePickerMode.day,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppTheme.primaryGold,
              onPrimary: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: AppTheme.surface),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Widget _buildHistoryCard(ThemeData theme, StudentRideLogModel log) {
    final isMorning = log.tripType.toLowerCase() == 'morning';
    final formatter = DateFormat('MMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');
    
    // Fallback date
    final displayDate = log.boardedAt != null 
        ? formatter.format(log.boardedAt!) 
        : (log.alightedAt != null ? formatter.format(log.alightedAt!) : log.date);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  log.tripName.isNotEmpty ? log.tripName : 'Unknown Trip',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isMorning 
                      ? AppTheme.primaryGold.withValues(alpha: 0.1) 
                      : AppTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.tripType,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isMorning ? AppTheme.primaryGold : AppTheme.successGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            displayDate,
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          
          // Timeline
          _buildTimelineRow(
            theme, 
            icon: Icons.login_rounded, 
            label: 'Boarded', 
            time: log.boardedAt != null ? timeFormatter.format(log.boardedAt!) : '--:--',
            iconColor: AppTheme.textPrimary,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 11.0, top: 4, bottom: 4),
            child: Container(
              height: 16,
              width: 2,
              color: AppTheme.border.withValues(alpha: 0.5),
            ),
          ),
          _buildTimelineRow(
            theme, 
            icon: Icons.logout_rounded, 
            label: 'Alighted', 
            time: log.alightedAt != null ? timeFormatter.format(log.alightedAt!) : '--:--',
            iconColor: AppTheme.textSecondary,
          ),
          
          if (log.driverName.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: AppTheme.border.withValues(alpha: 0.3), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_rounded, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Driver: ${log.driverName}',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                ),
                if (log.vehicleNumber.isNotEmpty) ...[
                  const Spacer(),
                  const Icon(Icons.directions_car_rounded, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    log.vehicleNumber,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
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
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(width: 16),
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
