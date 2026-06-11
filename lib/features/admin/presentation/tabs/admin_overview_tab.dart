import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/admin_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../admin_dashboard_screen.dart';
import '../admin_schools_screen.dart';

class AdminOverviewTab extends ConsumerWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final liveTripsAsync = ref.watch(adminLiveTripsProvider);

    return RefreshIndicator(
      color: kAdminNavy,
      onRefresh: () async {
        ref.invalidate(adminStatsProvider);
        ref.invalidate(adminLiveTripsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ── Section header ───────────────────────────────────────────────
          const Text(
            'System Health',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kAdminNavy, letterSpacing: -0.3),
          ),
          const SizedBox(height: 3),
          Text(
            'Real-time snapshot of SafePick operations',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 20),

          // ── Stat cards ──────────────────────────────────────────────────
          statsAsync.when(
            data: (stats) => GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.18,
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
            ).animate().fade(duration: 250.ms).slideY(begin: 0.03),
            loading: () => const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(color: kAdminNavy, strokeWidth: 2.5)),
            ),
            error: (e, _) => _ErrorCard(message: 'Could not load stats: $e'),
          ),

          const SizedBox(height: 28),

          // ── School Management ─────────────────────────────────────────────
          const Text(
            'School Management',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: kAdminNavy, letterSpacing: -0.2),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminSchoolsScreen()));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.015), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kAdminNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.domain_rounded, color: kAdminNavy, size: 22),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manage Schools & Map', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Add, edit, or remove school locations.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Live trip indicator ──────────────────────────────────────────
          const Text(
            'Live Right Now',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: kAdminNavy, letterSpacing: -0.2),
          ),
          const SizedBox(height: 12),

          liveTripsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.airline_seat_recline_normal_rounded, size: 36, color: AppTheme.textMuted.withValues(alpha: 0.3)),
                      const SizedBox(height: 10),
                      Text(
                        'All quiet — no active trips.', 
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.015), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.25)),
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
                        Text(
                          '${sessions.length} trip${sessions.length > 1 ? 's' : ''} in progress', 
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: -0.1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...sessions.take(3).map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_bus_filled_rounded, size: 16, color: kAdminNavy),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Trip ${s.tripId.substring(0, 8)}…',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            s.date, 
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5, fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    )),
                    if (sessions.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Center(
                          child: Text(
                            '+${sessions.length - 3} more',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(color: kAdminNavy, strokeWidth: 2.5)),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.015), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value, 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
              ),
              const SizedBox(height: 1),
              Text(
                title, 
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w400),
                overflow: TextOverflow.ellipsis,
              ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.errorRed.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.errorRed, fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}