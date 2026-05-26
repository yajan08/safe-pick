import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../data/trip_model.dart';
import '../data/trip_service.dart';
import '../data/trip_manifest_model.dart';
import '../../../core/services/auth_service.dart';

/// Future provider to fetch details of a specific trip.
final tripDetailsProvider = FutureProvider.family<TripModel, String>((ref, tripId) async {
  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore.collection('trips').doc(tripId).get();
  if (!doc.exists) {
    throw 'Trip not found';
  }
  return TripModel.fromJson(doc.data()!, doc.id);
});

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  bool _isStarting = false;
  bool _isSessionStarted = false;

  Future<void> _handleStartTrip() async {
    setState(() {
      _isStarting = true;
    });

    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.startDailySession(widget.tripId);
      
      setState(() {
        _isSessionStarted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip session started! Location tracking active.'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripDetailsProvider(widget.tripId));
    final manifestAsync = ref.watch(tripManifestProvider(widget.tripId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Trip Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: tripAsync.when(
        data: (trip) {
          final isInProgress = trip.status.toLowerCase() == 'active' || _isSessionStarted;
          final isCompleted = trip.status.toLowerCase() == 'completed';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Status Banner
                      _buildStatusBanner(theme, trip, isInProgress, isCompleted),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),

                            // 2. Trip Details Card
                            _buildTripDetailsCard(theme, trip, isInProgress, isCompleted),
                            const SizedBox(height: 16),

                            // 3. Map Placeholder
                            _buildMapPlaceholder(theme),
                            const SizedBox(height: 16),

                            // 4. Target Schools Summary
                            manifestAsync.when(
                              data: (manifest) => _buildSchoolsSummary(theme, manifest),
                              loading: () => const SizedBox.shrink(),
                              error: (error, _) => const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 20),

                            // 5. Roster Header
                            _buildRosterHeader(theme, manifestAsync),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),

                      // 6. Student Roster List
                      manifestAsync.when(
                        data: (manifest) {
                          if (manifest.isEmpty) {
                            return _buildEmptyManifestState(theme);
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: manifest.asMap().entries.map((entry) {
                                return _buildStudentRow(theme, entry.value, entry.key)
                                    .animate()
                                    .fade(delay: Duration(milliseconds: 150 + (entry.key * 60)))
                                    .slideY(begin: 0.03);
                              }).toList(),
                            ),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                            ),
                          ),
                        ),
                        error: (error, _) => _buildErrorState(theme, error.toString()),
                      ),
                      const SizedBox(height: 100), // Space for FAB
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
          ),
        ),
        error: (error, _) => _buildErrorState(theme, error.toString()),
      ),
      // QR Scan FAB
      floatingActionButton: tripAsync.when(
        data: (trip) {
          final isInProgress = trip.status.toLowerCase() == 'active' || _isSessionStarted;
          if (!isInProgress) return null;
          return SizedBox(
            width: 72,
            height: 72,
            child: FloatingActionButton(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Initializing Camera...'),
                    backgroundColor: AppTheme.primaryGold,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Icon(Icons.qr_code_scanner_rounded, size: 36),
            ),
          );
        },
        loading: () => null,
        error: (error, _) => null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ─── 1. Status Banner ──────────────────────────────────
  Widget _buildStatusBanner(ThemeData theme, TripModel trip, bool isInProgress, bool isCompleted) {
    String label;
    Color bgColor;
    IconData icon;

    if (isCompleted) {
      label = 'COMPLETED';
      bgColor = AppTheme.successGreen;
      icon = Icons.check_circle_rounded;
    } else if (isInProgress) {
      label = 'IN PROGRESS';
      bgColor = AppTheme.primaryGold;
      icon = Icons.play_circle_rounded;
    } else {
      label = 'UPCOMING';
      bgColor = const Color(0xFF3A3A3A);
      icon = Icons.schedule_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      color: bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms);
  }

  // ─── 2. Trip Details & Edit ────────────────────────────
  Widget _buildTripDetailsCard(ThemeData theme, TripModel trip, bool isInProgress, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.tripName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Edit Icon (large touch target)
              if (!isCompleted)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryGold),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit Trip Details... (Coming Soon)'),
                          backgroundColor: AppTheme.primaryGold,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),
          // Trip Type
          _buildInfoRow(
            theme,
            trip.tripType.toLowerCase() == 'pickup' ? Icons.login_rounded : Icons.logout_rounded,
            'Type',
            trip.tripType.toLowerCase() == 'pickup' ? 'Morning Pick-Up' : 'Afternoon Drop-Off',
          ),
          const SizedBox(height: 10),
          // Start Time
          _buildInfoRow(
            theme,
            Icons.access_time_rounded,
            'Start Time',
            trip.approxStartTime.isNotEmpty ? trip.approxStartTime : 'Not set',
          ),
          const SizedBox(height: 10),
          // Duration
          _buildInfoRow(
            theme,
            Icons.timer_outlined,
            'Duration',
            trip.estimatedDuration,
          ),
          const SizedBox(height: 16),
          // Start/Status Button
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: (isInProgress || isCompleted || _isStarting)
                  ? null
                  : _handleStartTrip,
              icon: _isStarting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : isInProgress
                              ? Icons.play_circle_rounded
                              : Icons.play_arrow_rounded,
                    ),
              label: Text(
                isCompleted
                    ? 'Trip Completed'
                    : isInProgress
                        ? 'Trip In Progress'
                        : 'Start Trip',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted
                    ? AppTheme.successGreen
                    : isInProgress
                        ? AppTheme.primaryGold.withValues(alpha: 0.7)
                        : AppTheme.primaryGold,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isCompleted ? AppTheme.successGreen.withValues(alpha: 0.7) : AppTheme.primaryGold.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.03);
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGold, size: 20),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ─── 3. Map Placeholder ────────────────────────────────
  Widget _buildMapPlaceholder(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Map View loading... (Coming Soon)'),
            backgroundColor: AppTheme.primaryGold,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Stack(
          children: [
            // Grid pattern overlay
            CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _MapGridPainter(),
            ),
            // Center content
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_rounded, color: AppTheme.primaryGold, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'View Live Map',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(delay: 200.ms).slideY(begin: 0.03);
  }

  // ─── 4. Target Schools Summary ─────────────────────────
  Widget _buildSchoolsSummary(ThemeData theme, List<TripManifestModel> manifest) {
    final schoolNames = manifest
        .map((m) => m.schoolName)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    if (schoolNames.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school_rounded, color: AppTheme.primaryGold, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Destinations',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  schoolNames.join(', '),
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 250.ms).slideY(begin: 0.03);
  }

  // ─── 5. Roster Header ─────────────────────────────────
  Widget _buildRosterHeader(ThemeData theme, AsyncValue<List<TripManifestModel>> manifestAsync) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Student Roster',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: manifestAsync.when(
            data: (manifest) => Text(
              '${manifest.length} Students',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            loading: () => const Text('...'),
            error: (error, _) => const Text('Error'),
          ),
        ),
      ],
    );
  }

  // ─── 6. Student Roster Row ────────────────────────────
  Widget _buildStudentRow(ThemeData theme, TripManifestModel student, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Sr No
          SizedBox(
            width: 32,
            child: Text(
              '${student.stopOrder}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),

          // Name & School
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (student.schoolName.isNotEmpty)
                  Text(
                    student.schoolName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          // Status Chip
          _buildStatusChip(theme, student.status),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, String status) {
    Color chipColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'onboarded':
        chipColor = AppTheme.primaryGold.withValues(alpha: 0.15);
        textColor = AppTheme.primaryGold;
        label = 'Onboarded';
        break;
      case 'dropped':
        chipColor = AppTheme.successGreen.withValues(alpha: 0.15);
        textColor = AppTheme.successGreen;
        label = 'Dropped';
        break;
      case 'absent':
        chipColor = AppTheme.errorRed.withValues(alpha: 0.15);
        textColor = AppTheme.errorRed;
        label = 'Absent';
        break;
      case 'pending':
      default:
        chipColor = AppTheme.border;
        textColor = AppTheme.textMuted;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  // ─── Empty & Error States ─────────────────────────────
  Widget _buildEmptyManifestState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.format_list_bulleted_rounded, color: AppTheme.textMuted, size: 48),
          const SizedBox(height: 16),
          Text(
            'Roster is Empty',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'No students assigned to this trip yet.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading details',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(error, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for a subtle map grid background
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 0.5;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
