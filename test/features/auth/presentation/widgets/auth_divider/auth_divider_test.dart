import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_divider/auth_divider.dart';

Widget _wrapWithApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('AuthDivider', () {
    testWidgets('renders uppercased label', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const AuthDivider(label: 'or')));

      expect(find.text('OR'), findsOneWidget);
    });
  });
}
