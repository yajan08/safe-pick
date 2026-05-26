import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_pick/main.dart';

void main() {
  testWidgets('SafePick App Architecture Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SafePickApp(),
      ),
    );

    // Verify that the error gate is rendered since Firebase is not initialized in tests.
    expect(find.text('Auth Initialization Error'), findsOneWidget);
  });
}
