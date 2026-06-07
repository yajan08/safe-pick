import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/admin_service.dart';
import '../../../../core/theme/app_theme.dart';

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
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1A237E),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1A237E),
            tabs: const [
              Tab(text: 'Live Trips'),
              Tab(text: 'History'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLiveTrips(),
              const _TripHistoryView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveTrips() {
    final liveTripsAsync = ref.watch(liveTripsProvider);
    
    return liveTripsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Center(child: Text('No active trips right now.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.border.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('LIVE', style: TextStyle(color: AppTheme.successGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        Text(session.date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Trip ID: ${session.tripId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Driver UID: ${session.driverUid}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(
                      value: 0.5,
                      backgroundColor: Color(0xFFE8EAF6),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                    ),
                    const SizedBox(height: 8),
                    const Center(child: Text('In Progress...', style: TextStyle(fontSize: 12, color: Colors.grey))),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _TripHistoryView extends StatefulWidget {
  const _TripHistoryView();

  @override
  State<_TripHistoryView> createState() => _TripHistoryViewState();
}

class _TripHistoryViewState extends State<_TripHistoryView> {
  DateTime _selectedDate = DateTime.now();
  
  @override
  Widget build(BuildContext context) {
    // In a full implementation, this would use a paginated query on daily_sessions where status == 'completed'
    // For MVP, we simply show a date picker header and a placeholder or simple query.
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 20),
              const SizedBox(width: 12),
              Text(
                "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: const Text('Change Date'),
              )
            ],
          ),
        ),
        const Expanded(
          child: Center(
            child: Text('Historical trip logs will appear here.', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }
}
