import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/domain/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/trip_model.dart';
import 'trip_detail_screen.dart';
import 'create_trip_screen.dart';
import 'driver_profile_screen.dart';
import '../../../core/widgets/shimmer_loading.dart';

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
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 68,
        shape: const Border(
          bottom: BorderSide(color: AppTheme.border, width: 1.0),
        ),
        title: SvgPicture.asset(
          'assets/images/logo.svg',
          height: 56, // Scaled up for better visibility
        ).animate().fade().scale(delay: 100.ms, curve: Curves.easeOutBack),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DriverProfileScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.6), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.surfaceCard,
                child: const Icon(Icons.person_outline_rounded, color: AppTheme.textPrimary, size: 18),
              ),
            ),
          ).animate().fade(delay: 200.ms),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Functional Header
              Text(
                "Today's Trips",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppTheme.textPrimary,
                ),
              ).animate().fade().slideY(begin: -0.05),
              const SizedBox(height: 4),
              Text(
                'Assigned transport routes and manifests.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ).animate().fade(delay: 50.ms).slideY(begin: -0.05),
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
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 100), // Clearance for FAB
                            itemCount: sortedTrips.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final trip = sortedTrips[index];
                              return _buildTripCard(context, theme, trip)
                                  .animate()
                                  .fade(delay: Duration(milliseconds: 150 + (index * 50)))
                                  .slideY(begin: 0.05, curve: Curves.easeOut);
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
                        children: const [
                          Expanded(child: ShimmerCard(height: 110)),
                          SizedBox(width: 16),
                          Expanded(child: ShimmerCard(height: 110)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Expanded(child: ShimmerList(itemCount: 4, itemHeight: 96)),
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
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateTripScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ).animate().fade(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildSummaryCards(ThemeData theme, int total, int pending) {
    return Row(
      children: [
        Expanded(
          child: _buildSingleSummaryCard(
            theme: theme, 
            label: 'Total Routes', 
            value: total.toString(),
            icon: Icons.route_rounded,
            iconColor: AppTheme.primaryGold,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSingleSummaryCard(
            theme: theme, 
            label: 'Pending', 
            value: pending.toString(),
            icon: Icons.pending_actions_rounded,
            iconColor: AppTheme.textSecondary,
          ),
        ),
      ],
    ).animate().fade(delay: 100.ms).slideY(begin: 0.05, curve: Curves.easeOut);
  }

  Widget _buildSingleSummaryCard({
    required ThemeData theme, 
    required String label, 
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard, // Replaced harsh dark grey with clean surface
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, ThemeData theme, TripModel trip) {
    final isMorning = trip.tripType.toLowerCase() == 'morning';
    final isActive = trip.status.toLowerCase() == 'active';
    final isCompletedToday = _isTripCompletedToday(trip);

    // Muted, trustworthy UI states
    final String statusLabel;
    final Color statusColor;
    
    if (isActive) {
      statusLabel = 'In Progress';
      statusColor = AppTheme.warningOrange;
    } else if (isCompletedToday) {
      statusLabel = 'Completed';
      statusColor = AppTheme.successGreen;
    } else {
      statusLabel = 'Ready to Start';
      statusColor = AppTheme.textMuted;
    }

    final Color cardBg;
    final Border cardBorder;
    final List<BoxShadow> cardShadow;
    final TextStyle? titleStyle;
    final Widget actionIcon;

    if (isActive) {
      cardBg = const Color(0xFFFFFBEB);
      cardBorder = Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4), width: 1.5);
      cardShadow = [
        BoxShadow(
          color: AppTheme.primaryGold.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
      titleStyle = theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w900,
        color: AppTheme.textPrimary,
        letterSpacing: -0.2,
      );
      actionIcon = const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.primaryGoldDark,
        size: 24,
      );
    } else if (isCompletedToday) {
      cardBg = AppTheme.surfaceCard.withValues(alpha: 0.6);
      cardBorder = Border.all(color: AppTheme.border.withValues(alpha: 0.5), width: 1.0);
      cardShadow = [];
      titleStyle = theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppTheme.textMuted,
        decoration: TextDecoration.lineThrough,
        letterSpacing: -0.2,
      );
      actionIcon = const Icon(
        Icons.check_circle_rounded,
        color: AppTheme.successGreen,
        size: 24,
      );
    } else {
      cardBg = AppTheme.surfaceCard;
      cardBorder = Border.all(color: AppTheme.border, width: 1.2);
      cardShadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
      titleStyle = theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
        letterSpacing: -0.2,
      );
      actionIcon = const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textMuted,
        size: 24,
      );
    }

    return _TappableCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TripDetailScreen(tripId: trip.tripId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: cardBorder,
          boxShadow: cardShadow,
        ),
        child: Row(
          children: [
            // Left indicator block
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompletedToday
                    ? AppTheme.border.withValues(alpha: 0.4)
                    : (isMorning
                        ? AppTheme.primaryGold.withValues(alpha: 0.1)
                        : AppTheme.textSecondary.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isCompletedToday
                    ? Icons.check_rounded
                    : (isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded),
                color: isCompletedToday
                    ? AppTheme.textMuted
                    : (isMorning ? AppTheme.primaryGoldDark : AppTheme.textSecondary),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Core information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.tripName,
                    style: titleStyle,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCompletedToday ? AppTheme.textMuted : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action indicator
            actionIcon,
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.route_outlined, color: AppTheme.textMuted, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'No trips assigned',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Check back later, contact transport dispatch, or create a new trip using the + button below.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ).animate().fade().scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutCubic),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 40),
          ),
          const SizedBox(height: 24),
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
            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A wrapper widget that provides tactile scale-down feedback on tap.
class _TappableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TappableCard({required this.child, required this.onTap});

  @override
  State<_TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<_TappableCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}