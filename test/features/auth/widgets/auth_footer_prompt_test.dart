import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/auth/widgets/auth_footer_prompt.dart';

Widget _wrapWithApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('AuthFooterPrompt', () {
    testWidgets('renders prompt text and fires action', (tester) async {
      var actionCalls = 0;

      await tester.pumpWidget(
        _wrapWithApp(
          AuthFooterPrompt(
            prefixText: 'No account?',
            actionText: 'Register',
            buttonKey: const Key('auth_footer_action'),
            onPressed: () => actionCalls++,
          ),
        ),
      );

      expect(find.text('No account?'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);

      await tester.tap(find.byKey(const Key('auth_footer_action')));
      await tester.pumpAndSettle();

      expect(actionCalls, 1);
    });
  });
}
