import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:safe_pick/features/students/presentation/parent_live_tracking_screen.dart';
import '../../auth/domain/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/student_model.dart';
import 'parent_profile_screen.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../trips/domain/trip_service.dart';
import '../../../core/widgets/safe_pick_dialog.dart';

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
      body: Stack(
        children: [
          // ── Elegant Artistic Ambient Background ──
          _buildAmbientBackground(),

          SafeArea(
            bottom: true,
            child: studentsAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return _buildEmptyState(context, ref, theme);
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
                    // ── Unified header: logo row + student identity ──
                    _buildUnifiedHeader(context, ref, theme, students, selectedStudent),

                    // ── Fixed card layout ──
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: Column(
                            key: ValueKey<String>(selectedStudent.studentId),
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildProfileCard(context, theme, selectedStudent),
                                    const SizedBox(height: 16),
                                    _buildSquareStatusAndEtaCards(theme, selectedStudent),
                                    const SizedBox(height: 16),
                                    _buildMapCard(context, theme, selectedStudent),
                                  ],
                                ),
                              ),
                              _buildFooter(theme),
                            ],
                          ),
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
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => SafePickDialog(
        title: 'Sign Out',
        description: 'Are you sure you want to sign out?',
        primaryActionLabel: 'Sign Out',
        onPrimaryAction: () => Navigator.of(context).pop(true),
        secondaryActionLabel: 'Cancel',
        onSecondaryAction: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An error occurred. Please check your connection and try again.'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Artistic Ambient Background (Glassmorphism effect)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAmbientBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGold.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent.withValues(alpha: 0.03),
            ),
          ),
        ),
        // Heavy blur to create the frosted ambient aurora effect
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          bottom: BorderSide(color: AppTheme.border, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                height: 58, // Scaled up for better visibility
              ).animate().fade().scale(delay: 80.ms, curve: Curves.easeOutBack),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ParentProfileScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.border.withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.surfaceCard,
                        child: const Icon(Icons.person_outline_rounded,
                            color: AppTheme.textPrimary, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _handleSignOut(context, ref),
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceCard,
                        border: Border.all(
                            color: AppTheme.border.withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: AppTheme.textPrimary, size: 20),
                    ),
                  ),
                ],
              ).animate().fade(delay: 160.ms),
            ],
          ),

          const SizedBox(height: 24),

          // ── Student identity ──
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
    Widget identityContent;

    if (students.length == 1) {
      identityContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tracking',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selected.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppTheme.textPrimary,
              height: 1.1,
            ),
          ),
        ],
      );
    } else {
      // Multiple students — elegant large dropdown
      identityContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tracking',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          // FIX: Removed SizedBox(height: 32) and isDense: true to prevent text clipping
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected.studentId,
              icon: const Padding(
                padding: EdgeInsets.only(left: 8.0, top: 4.0),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary, size: 28),
              ),
              dropdownColor: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(24),
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
                          letterSpacing: -0.5,
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
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
          ),
          child: const Icon(Icons.child_care_rounded,
              color: AppTheme.textSecondary, size: 24),
        ),
        const SizedBox(width: 16),
        identityContent,
      ],
    ).animate().fade().slideY(begin: -0.04);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Profile Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildProfileCard(
      BuildContext context, ThemeData theme, StudentModel student) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 56, 
            width: 56,
            decoration: BoxDecoration(
              color: AppTheme.background,
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppTheme.border.withValues(alpha: 0.55)),
            ),
            child: const Icon(Icons.person_rounded,
                color: AppTheme.textMuted, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  student.schoolName.isNotEmpty
                      ? student.schoolName
                      : 'No School Assigned',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      student.grade.isNotEmpty ? student.grade : 'Grade Not Set',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.border.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        'ID: ${student.studentId}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.05, curve: Curves.easeOut);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Status + ETA
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

    Widget etaWidget;
    String fallbackEta = student.estimatedArrival ?? '';
    
    if (student.currentStatus == 'In Van') {
      final inVanSinceRaw = student.inVanSince;
      if (inVanSinceRaw != null) {
        etaWidget = StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 30)), // Tick every 30s to be safe
          builder: (context, _) {
            final now = DateTime.now();
            final isMorning = now.hour < 12; 
            final int count = (student.stats[isMorning ? 'morning_trip_count' : 'afternoon_trip_count'] as num?)?.toInt() ?? 0;
            final num avgDurationMs = (student.stats[isMorning ? 'morning_avg_duration_ms' : 'afternoon_avg_duration_ms'] as num?) ?? 0;

            String dynamicEta;
            if (count >= 10 && avgDurationMs > 0) {
              final timeInVanMs = now.difference(inVanSinceRaw).inMilliseconds;
              final remainingMs = avgDurationMs - timeInVanMs;
              if (remainingMs <= 0) {
                dynamicEta = 'Almost here';
              } else {
                final remainingMins = (remainingMs / 60000).ceil();
                dynamicEta = '~$remainingMins mins';
              }
            } else {
              dynamicEta = 'Available after 10 trips';
            }
            return Text(
              dynamicEta,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            );
          },
        );
      } else {
        fallbackEta = 'Calculating...';
        etaWidget = Text(
          fallbackEta,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        );
      }
    } else {
      if (fallbackEta.isEmpty) {
        switch (student.currentStatus) {
          case 'At Home':
            fallbackEta = 'Arrived';
            break;
          case 'Absent':
            fallbackEta = 'N/A';
            break;
          case 'At School':
          default:
            fallbackEta = 'Standby';
            break;
        }
      }
      etaWidget = Text(
        fallbackEta,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          letterSpacing: -0.5,
        ),
      );
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
        const SizedBox(width: 16),
        Expanded(
          child: _InfoTileDynamic(
            icon: Icons.schedule_rounded,
            iconColor: AppTheme.textSecondary,
            label: 'Est. Arrival',
            valueWidget: etaWidget,
          ),
        ),
      ],
    ).animate().fade(delay: 200.ms).slideY(begin: 0.05, curve: Curves.easeOut);
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
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(24),
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
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.2)),
        ),
        // FIX: Replaced solid padding with a ClipRRect and Stack to show map background
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Abstract Map Pattern Background
              Positioned.fill(
                child: Opacity(
                  opacity: 0.25, // Subtle map fade
                  child: CustomPaint(
                    painter: _MapGridPainter(),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.location_on_rounded,
                                color: AppTheme.primaryGold, size: 28)
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.15, 1.15),
                            duration: 1.5.seconds,
                            curve: Curves.easeInOut),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Tracking',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to view van location on map',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          color: AppTheme.primaryGold, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fade(delay: 300.ms).slideY(begin: 0.05, curve: Curves.easeOut),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty state
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.child_care_rounded,
                  color: AppTheme.textMuted, size: 64),
            ),
            const SizedBox(height: 32),
            Text('No students linked',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Text(
              'Add a student to your account in the Profile screen to start monitoring their rides securely.',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: AppTheme.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ParentProfileScreen()),
                ),
                icon: const Icon(Icons.person_rounded, size: 20),
                label: const Text('Go to Profile to Add Child'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: AppTheme.background,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleSignOut(context, ref),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ).animate().fade(duration: 600.ms).scale(
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppTheme.errorRed, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load dashboard',
              style: theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.errorRed, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: theme.textTheme.bodyLarge
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60), 
          const ShimmerLoading(width: 120, height: 14),
          const SizedBox(height: 12),
          const ShimmerLoading(width: 200, height: 36),
          const SizedBox(height: 32),
          const ShimmerCard(height: 96),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: ShimmerCard(height: 140)),
              SizedBox(width: 16),
              Expanded(child: ShimmerCard(height: 140)),
            ],
          ),
          const SizedBox(height: 16),
          const ShimmerCard(height: 104),
        ],
      ),
    );
  }


  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppTheme.surfaceCard.withValues(alpha: 0.75), 
      borderRadius: BorderRadius.circular(24), 
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(color: AppTheme.border, width: 1.2), 
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '© 2026 SafePick Inc. • Parent Portal',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.verified_user_rounded,
              size: 14,
              color: AppTheme.primaryGold,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          width: double.infinity,
          child: CustomPaint(
            painter: _DashboardCartoonPainter(),
          ),
        ),
      ],
    );
  }
}

