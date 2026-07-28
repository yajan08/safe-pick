import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/safe_pick_dialog.dart';
import 'tabs/admin_overview_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'tabs/admin_trips_tab.dart';
import 'tabs/admin_reports_tab.dart';

/// Admin accent color — a deep, authoritative navy to visually separate from
/// the consumer Gold theme while staying inside the "Calm" design language.
const Color kAdminNavy = Color(0xFF1A237E);
const Color kAdminNavyLight = Color(0xFF3949AB);

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    AdminOverviewTab(),
    AdminUsersTab(),
    AdminTripsTab(),
    AdminReportsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: kAdminNavy,
          secondary: kAdminNavy,
        ),
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kAdminNavy, width: 1.5),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          foregroundColor: kAdminNavy,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          shape: const Border(
            bottom: BorderSide(color: AppTheme.border, width: 1.0),
          ),
          title: const Text(
            'Admin Console',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.5,
              color: kAdminNavy,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: kAdminNavy, size: 22),
              tooltip: 'Sign Out',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => SafePickDialog(
                    title: 'Sign Out',
                    description:
                        'Are you sure you want to sign out of the Admin Console?',
                    primaryActionLabel: 'Sign Out',
                    primaryActionColor: AppTheme.errorRed,
                    onPrimaryAction: () => Navigator.pop(context, true),
                    secondaryActionLabel: 'Cancel',
                    onSecondaryAction: () => Navigator.pop(context, false),
                  ),
                );

                if (confirm == true) {
                  // ignore: use_build_context_synchronously
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref.read(authServiceProvider).signOut();
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppTheme.errorRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        // IndexedStack keeps tab states alive, preventing full-screen flicker
        body: SafeArea(
          child: IndexedStack(index: _currentIndex, children: _tabs),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.border, width: 1.0),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: AppTheme.surface,
            indicatorColor: kAdminNavy.withValues(alpha: 0.08),
            height: 72,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined, color: AppTheme.textMuted),
                selectedIcon: const Icon(
                  Icons.dashboard_rounded,
                  color: kAdminNavy,
                ),
                label: 'Overview',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.people_outline_rounded,
                  color: AppTheme.textMuted,
                ),
                selectedIcon: const Icon(Icons.people_rounded, color: kAdminNavy),
                label: 'Users',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.directions_bus_outlined,
                  color: AppTheme.textMuted,
                ),
                selectedIcon: const Icon(
                  Icons.directions_bus_rounded,
                  color: kAdminNavy,
                ),
                label: 'Trips',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined, color: AppTheme.textMuted),
                selectedIcon: const Icon(
                  Icons.analytics_rounded,
                  color: kAdminNavy,
                ),
                label: 'Reports',
              ),
            ],
          ),
        ),
        floatingActionButton: _currentIndex == 1
            ? FloatingActionButton(
                backgroundColor: kAdminNavy,
                foregroundColor: Colors.white,
                elevation: 4,
                onPressed: () => AdminUsersTab.showRegisterDriverSheet(context),
                child: const Icon(Icons.person_add_rounded),
              )
            : null,
      ),
    );
  }
}
