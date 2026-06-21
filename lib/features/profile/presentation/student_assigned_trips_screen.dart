import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../students/data/student_model.dart';
import '../../../core/widgets/safe_pick_dialog.dart';
import '../../trips/data/trip_model.dart';
import '../../trips/domain/trip_service.dart';

class StudentAssignedTripsScreen extends ConsumerWidget {
  final StudentModel student;

  const StudentAssignedTripsScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tripsAsync = ref.watch(studentTripsProvider(student.studentId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Assigned Trips',
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
      body: tripsAsync.when(
        data: (trips) {
          if (trips.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.route_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No Assigned Trips',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${student.name} is not currently assigned to any active morning or afternoon trips.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return _buildTripCard(context, ref, theme, trip);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
        error: (err, st) => Center(
          child: Text('Error loading trips: $err', style: const TextStyle(color: AppTheme.errorRed)),
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, WidgetRef ref, ThemeData theme, TripModel trip) {
    final isMorning = trip.tripType.toLowerCase() == 'morning';
    final cardColor = isMorning ? Colors.orange : Colors.indigo;
    final iconData = isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: cardColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.tripName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trip.tripType} Trip',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.person_remove_rounded, size: 20),
              label: const Text('Remove from Trip', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _confirmRemoveTrip(context, ref, trip),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveTrip(BuildContext context, WidgetRef ref, TripModel trip) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (builderCtx, setState) {
            return SafePickDialog(
              title: 'Remove from Trip?',
              description: isLoading 
                  ? 'Removing student...' 
                  : 'Are you sure you want to remove ${student.name} from "${trip.tripName}"? This action cannot be undone.',
              isDestructive: true,
              primaryActionLabel: isLoading ? 'Removing...' : 'Remove',
              isPrimaryActionEnabled: !isLoading,
              onPrimaryAction: isLoading ? null : () async {
                setState(() => isLoading = true);
                try {
                  await ref.read(tripServiceProvider).removeStudentFromTrip(trip.tripId, student.studentId);
                  
                  // Pop the dialog route using the dialog's context.
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                  
                  // Display success message using screen's context.
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Student removed from trip successfully.')),
                    );
                  }
                } catch (e) {
                  if (builderCtx.mounted) {
                    setState(() => isLoading = false);
                  }
                  // Display error message using screen's context.
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed),
                    );
                  }
                }
              },
              secondaryActionLabel: isLoading ? null : 'Cancel',
              onSecondaryAction: isLoading ? null : () => Navigator.pop(dialogCtx),
            );
          },
        );
      },
    );
  }
}
