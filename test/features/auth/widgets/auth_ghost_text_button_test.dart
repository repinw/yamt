import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/auth/widgets/auth_ghost_text_button.dart';

Widget _wrapWithApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('AuthGhostTextButton', () {
    testWidgets('shows loading indicator instead of text when loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithApp(
          AuthGhostTextButton(
            buttonKey: const Key('auth_ghost_button'),
            label: 'Continue as guest',
            minimumHeight: 48,
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continue as guest'), findsNothing);
    });

    testWidgets('renders text and fires callback when pressed', (
      tester,
    ) async {
      var actionCalls = 0;

      await tester.pumpWidget(
        _wrapWithApp(
          AuthGhostTextButton(
            buttonKey: const Key('auth_ghost_button'),
            label: 'Continue as guest',
            minimumHeight: 48,
            onPressed: () => actionCalls++,
            isLoading: false,
          ),
        ),
      );

      expect(find.text('Continue as guest'), findsOneWidget);

      await tester.tap(find.byKey(const Key('auth_ghost_button')));
      await tester.pumpAndSettle();

      expect(actionCalls, 1);
    });
  });
}
