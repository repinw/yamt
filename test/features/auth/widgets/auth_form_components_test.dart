import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shared/widgets/auth_form_components.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _testHarness(Widget child, {Locale? locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('email validator rejects invalid email', (tester) async {
    await tester.pumpWidget(_testHarness(const SizedBox(key: Key('root'))));
    final context = tester.element(find.byKey(const Key('root')));

    final validator = buildEmailValidator(context);

    expect(validator('invalid'), isNotNull);
    expect(validator('valid@example.com'), isNull);
  });

  testWidgets('password validator checks min length', (tester) async {
    await tester.pumpWidget(_testHarness(const SizedBox(key: Key('root'))));
    final context = tester.element(find.byKey(const Key('root')));

    final validator = buildPasswordValidator(context, minLength: 6);

    expect(validator('12345'), isNotNull);
    expect(validator('123456'), isNull);
  });

  testWidgets('confirm password validator checks match', (tester) async {
    await tester.pumpWidget(_testHarness(const SizedBox(key: Key('root'))));
    final context = tester.element(find.byKey(const Key('root')));
    final passwordController = TextEditingController(text: 'secret123');
    addTearDown(passwordController.dispose);

    final validator = buildConfirmPasswordValidator(
      passwordController,
      context,
      mismatchMessage: 'no match',
    );

    expect(validator('secret12'), 'no match');
    expect(validator('secret123'), isNull);
  });

  testWidgets('validator locale resolution handles region locale fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHarness(
        const SizedBox(key: Key('root')),
        locale: const Locale('de', 'AT'),
      ),
    );
    final context = tester.element(find.byKey(const Key('root')));

    final validator = buildEmailValidator(context);

    expect(validator('not-an-email'), isNotNull);
  });

  testWidgets('validator locale resolution falls back to english', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHarness(
        const SizedBox(key: Key('root')),
        locale: const Locale('zz'),
      ),
    );
    final context = tester.element(find.byKey(const Key('root')));

    final validator = buildEmailValidator(context);

    expect(validator('not-an-email'), isNotNull);
    expect(validator('valid@example.com'), isNull);
  });
}
