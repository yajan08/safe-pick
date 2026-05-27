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
      ref.invalidate(tripDetailsProvider(widget.tripId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip session started!'),
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
      ref.invalidate(tripDetailsProvider(widget.tripId));
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

  Future<void> _handleReopenTrip(String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('Reopen Trip', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure you want to reopen this trip? This will set it back to In Progress.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.white),
            child: const Text('Reopen Trip'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.reopenDailySession(sessionId, widget.tripId);
      ref.invalidate(tripDetailsProvider(widget.tripId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip reopened successfully.'),
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

  Future<void> _handleEditTrip(TripModel trip) async {
    final controller = TextEditingController(text: trip.tripName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('Edit Trip Name', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Trip Name',
            hintText: 'e.g. Route A Morning',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == trip.tripName) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(tripServiceProvider).updateTripDetails(trip.tripId, newName);
      ref.invalidate(tripDetailsProvider(widget.tripId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip details updated successfully.'),
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
    final sessionAsync = ref.watch(activeSessionProvider(widget.tripId));

    final session = sessionAsync.asData?.value;
    final isTripActive = session?.status == 'in_progress';

    return PopScope(
      canPop: !isTripActive,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isTripActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must end the active trip before leaving this screen.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(isTripActive ? 'Active Trip' : 'Trip Details'),
          leading: isTripActive
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
          automaticallyImplyLeading: !isTripActive,
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
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 20),

                                  // 1. Trip Details & Action Buttons
                                  _buildTripDetailsCard(theme, trip, session),
                                  const SizedBox(height: 16),

                                  // 2. Map Placeholder
                                  _buildMapPlaceholder(theme),
                                  const SizedBox(height: 24),

                                  // 3. Target Schools Summary
                                  ref.watch(tripManifestProvider(widget.tripId)).when(
                                        data: (manifest) => _buildSchoolsSummary(theme, manifest),
                                        loading: () => const SizedBox.shrink(),
                                        error: (err, stack) => const SizedBox.shrink(),
                                      ),
                                  const SizedBox(height: 24),

                                  // 4. Roster Header
                                  _buildRosterHeader(theme, ref.watch(tripManifestProvider(widget.tripId))),
                                  const SizedBox(height: 16),

                                  // 5. Roster list
                                  ref.watch(tripManifestProvider(widget.tripId)).when(
                                        data: (manifest) {
                                          if (manifest.isEmpty) {
                                            return _buildEmptyRosterCard(theme);
                                          }

                                          final attendanceMap = session != null
                                              ? ref.watch(sessionAttendanceProvider(session.sessionId)).asData?.value ?? const {}
                                              : const <String, String>{};

                                          return Column(
                                            children: manifest.asMap().entries.map((entry) {
                                              return _buildStudentRow(theme, entry.value, entry.key, session, attendanceMap);
                                            }).toList(),
                                          );
                                        },
                                        loading: () => const ShimmerList(itemCount: 3, itemHeight: 80),
                                        error: (err, _) => _buildErrorState(theme, err.toString()),
                                      ),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold))),
              error: (err, _) => _buildErrorState(theme, err.toString()),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold))),
          error: (err, _) => _buildErrorState(theme, err.toString()),
        ),
        floatingActionButton: sessionAsync.when(
          data: (session) {
            if (session != null && session.status == 'in_progress') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: FloatingActionButton(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => QRScannerScreen(sessionId: session.sessionId),
                      ),
                    );
                  },
                  child: const Icon(Icons.qr_code_scanner_rounded, size: 36),
                ),
              );
            }
            return null;
          },
          loading: () => null,
          error: (error, _) => null,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // ─── 1. Trip Details Card ────────────────────────────
  Widget _buildTripDetailsCard(ThemeData theme, TripModel trip, DailySessionModel? session) {
    final showEdit = session == null || session.status != 'completed';

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
              if (showEdit)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryGold),
                    onPressed: () => _handleEditTrip(trip),
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
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _handleEndTrip(session.sessionId),
          icon: const Icon(Icons.stop_rounded),
          label: const Text('END TRIP'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB71C1C), // Deep Red
            foregroundColor: Colors.white,
          ),
        ),
      );
    } else {
      // completed
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _handleReopenTrip(session.sessionId),
          icon: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.refresh_rounded),
          label: const Text('REDO TRIP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGold,
            foregroundColor: Colors.white,
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

  // ─── 2. Map Placeholder ────────────────────────────────
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

  // ─── 3. Target Schools Summary ─────────────────────────
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

  // ─── 4. Roster Header ─────────────────────────────────
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
        title: Text(
          status == 'onboarded'
              ? 'Board Student'
              : status == 'dropped'
                  ? 'Offboard Student'
                  : 'Mark Student Absent',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to mark this student as '
          '${status == 'onboarded' ? 'boarded (in the van)' : status == 'dropped' ? 'offboarded (dropped off)' : 'absent'}?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'onboarded'
                  ? AppTheme.primaryGold
                  : status == 'dropped'
                      ? AppTheme.successGreen
                      : AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
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

  // ─── 5. Student Roster Row ────────────────────────────
  Widget _buildStudentRow(ThemeData theme, TripManifestModel student, int index, DailySessionModel? session, Map<String, String> attendanceMap) {
    final status = attendanceMap[student.studentId] ?? student.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${student.stopOrder}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
              _buildStatusChip(theme, status),
            ],
          ),
          if (session != null && session.status == 'in_progress') ...[
            const SizedBox(height: 12),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 12),
            Center(
              child: _buildStudentActionButtons(context, session.sessionId, student.studentId, status),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentActionButtons(BuildContext context, String sessionId, String studentId, String currentStatus) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Boarded Button
        _buildToggleItem(
          icon: Icons.directions_bus_rounded,
          label: 'Boarded',
          isActive: currentStatus == 'onboarded',
          activeColor: AppTheme.primaryGold,
          onTap: () => _handleManualOverride(sessionId, studentId, 'onboarded'),
        ),
        const SizedBox(width: 8),
        // Offboarded Button
        _buildToggleItem(
          icon: Icons.home_rounded,
          label: 'Offboarded',
          isActive: currentStatus == 'dropped',
          activeColor: AppTheme.successGreen,
          onTap: () => _handleManualOverride(sessionId, studentId, 'dropped'),
        ),
        const SizedBox(width: 8),
        // Absent Button
        _buildToggleItem(
          icon: Icons.cancel_rounded,
          label: 'Absent',
          isActive: currentStatus == 'absent',
          activeColor: AppTheme.errorRed,
          onTap: () => _handleManualOverride(sessionId, studentId, 'absent'),
        ),
      ],
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : AppTheme.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? activeColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? activeColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
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
        label = 'Boarded';
        break;
      case 'dropped':
        chipColor = AppTheme.successGreen.withValues(alpha: 0.15);
        textColor = AppTheme.successGreen;
        label = 'Offboarded';
        break;
      case 'absent':
        chipColor = AppTheme.errorRed.withValues(alpha: 0.15);
        textColor = AppTheme.errorRed;
        label = 'Absent';
        break;
      case 'pending':
      default:
        chipColor = const Color(0xFFE0E0E0);
        textColor = AppTheme.textPrimary;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyRosterCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Text(
          'No students assigned to this trip yet.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
        ),
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
