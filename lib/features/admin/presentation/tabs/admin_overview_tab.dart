import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/admin_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../admin_dashboard_screen.dart';

class AdminOverviewTab extends ConsumerWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final liveTripsAsync = ref.watch(adminLiveTripsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminStatsProvider);
        ref.invalidate(adminLiveTripsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ── Section header ───────────────────────────────────────────────
          const Text(
            'System Health',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kAdminNavy),
          ),
          const SizedBox(height: 4),
          Text(
            'Real-time snapshot of SafePick operations',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ── Stat cards ──────────────────────────────────────────────────
          statsAsync.when(
            data: (stats) => GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.15,
              children: [
                _StatCard(
                  title: 'Active Trips',
                  value: '${stats['active_trips_today'] ?? 0}',
                  icon: Icons.directions_bus_rounded,
                  color: AppTheme.successGreen,
                ),
                _StatCard(
                  title: 'Total Students',
                  value: '${stats['total_students'] ?? 0}',
                  icon: Icons.school_rounded,
                  color: kAdminNavy,
                ),
                _StatCard(
                  title: 'Total Drivers',
                  value: '${stats['total_drivers'] ?? 0}',
                  icon: Icons.badge_rounded,
                  color: Colors.teal,
                ),
                _StatCard(
                  title: 'Absent Today',
                  value: '${stats['absent_today'] ?? 0}',
                  icon: Icons.person_off_rounded,
                  color: AppTheme.warningOrange,
                ),
              ],
            ).animate().fade(duration: 300.ms).slideY(begin: 0.05),
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: kAdminNavy)),
            ),
            error: (e, _) => _ErrorCard(message: 'Could not load stats: $e'),
          ),

          const SizedBox(height: 32),

          // ── Live trip indicator ──────────────────────────────────────────
          const Text(
            'Live Right Now',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kAdminNavy),
          ),
          const SizedBox(height: 16),

          liveTripsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.airline_seat_recline_normal_rounded, size: 40, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('All quiet — no active trips.', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))],
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppTheme.successGreen, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text('${sessions.length} trip${sessions.length > 1 ? 's' : ''} in progress', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...sessions.take(3).map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_bus_filled_rounded, size: 18, color: kAdminNavy),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Trip ${s.tripId.substring(0, 8)}…',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(s.date, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    )),
                    if (sessions.length > 3)
                      Center(
                        child: Text(
                          '+${sessions.length - 3} more',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator(color: kAdminNavy)),
            ),
            error: (e, _) => _ErrorCard(message: 'Could not load live trips: $e'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Private Widgets
// ──────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.errorRed.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppTheme.errorRed.withValues(alpha: 0.8), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
