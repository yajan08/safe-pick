import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_pick/main.dart';
import 'package:safe_pick/core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SafePick App Logged Out routes to LoginScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the auth state changes provider to return null (logged out)
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const SafePickApp(),
      ),
    );

    // Pump the stream values and wait for animations
    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pumpAndSettle();

    // Verify that the login screen elements are rendered.
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });
}
