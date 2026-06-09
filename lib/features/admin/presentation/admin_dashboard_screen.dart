import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
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
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        foregroundColor: kAdminNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // IndexedStack keeps tab states alive, preventing full-screen flicker
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.border.withValues(alpha: 0.3), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: kAdminNavy.withValues(alpha: 0.08),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 68,
          // Subtle text styling for the labels
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return theme.textTheme.labelSmall?.copyWith(
              color: isSelected ? kAdminNavy : AppTheme.textMuted,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.2,
            );
          }),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: AppTheme.textMuted),
              selectedIcon: const Icon(Icons.dashboard_rounded, color: kAdminNavy),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded, color: AppTheme.textMuted),
              selectedIcon: const Icon(Icons.people_rounded, color: kAdminNavy),
              label: 'Users',
            ),
            NavigationDestination(
              icon: Icon(Icons.directions_bus_outlined, color: AppTheme.textMuted),
              selectedIcon: const Icon(Icons.directions_bus_rounded, color: kAdminNavy),
              label: 'Trips',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined, color: AppTheme.textMuted),
              selectedIcon: const Icon(Icons.analytics_rounded, color: kAdminNavy),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}