import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import 'tabs/admin_overview_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'tabs/admin_trips_tab.dart';
import 'tabs/admin_reports_tab.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    AdminOverviewTab(),
    AdminUsersTab(),
    AdminTripsTab(),
    AdminReportsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    // Override the primary color specifically for the Admin dashboard to give it a distinct authoritative feel
    final adminTheme = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: const Color(0xFF1A237E), // Deep Navy Blue
        secondary: const Color(0xFF3949AB),
      ),
      appBarTheme: Theme.of(context).appBarTheme.copyWith(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
    );

    return Theme(
      data: adminTheme,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Admin Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign Out',
              onPressed: () async {
                try {
                  await ref.read(authServiceProvider).signOut();
                  // AuthGate will handle the routing via authStateChanges provider.
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppTheme.surface,
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.04),
          indicatorColor: const Color(0xFF1A237E).withOpacity(0.1),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF1A237E)), label: 'Overview'),
            NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded, color: Color(0xFF1A237E)), label: 'Users'),
            NavigationDestination(icon: Icon(Icons.directions_bus_outlined), selectedIcon: Icon(Icons.directions_bus_rounded, color: Color(0xFF1A237E)), label: 'Trips'),
            NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics_rounded, color: Color(0xFF1A237E)), label: 'Reports'),
          ],
        ),
      ),
    );
  }
}
