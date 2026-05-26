import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/daily_session_model.dart';

final driverHistoryProvider = StreamProvider<List<DailySessionModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final currentUser = ref.watch(firebaseAuthProvider).currentUser;

  if (currentUser == null) return Stream.value(const []);

  return firestore
      .collection('daily_sessions')
      .where('driver_uid', isEqualTo: currentUser.uid)
      .where('status', isEqualTo: 'completed')
      .orderBy('start_time', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => DailySessionModel.fromJson(doc.data(), doc.id))
          .toList());
});

final tripNameProvider = FutureProvider.family<String, String>((ref, tripId) async {
  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore.collection('trips').doc(tripId).get();
  if (doc.exists) {
    return doc.data()?['trip_name'] as String? ?? 'Unknown Trip';
  }
  return 'Unknown Trip';
});

class TripHistoryScreen extends ConsumerWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(driverHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Trip History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: historyAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No completed trips yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildHistoryCard(context, ref, theme, session);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold)),
        ),
        error: (error, _) {
          if (error.toString().contains('failed-precondition')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.build_circle_outlined, size: 48, color: AppTheme.primaryGold),
                    const SizedBox(height: 16),
                    Text(
                      'Database index building.\nPlease check back in a few minutes.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: Text(
              'Error loading history: $error',
              style: const TextStyle(color: AppTheme.errorRed),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, WidgetRef ref, ThemeData theme, DailySessionModel session) {
    final nameAsync = ref.watch(tripNameProvider(session.tripId));
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    final startTimeStr = timeFormat.format(session.startTime);
    final endTimeStr = session.endTime != null ? timeFormat.format(session.endTime!) : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              nameAsync.when(
                data: (name) => Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                loading: () => const Expanded(child: Text('Loading...')),
                error: (error, _) => const Expanded(child: Text('Unknown Trip')),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'COMPLETED',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(session.startTime),
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                '$startTimeStr - $endTimeStr',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
