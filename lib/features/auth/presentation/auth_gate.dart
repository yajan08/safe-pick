import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_pick/features/auth/presentation/auth_screen.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../students/presentation/parent_dashboard.dart';
import '../../trips/presentation/driver_dashboard.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../../core/services/push_notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Future provider that fetches the user's profile data from Firestore using their UID.
/// Caches the profile data for the user session.
final userProfileProvider = FutureProvider.family<Map<String, String>, String>((ref, uid) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getUserProfileData(uid);
});

/// A gatekeeper widget that routes the user based on their authentication state.
/// - If not logged in -> routes to [LoginScreen].
/// - If logged in -> fetches user role from Firestore and routes to corresponding dashboard.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      if (next.value != null) {
        ref.read(pushNotificationServiceProvider).initialize();
      }
    });

    final authState = ref.watch(authStateChangesProvider);
    final theme = Theme.of(context);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const AuthScreen();
        }
        
        // User is logged in, now fetch their role from Firestore
        final profileAsync = ref.watch(userProfileProvider(user.uid));

        return profileAsync.when(
          data: (profile) {
            final normalizedRole = profile['role']?.toLowerCase().trim() ?? 'parent';
            final status = profile['status']?.toLowerCase().trim() ?? 'active';

            if (status == 'suspended' || status == 'inactive') {
              return Scaffold(
                backgroundColor: AppTheme.background,
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorRed.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.block_rounded,
                                  color: AppTheme.errorRed,
                                  size: 56,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Account Suspended',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.errorRed,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your account has been suspended.\n\nPlease contact safepickhq@gmail.com or call on +91 8668959041 for support.',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              ref.invalidate(userProfileProvider(user.uid));
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
                          },
                          icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
                          label: const Text('Sign Out', style: TextStyle(color: AppTheme.errorRed)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.errorRed, width: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            
            if (normalizedRole == 'admin') {
              return const AdminDashboardScreen();
            } else if (normalizedRole == 'driver') {
              return const DriverDashboard();
            } else if (normalizedRole == 'parent') {
              return const ParentDashboard();
            }
            
            // Fallback for unknown roles
            return Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.help_outline_rounded,
                                color: theme.colorScheme.primary,
                                size: 56,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Unknown Role: ${profile['role']}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your account role is not recognized by the system.',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            ref.invalidate(userProfileProvider(user.uid));
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
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loading account profile...',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          error: (error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final connectivity = await Connectivity().checkConnectivity();
              final isOffline = connectivity.contains(ConnectivityResult.none);
              
              if (!isOffline) {
                try {
                  ref.invalidate(userProfileProvider(user.uid));
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account profile missing. Please try signing up again.'),
                        backgroundColor: AppTheme.errorRed,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  // Ignore sign-out errors in the fallback
                }
              }
            });

            return Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: AppTheme.textSecondary, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'You are offline.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Please check your connection to sync your profile.', style: TextStyle(color: AppTheme.textMuted)),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(userProfileProvider(user.uid)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: AppTheme.errorRed,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Auth Connection Error',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Could not verify authentication stream. Please check your config parameters.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton(
                    onPressed: () {
                      ref.invalidate(authStateChangesProvider);
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
