import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/trip_model.dart';
import 'trip_detail_screen.dart';
import 'create_trip_screen.dart';
import '../../profile/presentation/driver_profile_screen.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/services/test_mqtt_service.dart';

/// Real-time stream provider that fetches all trips assigned to the logged-in driver.
final driverTripsProvider = StreamProvider<List<TripModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final currentUser = ref.watch(firebaseAuthProvider).currentUser;

  if (currentUser == null) {
    return Stream.value(const []);
  }

  return firestore
      .collection('trips')
      .where('driver_uid', isEqualTo: currentUser.uid)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TripModel.fromJson(doc.data(), doc.id))
          .toList());
});

class DriverDashboard extends ConsumerWidget {
  const DriverDashboard({super.key});

  bool _isTripCompletedToday(TripModel trip) {
    if (trip.lastCompletedDate == null) return false;
    final now = DateTime.now();
    final completedDate = trip.lastCompletedDate!;
    return completedDate.year == now.year &&
        completedDate.month == now.month &&
        completedDate.day == now.day;
  }



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tripsAsync = ref.watch(driverTripsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/images/light_logo.jpg',
          height: 32,
        ),
        actions: [
          TextButton(
            onPressed: () => TestMqttService().testConnection(),
            child: const Text('TEST MQTT', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryGold),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DriverProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              Text(
                "Today's Trips",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fade().slideY(begin: -0.1),
              const SizedBox(height: 8),
              Text(
                'Assigned transport routes and manifests.',
                style: theme.textTheme.bodyMedium,
              ).animate().fade(delay: 100.ms).slideY(begin: -0.1),
              const SizedBox(height: 24),

              // Summary & List
              Expanded(
                child: tripsAsync.when(
                  data: (trips) {
                    if (trips.isEmpty) {
                      return _buildEmptyState(theme);
                    }

                    // Sort trips: completed today goes to the bottom, active/pending on top
                    // For pending, Morning trips appear first, followed by Afternoon
                    final sortedTrips = List<TripModel>.from(trips)..sort((a, b) {
                      final aCompleted = _isTripCompletedToday(a);
                      final bCompleted = _isTripCompletedToday(b);
                      if (aCompleted && !bCompleted) return 1;
                      if (!aCompleted && bCompleted) return -1;
                      
                      // Both are either completed or pending. Sort by type: Morning first
                      final aType = a.tripType.toLowerCase();
                      final bType = b.tripType.toLowerCase();
                      if (aType == 'morning' && bType != 'morning') return -1;
                      if (aType != 'morning' && bType == 'morning') return 1;
                      return 0;
                    });

                    final totalTrips = sortedTrips.length;
                    final pendingTrips = sortedTrips.where((t) {
                      final isCompletedToday = _isTripCompletedToday(t);
                      final isActive = t.status == 'active';
                      return !isCompletedToday && !isActive;
                    }).length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryCards(theme, totalTrips, pendingTrips),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: sortedTrips.length,
                            itemBuilder: (context, index) {
                              final trip = sortedTrips[index];
                              return _buildTripCard(context, theme, trip)
                                  .animate()
                                  .fade(delay: Duration(milliseconds: 300 + (index * 100)))
                                  .slideY(begin: 0.1);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: ShimmerLoading(width: double.infinity, height: 100, borderRadius: 20)),
                          const SizedBox(width: 16),
                          Expanded(child: ShimmerLoading(width: double.infinity, height: 100, borderRadius: 20)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Expanded(child: ShimmerList(itemCount: 4, itemHeight: 140)),
                    ],
                  ),
                  error: (error, stackTrace) => _buildErrorState(theme, error.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateTripScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme, int total, int pending) {
    return Row(
      children: [
        Expanded(
          child: _buildSingleSummaryCard(theme, 'Total Trips', total.toString()),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSingleSummaryCard(theme, 'Pending Today', pending.toString()),
        ),
      ],
    ).animate().fade(delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildSingleSummaryCard(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C), // Dark grey background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppTheme.primaryGold, // Bright amber accents
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, ThemeData theme, TripModel trip) {
    final isMorning = trip.tripType.toLowerCase() == 'morning';
    final isActive = trip.status.toLowerCase() == 'active';
    final isCompletedToday = _isTripCompletedToday(trip);

    // Dynamic UI states based on daily reset logic
    final String statusLabel;
    final Color badgeColor;
    if (isActive) {
      statusLabel = 'ACTIVE';
      badgeColor = AppTheme.primaryGold;
    } else if (isCompletedToday) {
      statusLabel = 'COMPLETED';
      badgeColor = AppTheme.successGreen;
    } else {
      statusLabel = 'READY';
      badgeColor = const Color(0xFFE0E0E0);
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TripDetailScreen(tripId: trip.tripId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.tripName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            isMorning ? Icons.login_rounded : Icons.logout_rounded,
                            color: AppTheme.primaryGold,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isMorning ? 'Morning Pick-Up' : 'Afternoon Drop-Off',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: (isCompletedToday || isActive) ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: AppTheme.primaryGold,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No trips assigned for today.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later, contact transport dispatch, or create a new trip using the button below.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fade().scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to load assigned trips',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.errorRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
