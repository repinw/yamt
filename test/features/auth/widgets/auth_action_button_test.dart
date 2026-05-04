import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/auth/widgets/auth_action_button.dart';

Widget _wrapWithApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('AuthActionButton', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          AuthActionButton(
            buttonKey: const Key('auth_action_button'),
            label: 'Continue',
            icon: const Icon(Icons.login),
            minimumHeight: 48,
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.login), findsNothing);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('fires callback when pressed', (tester) async {
      var pressedCount = 0;

      await tester.pumpWidget(
        _wrapWithApp(
          AuthActionButton(
            buttonKey: const Key('auth_action_button'),
            label: 'Continue',
            icon: const Icon(Icons.login),
            minimumHeight: 48,
            onPressed: () => pressedCount++,
            isLoading: false,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('auth_action_button')));
      await tester.pumpAndSettle();

      expect(pressedCount, 1);
    });
  });
}