class _DashboardCartoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double groundY = h - 35; 
    final double scale = w / 400.0;

    // 1. Sky Gradient
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFF0F9FF), Color(0x99BAE6FD)],
      ).createShader(Rect.fromLTWH(0, 0, w, groundY));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, groundY), skyPaint);

    // 2. Cloud and Sun
    canvas.drawCircle(Offset(w * 0.85, 30), 10 * scale, Paint()..color = const Color(0xE6FDE047));
    canvas.drawCircle(Offset(w * 0.85, 30), 6 * scale, Paint()..color = const Color(0xFFFACC15));
    _drawCloud(canvas, w * 0.25, 25, scale, Paint()..color = const Color(0x99E0F2FE));
    _drawCloud(canvas, w * 0.65, 35, scale, Paint()..color = const Color(0x99E0F2FE));

    // 3. Road
    final Paint roadPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF475569), Color(0xFF334155)],
      ).createShader(Rect.fromLTWH(0, groundY, w, h - groundY));
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), roadPaint);
    canvas.drawRect(Rect.fromLTWH(0, groundY - 2, w, 2), Paint()..color = const Color(0xFF1E293B).withValues(alpha: 0.4));

    final Paint dashPaint = Paint()..color = const Color(0xCCFACC15)..strokeWidth = 2 * scale..strokeCap = StrokeCap.round;
    for (double i = 10; i < w; i += (45 * scale)) {
      canvas.drawLine(Offset(i, groundY + (h - groundY) * 0.35), Offset(i + (20 * scale), groundY + (h - groundY) * 0.35), dashPaint);
    }

    // 4. Draw Entities
    _drawEntity(canvas, w * 0.05, groundY, scale, _drawSchool);
    _drawEntity(canvas, w * 0.28, groundY, scale, (c) => _drawTree(c, 1.0));
    _drawEntity(canvas, w * 0.38, groundY, scale, _drawKid);
    _drawEntity(canvas, w * 0.48, groundY, scale, _drawBus);
    _drawEntity(canvas, w * 0.82, groundY, scale, _drawHouse);
    _drawEntity(canvas, w * 0.94, groundY, scale, _drawParent);
  }

  void _drawEntity(Canvas canvas, double x, double y, double scale, Function(Canvas) drawFn) {
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale, scale);
    drawFn(canvas);
    canvas.restore();
  }

  void _drawCloud(Canvas canvas, double cx, double cy, double scale, Paint paint) {
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 34 * scale, height: 14 * scale), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 12 * scale, cy - 3 * scale), width: 26 * scale, height: 14 * scale), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 12 * scale, cy - 2 * scale), width: 22 * scale, height: 12 * scale), paint);
  }

  void _drawSchool(Canvas canvas) {
    final bld = Paint()..color = const Color(0xFFE0F2FE);
    final roof = Paint()..color = const Color(0xFF7DD3FC);
    final winDark = Paint()..color = const Color(0xFFBAE6FD);
    final winLight = Paint()..color = const Color(0xCCFDE047);

    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, -40, 62, 40), const Radius.circular(2)), bld);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, -45, 72, 8), const Radius.circular(2)), roof);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(23, -20, 12, 20), const Radius.circular(2)), roof);
    canvas.drawCircle(const Offset(33, -10), 1.5, Paint()..color = const Color(0xFF0EA5E9));
    
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(11, -33, 9, 9), const Radius.circular(1)), winDark);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, -33, 9, 9), const Radius.circular(1)), winDark);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(37, -33, 9, 9), const Radius.circular(1)), winLight);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(50, -33, 9, 9), const Radius.circular(1)), winDark);
  }

  void _drawTree(Canvas canvas, double sizeMult) {
    final trunk = Paint()..color = const Color(0xFF92400E);
    final leavesMain = Paint()..color = const Color(0xFF4ADE80);
    final leavesAccent = Paint()..color = const Color(0xFF22C55E);

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, -16 * sizeMult, 4, 16 * sizeMult), const Radius.circular(1)), trunk);
    canvas.drawOval(Rect.fromLTWH(-7, -40 * sizeMult, 18, 26 * sizeMult), leavesMain);
    canvas.drawOval(Rect.fromLTWH(-4.5, -45 * sizeMult, 13, 18 * sizeMult), leavesAccent);
  }

  void _drawKid(Canvas canvas) {
    final skin = Paint()..color = const Color(0xFFFEF08A);
    final shirt = Paint()..color = const Color(0xFF6366F1);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, -10, 4, 10), const Radius.circular(2)), skin);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9, -10, 4, 10), const Radius.circular(2)), skin);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, -22, 10, 12), const Radius.circular(2.5)), shirt);
    canvas.drawCircle(const Offset(8, -28), 6, skin);
  }

  void _drawHouse(Canvas canvas) {
    final bld = Paint()..color = const Color(0xFFE0F2FE);
    final roof = Paint()..color = const Color(0xFF7DD3FC);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, -32, 42, 32), const Radius.circular(2)), bld);
    canvas.drawPath(Path()..moveTo(-2, -32)..lineTo(44, -32)..lineTo(21, -52)..close(), roof);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, -22, 10, 22), const Radius.circular(2)), roof);
  }

  void _drawParent(Canvas canvas) {
    final skin = Paint()..color = const Color(0xFFFEF08A);
    final shirt = Paint()..color = const Color(0xFFF472B6);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, -10, 4, 10), const Radius.circular(2)), skin);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9, -10, 4, 10), const Radius.circular(2)), skin);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, -22, 10, 12), const Radius.circular(2.5)), shirt);
    canvas.drawCircle(const Offset(8, -28), 6, skin);
  }

  void _drawBus(Canvas canvas) {
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, -35, 82, 30), const Radius.circular(4)), Paint()..color = const Color(0xFFFACC15));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(64, -32, 18, 22), const Radius.circular(3)), Paint()..color = const Color(0xFFEAB308));

    final winPaint = Paint()..color = const Color(0xFFBAE6FD);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(66, -30, 13, 14), const Radius.circular(2)), winPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, -32, 10, 8), const Radius.circular(1.5)), winPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(19, -32, 10, 8), const Radius.circular(1.5)), winPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(33, -32, 10, 8), const Radius.circular(1.5)), winPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(47, -32, 10, 8), const Radius.circular(1.5)), winPaint);

    canvas.drawRect(const Rect.fromLTWH(0, -25, 82, 3), Paint()..color = const Color(0x331E293B));
    canvas.drawRect(const Rect.fromLTWH(0, -17, 82, 3), Paint()..color = const Color(0x331E293B));

    final tire = Paint()..color = const Color(0xFF1E293B);
    final rim = Paint()..color = const Color(0xFF64748B);
    canvas.drawCircle(const Offset(18, -3), 8, tire);
    canvas.drawCircle(const Offset(18, -3), 4, rim);
    canvas.drawCircle(const Offset(66, -3), 8, tire);
    canvas.drawCircle(const Offset(66, -3), 4, rim);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Abstract Map Background Painter
