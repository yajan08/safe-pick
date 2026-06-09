import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:safe_pick/features/students/presentation/parent_live_tracking_screen.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/student_model.dart';
import '../../profile/presentation/parent_profile_screen.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../trips/data/trip_service.dart';

/// Real-time stream provider that fetches all students linked to the logged-in parent.
final parentStudentsProvider = StreamProvider<List<StudentModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final currentUser = ref.watch(firebaseAuthProvider).currentUser;

  if (currentUser == null) {
    return Stream.value(const []);
  }

  return firestore
      .collection('students')
      .where('parent_uid', isEqualTo: currentUser.uid)
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => StudentModel.fromJson(doc.data(), doc.id))
          .toList());
});

/// State provider for the currently selected student ID
class SelectedStudentIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void updateStudent(String? id) => state = id;
}

final selectedStudentIdProvider =
    NotifierProvider<SelectedStudentIdNotifier, String?>(
  SelectedStudentIdNotifier.new,
);

class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final studentsAsync = ref.watch(parentStudentsProvider);
    final selectedId = ref.watch(selectedStudentIdProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      // Use a custom header that merges the app bar + student selector
      // into one tight, unified surface — eliminating the dead zone between them.
      body: SafeArea(
        bottom: false,
        child: studentsAsync.when(
          data: (students) {
            if (students.isEmpty) {
              return _buildEmptyState(context, theme);
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (selectedId == null && students.isNotEmpty) {
                ref
                    .read(selectedStudentIdProvider.notifier)
                    .updateStudent(students.first.studentId);
              }
            });

            final selectedStudent = students.firstWhere(
              (s) => s.studentId == selectedId,
              orElse: () => students.first,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Unified header: logo row + student identity, zero gap ──
                _buildUnifiedHeader(context, ref, theme, students, selectedStudent),

                // ── Fixed card layout — no scroll, no Expanded ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: Column(
                      key: ValueKey<String>(selectedStudent.studentId),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProfileCard(context, theme, selectedStudent),
                        const SizedBox(height: 12),
                        _buildSquareStatusAndEtaCards(theme, selectedStudent),
                        const SizedBox(height: 12),
                        _buildMapCard(context, theme, selectedStudent),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => _buildShimmer(),
          error: (error, stackTrace) => _buildErrorState(theme, error.toString()),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Unified header — collapses the AppBar + student-name gap into one surface
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildUnifiedHeader(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<StudentModel> students,
    StudentModel selected,
  ) {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Logo row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SvgPicture.asset(
                'assets/images/logo.svg',
                height: 32,
              ).animate().fade().scale(delay: 80.ms, curve: Curves.easeOutBack),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ParentProfileScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.border.withValues(alpha: 0.55), width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: AppTheme.surfaceCard,
                    child: const Icon(Icons.person_outline_rounded,
                        color: AppTheme.textPrimary, size: 17),
                  ),
                ),
              ).animate().fade(delay: 160.ms),
            ],
          ),

          // ── Divider — very subtle ──
          const SizedBox(height: 14),
          Container(
            height: 0.5,
            color: AppTheme.border.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 14),

          // ── Student identity — directly below, no gap ──
          _buildStudentIdentity(ref, theme, students, selected),
        ],
      ),
    );
  }

  Widget _buildStudentIdentity(
    WidgetRef ref,
    ThemeData theme,
    List<StudentModel> students,
    StudentModel selected,
  ) {
    if (students.length == 1) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.child_care_rounded,
                color: AppTheme.textSecondary, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tracking',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                selected.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ).animate().fade().slideY(begin: -0.04);
    }

    // Multiple students — compact dropdown
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
          ),
          child: const Icon(Icons.child_care_rounded,
              color: AppTheme.textSecondary, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tracking',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            SizedBox(
              height: 32,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isDense: true,
                  value: selected.studentId,
                  icon: const Padding(
                    padding: EdgeInsets.only(left: 6.0),
                    child: Icon(Icons.expand_more_rounded,
                        color: AppTheme.textSecondary, size: 20),
                  ),
                  dropdownColor: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  items: students.map((StudentModel student) {
                    return DropdownMenuItem<String>(
                      value: student.studentId,
                      child: Text(
                        student.name,
                        style: Theme.of(
                                WidgetsBinding.instance.rootElement! as BuildContext)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      ref
                          .read(selectedStudentIdProvider.notifier)
                          .updateStudent(newValue);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fade().slideY(begin: -0.04);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Profile Card — cleaner, slightly denser
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProfileCard(
      BuildContext context, ThemeData theme, StudentModel student) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppTheme.background,
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppTheme.border.withValues(alpha: 0.55)),
            ),
            child: const Icon(Icons.person_rounded,
                color: AppTheme.textMuted, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        student.schoolName.isNotEmpty
                            ? student.schoolName
                            : 'No School Assigned',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppTheme.border.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        'ID: ${student.studentId}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  student.grade.isNotEmpty ? student.grade : 'Grade Not Set',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 40.ms).slideY(begin: 0.04, curve: Curves.easeOut);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Status + ETA — side-by-side, balanced, tight
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSquareStatusAndEtaCards(ThemeData theme, StudentModel student) {
    Color statusColor;
    IconData statusIcon;

    switch (student.currentStatus) {
      case 'In Van':
        statusColor = AppTheme.warningOrange;
        statusIcon = Icons.directions_bus_rounded;
        break;
      case 'At School':
        statusColor = AppTheme.primaryGoldDark;
        statusIcon = Icons.school_rounded;
        break;
      case 'Absent':
        statusColor = AppTheme.errorRed;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'At Home':
      default:
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.home_rounded;
        break;
    }

    String etaText = student.estimatedArrival ?? '';
    if (etaText.isEmpty) {
      switch (student.currentStatus) {
        case 'In Van':
          etaText = '15 mins';
          break;
        case 'At Home':
          etaText = 'Arrived';
          break;
        case 'Absent':
          etaText = 'N/A';
          break;
        case 'At School':
        default:
          etaText = 'Standby';
          break;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            icon: statusIcon,
            iconColor: statusColor,
            label: 'Current Status',
            value: student.currentStatus,
            dotColor: statusColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoTile(
            icon: Icons.schedule_rounded,
            iconColor: AppTheme.textSecondary,
            label: 'Est. Arrival',
            value: etaText,
          ),
        ),
      ],
    ).animate().fade(delay: 80.ms).slideY(begin: 0.04, curve: Curves.easeOut);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Live Tracking CTA card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMapCard(
      BuildContext context, ThemeData theme, StudentModel student) {
    return _TappableCard(
      onTap: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CircularProgressIndicator(
                  color: AppTheme.primaryGold),
            ),
          ),
        );

        try {
          final tripService =
              ProviderScope.containerOf(context).read(tripServiceProvider);
          final sessionId =
              await tripService.getActiveSessionIdForStudent(student.studentId);

          if (context.mounted) {
            Navigator.of(context).pop();
            if (sessionId != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ParentLiveTrackingScreen(
                    student: student,
                    sessionId: sessionId,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('No active trip in progress for this student.'),
                  backgroundColor: AppTheme.textSecondary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error finding trip: $e'),
                  backgroundColor: AppTheme.errorRed),
            );
          }
        }
      },
      child: Container(
        height: 80,
        decoration: _cardDecoration(),
        child: Row(
          children: [
            // Gold accent strip with pulsing pin
            Container(
              width: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.06),
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(19)),
                border: Border(
                    right: BorderSide(
                        color: AppTheme.border.withValues(alpha: 0.28))),
              ),
              child: Center(
                child: const Icon(Icons.location_on_rounded,
                        color: AppTheme.primaryGold, size: 26)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.12, 1.12),
                        duration: 1.4.seconds,
                        curve: Curves.easeInOut),
              ),
            ),
            // Label
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Tracking',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to view van location',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 18),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textMuted, size: 14),
            ),
          ],
        ),
      ).animate().fade(delay: 120.ms).slideY(begin: 0.04, curve: Curves.easeOut),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty state
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.child_care_rounded,
                  color: AppTheme.textMuted, size: 48),
            ),
            const SizedBox(height: 24),
            Text('No students linked',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              'Add a student to your account in the Profile screen to start monitoring their rides securely.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ParentProfileScreen()),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: const Text('Go to Profile'),
            ),
          ],
        ).animate().fade(duration: 400.ms).scale(
            begin: const Offset(0.95, 0.95), curve: Curves.easeOutCubic),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Error state
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppTheme.errorRed, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load dashboard',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.errorRed, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Loading shimmer
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(width: 100, height: 12),
          const SizedBox(height: 6),
          const ShimmerLoading(width: 160, height: 28),
          const SizedBox(height: 20),
          const ShimmerCard(height: 72),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: ShimmerCard(height: 110)),
              SizedBox(width: 12),
              Expanded(child: ShimmerCard(height: 110)),
            ],
          ),
          const SizedBox(height: 12),
          const ShimmerCard(height: 80),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.025),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: AppTheme.border.withValues(alpha: 0.45)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable info tile for Status + ETA cards
// ─────────────────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? dotColor;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tappable card with scale feedback — unchanged
// ─────────────────────────────────────────────────────────────────────────────
class _TappableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TappableCard({required this.child, required this.onTap});

  @override
  State<_TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<_TappableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
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
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: widget.child,
      ),
    );
  }
}