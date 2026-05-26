import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/trip_model.dart';
import 'trip_detail_screen.dart';
import 'create_trip_screen.dart';

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

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.border, width: 1),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'No',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: AppTheme.background,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tripsAsync = ref.watch(driverTripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _handleSignOut(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Text(
                "Today's Trips",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Assigned transport routes and manifests.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Assigned Trips List
              Expanded(
                child: tripsAsync.when(
                  data: (trips) {
                    if (trips.isEmpty) {
                      return _buildEmptyState(theme);
                    }
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        return _buildTripCard(context, theme, trip);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                    ),
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

  Widget _buildTripCard(BuildContext context, ThemeData theme, TripModel trip) {
    final isPickup = trip.tripType.toLowerCase() == 'pickup';
    final isActive = trip.status.toLowerCase() == 'active';
    final isCompleted = trip.status.toLowerCase() == 'completed';

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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Route Title
                Expanded(
                  child: Text(
                    trip.tripName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.successGreen.withValues(alpha: 0.15)
                        : isActive
                            ? AppTheme.primaryGold.withValues(alpha: 0.15)
                            : AppTheme.textSecondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trip.status.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isCompleted
                          ? AppTheme.successGreen
                          : isActive
                              ? AppTheme.primaryGold
                              : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                // Trip Type info
                Icon(
                  isPickup ? Icons.login_rounded : Icons.logout_rounded,
                  color: AppTheme.primaryGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isPickup ? 'Morning Pick-Up' : 'Afternoon Drop-Off',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Estimated Duration info
                const Icon(
                  Icons.schedule_rounded,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  trip.estimatedDuration,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Action button to start/view route details
            ElevatedButton.icon(
              onPressed: isCompleted
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TripDetailScreen(tripId: trip.tripId),
                        ),
                      );
                    },
              icon: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                color: isCompleted ? AppTheme.textSecondary : AppTheme.background,
              ),
              label: Text(isCompleted ? 'Route Completed' : 'Start Route'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? AppTheme.border : AppTheme.primaryGold,
                foregroundColor: isCompleted ? AppTheme.textMuted : AppTheme.background,
              ),
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
            'Check back later or contact transport dispatch.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
