import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'login_screen.dart';

/// A gatekeeper widget that routes the user based on their Firebase Authentication state.
/// - If not authenticated -> routes to [LoginScreen].
/// - If authenticated -> routes to a temporary role checker screen (Phase 3).
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final theme = Theme.of(context);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        return const CheckingRoleScreen();
      },
      loading: () => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading SafePick...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
                    'Auth Initialization Error',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Could not configure connection to Firebase. Please verify you have run "flutterfire configure" or checked your configuration settings.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton(
                    onPressed: () {
                      // Trigger a manual refresh of the provider
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

/// A premium temporary screen showing checking role. 
/// It includes a sign-out button so users aren't locked in during manual testing.
class CheckingRoleScreen extends ConsumerWidget {
  const CheckingRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Loading Animation & Icon
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                          ),
                        ),
                        Icon(
                          Icons.vpn_key_outlined,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Logged In Successfully',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Checking user role and profile status...',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Log out Option
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(authServiceProvider).signOut();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out / Reset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
