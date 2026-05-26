import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../data/trip_model.dart';
import '../data/trip_service.dart';
import '../data/trip_manifest_model.dart';
import '../data/daily_session_model.dart';
import 'qr_scanner_screen.dart';
import '../../../core/widgets/shimmer_loading.dart';
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
  bool _isLoading = false;

  Future<void> _handleStartTrip() async {
    setState(() => _isLoading = true);
    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.startDailySession(widget.tripId);
      
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
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePauseTrip(String sessionId) async {
    setState(() => _isLoading = true);
    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.pauseDailySession(sessionId);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResumeTrip(String sessionId) async {
    setState(() => _isLoading = true);
    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.resumeDailySession(sessionId);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEndTrip(String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('End Trip', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure you want to end this trip?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.endDailySession(sessionId, widget.tripId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip ended successfully.'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripDetailsProvider(widget.tripId));
    final manifestAsync = ref.watch(tripManifestProvider(widget.tripId));
    final sessionAsync = ref.watch(activeSessionProvider(widget.tripId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/images/light_logo.jpg',
          height: 32,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: tripAsync.when(
        data: (trip) {
          return sessionAsync.when(
            data: (session) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Status Banner
                          _buildStatusBanner(theme, trip, session),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 20),

                                // 2. Trip Details & Action Buttons
                                _buildTripDetailsCard(theme, trip, session),
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
                              final attendanceMap = session != null
                                  ? ref.watch(sessionAttendanceProvider(session.sessionId)).value ?? {}
                                  : <String, String>{};

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  children: manifest.asMap().entries.map((entry) {
                                    return _buildStudentRow(theme, entry.value, entry.key, session, attendanceMap)
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
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ShimmerList(itemCount: 5, itemHeight: 80),
            ),
            error: (error, _) => _buildErrorState(theme, error.toString()),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ShimmerList(itemCount: 5, itemHeight: 80),
        ),
        error: (error, _) => _buildErrorState(theme, error.toString()),
      ),
      // QR Scan FAB
      floatingActionButton: sessionAsync.when(
        data: (session) {
          if (session?.status != 'in_progress') return null;
          return SizedBox(
            width: 72,
            height: 72,
            child: FloatingActionButton(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QRScannerScreen(sessionId: session!.sessionId),
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
  Widget _buildStatusBanner(ThemeData theme, TripModel trip, DailySessionModel? session) {
    String label;
    Color bgColor;
    IconData icon;

    if (session?.status == 'completed' || trip.status.toLowerCase() == 'completed') {
      label = 'COMPLETED';
      bgColor = AppTheme.successGreen;
      icon = Icons.check_circle_rounded;
    } else if (session?.status == 'in_progress') {
      label = 'IN PROGRESS';
      bgColor = AppTheme.primaryGold;
      icon = Icons.play_circle_rounded;
    } else if (session?.status == 'paused') {
      label = 'PAUSED';
      bgColor = AppTheme.warningOrange;
      icon = Icons.pause_circle_rounded;
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

  // ─── 2. Trip Details & Action Buttons ────────────────────────────
  Widget _buildTripDetailsCard(ThemeData theme, TripModel trip, DailySessionModel? session) {
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
              if (session?.status != 'completed' && trip.status.toLowerCase() != 'completed')
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
          _buildInfoRow(
            theme,
            trip.tripType.toLowerCase() == 'pickup' ? Icons.login_rounded : Icons.logout_rounded,
            'Type',
            trip.tripType.toLowerCase() == 'pickup' ? 'Morning Pick-Up' : 'Afternoon Drop-Off',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            theme,
            Icons.access_time_rounded,
            'Start Time',
            trip.approxStartTime.isNotEmpty ? trip.approxStartTime : 'Not set',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            theme,
            Icons.timer_outlined,
            'Duration',
            trip.estimatedDuration,
          ),
          const SizedBox(height: 24),
          _buildActionButtons(session),
        ],
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.03);
  }

  Widget _buildActionButtons(DailySessionModel? session) {
    if (session == null || session.status == 'not_started') {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleStartTrip,
          icon: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.play_arrow_rounded),
          label: const Text('START TRIP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGold,
            foregroundColor: Colors.white,
          ),
        ),
      );
    } else if (session.status == 'in_progress') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => _handlePauseTrip(session.sessionId),
              icon: const Icon(Icons.pause_rounded),
              label: const Text('PAUSE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGold,
                side: const BorderSide(color: AppTheme.primaryGold, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _handleEndTrip(session.sessionId),
              icon: const Icon(Icons.stop_rounded),
              label: const Text('END TRIP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C), // Deep Red
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );
    } else if (session.status == 'paused') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _handleResumeTrip(session.sessionId),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('RESUME'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _handleEndTrip(session.sessionId),
              icon: const Icon(Icons.stop_rounded),
              label: const Text('END TRIP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C), // Deep Red
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );
    } else {
      // completed
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.successGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'Trip Completed',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.successGreen,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }
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
            CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _MapGridPainter(),
            ),
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

  Future<void> _handleManualOverride(String sessionId, String studentId, String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Text(status == 'onboarded' ? 'Manual Onboard' : 'Mark Absent', style: const TextStyle(color: AppTheme.textPrimary)),
        content: Text('Are you sure you want to mark this student as ${status == 'onboarded' ? 'onboarded' : 'absent'}?', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: status == 'onboarded' ? AppTheme.primaryGold : AppTheme.errorRed, foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await ref.read(tripServiceProvider).manualAttendanceOverride(sessionId, studentId, status);
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  // ─── 6. Student Roster Row ────────────────────────────
  Widget _buildStudentRow(ThemeData theme, TripManifestModel student, int index, DailySessionModel? session, Map<String, String> attendanceMap) {
    final status = attendanceMap[student.studentId] ?? student.status;

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
          _buildStatusChip(theme, status),
          if (session != null && session.status == 'in_progress')
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
              color: AppTheme.surface,
              onSelected: (val) => _handleManualOverride(session.sessionId, student.studentId, val),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'onboarded',
                  child: Text('Manual Onboard', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                ),
                const PopupMenuItem(
                  value: 'absent',
                  child: Text('Mark Absent', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
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
