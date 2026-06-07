import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/admin_service.dart';
import '../../../trips/data/daily_session_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../admin_dashboard_screen.dart';

class AdminTripsTab extends ConsumerStatefulWidget {
  const AdminTripsTab({super.key});

  @override
  ConsumerState<AdminTripsTab> createState() => _AdminTripsTabState();
}

class _AdminTripsTabState extends ConsumerState<AdminTripsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Sub-tabs ──────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.3))),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: kAdminNavy,
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: kAdminNavy,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            tabs: const [
              Tab(text: 'Live Trips'),
              Tab(text: 'History'),
            ],
          ),
        ),

        // ── Tab content ───────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _LiveTripsView(),
              const _TripHistoryView(),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Live Trips
// ──────────────────────────────────────────────────────────────────────────────

class _LiveTripsView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync = ref.watch(adminLiveTripsProvider);

    return liveAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.airline_seat_recline_normal_rounded, size: 52, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No trips are active right now.', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _LiveTripCard(session: session)
                .animate()
                .fade(delay: Duration(milliseconds: 40 * index.clamp(0, 8)))
                .slideY(begin: 0.04);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: kAdminNavy)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Error: $e', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}

class _LiveTripCard extends StatelessWidget {
  final DailySessionModel session;
  const _LiveTripCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 6))],
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.successGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('LIVE', style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
              const Spacer(),
              Text(session.date, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Trip ${session.tripId.length > 12 ? '${session.tripId.substring(0, 12)}…' : session.tripId}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Driver: ${session.driverUid.length > 16 ? '${session.driverUid.substring(0, 16)}…' : session.driverUid}',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: null, // indeterminate — trip is live
              backgroundColor: Color(0xFFE8EAF6),
              valueColor: AlwaysStoppedAnimation<Color>(kAdminNavy),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Trip History
// ──────────────────────────────────────────────────────────────────────────────

class _TripHistoryView extends StatefulWidget {
  const _TripHistoryView();

  @override
  State<_TripHistoryView> createState() => _TripHistoryViewState();
}

class _TripHistoryViewState extends State<_TripHistoryView> {
  DateTime _selectedDate = DateTime.now();
  List<DailySessionModel> _history = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    try {
      // COMPOSITE INDEX REQUIRED: daily_sessions → status (Asc) + date (Desc)
      final snap = await FirebaseFirestore.instance
          .collection('daily_sessions')
          .where('status', isEqualTo: 'completed')
          .where('date', isEqualTo: dateStr)
          .limit(30)
          .get();

      setState(() {
        _history = snap.docs.map((d) => DailySessionModel.fromJson(d.data(), d.id)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Date picker header ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                _loadHistory();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: kAdminNavy, size: 18),
                  const SizedBox(width: 12),
                  Text(
                    "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text('Tap to change', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
          ),
        ),

        // ── History list ──────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kAdminNavy))
              : _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_rounded, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('No completed trips on this date.', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final session = _history[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: kAdminNavy.withValues(alpha: 0.06),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_rounded, color: kAdminNavy, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Trip ${session.tripId.length > 10 ? '${session.tripId.substring(0, 10)}…' : session.tripId}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Driver: ${session.driverUid.length > 14 ? '${session.driverUid.substring(0, 14)}…' : session.driverUid}',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(session.date, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
