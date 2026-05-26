import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_pick/main.dart';
import 'package:safe_pick/core/services/auth_service.dart';

void main() {
  testWidgets('SafePick App Logged Out routes to LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the auth state changes provider to return null (logged out)
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const SafePickApp(showOnboarding: false),
      ),
    );

    // Pump the stream values and wait for animations
    await tester.pumpAndSettle();

    // Verify that the login screen elements are rendered.
    expect(find.text('Welcome to SafePick'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });
}