// ─────────────────────────────────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = AppTheme.primaryGoldDark.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke;

    final blockPaint = Paint()
      ..color = AppTheme.primaryGold.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Draw dense grid of roads (horizontal)
    for (double y = 0; y < size.height; y += 15) {
      strokePaint.strokeWidth = (y % 60 == 0) ? 1.5 : 0.5; // Arterial vs minor
      if (y % 30 == 0 && y % 60 != 0) continue; // Leave some gaps for larger blocks
      canvas.drawLine(Offset(0, y), Offset(size.width, y), strokePaint);
    }

    // Draw dense grid of roads (vertical)
    for (double x = 0; x < size.width; x += 20) {
      strokePaint.strokeWidth = (x % 80 == 0) ? 1.5 : 0.5; // Arterial vs minor
      if (x % 40 == 0 && x % 80 != 0) continue; // Leave some gaps for larger blocks
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), strokePaint);
    }

    // Draw dense blocks (rectangles)
    for (double x = 10; x < size.width; x += 80) {
      for (double y = 15; y < size.height; y += 60) {
        // Pseudo-random skipping for organic feel
        if ((x + y) % 7 == 0) continue; 
        final rect = Rect.fromLTWH(x, y, 60, 45);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), blockPaint);
      }
    }
    
    // Draw some smaller irregular blocks
    for (double x = 30; x < size.width; x += 100) {
      for (double y = 45; y < size.height; y += 90) {
        if ((x * y) % 3 == 0) continue;
        final rect = Rect.fromLTWH(x, y, 40, 30);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), blockPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    return _InfoTileDynamic(
      icon: icon,
      iconColor: iconColor,
      label: label,
      dotColor: dotColor,
      valueWidget: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _InfoTileDynamic extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget valueWidget;
  final Color? dotColor;

  const _InfoTileDynamic({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.valueWidget,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppTheme.border, width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                valueWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tappable card with scale feedback
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
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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