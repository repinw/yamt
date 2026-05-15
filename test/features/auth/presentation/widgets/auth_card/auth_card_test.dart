import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_card/auth_card.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_layout_metrics/auth_layout_metrics.dart';
import 'package:yamt/features/auth/presentation/widgets/login_form/login_form.dart';
import 'package:yamt/features/auth/presentation/widgets/register_form/register_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _metrics = AuthLayoutMetrics(
  heroBadgeSize: 88,
  heroIconSize: 36,
  cardPadding: EdgeInsets.all(16),
  headerSpacing: 20,
  sectionSpacing: 20,
  footerSpacing: 16,
  socialButtonHeight: 56,
  centerContent: true,
);

Widget _wrapWithApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('AuthCard', () {
    testWidgets('shows login form and login actions in login mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithApp(
          AuthCard(
            isLoginMode: true,
            onShowLoginMode: () {},
            onShowRegisterMode: () {},
            metrics: _metrics,
          ),
        ),
      );

      expect(find.byType(LoginForm), findsOneWidget);
      expect(find.byType(RegisterForm), findsNothing);
      expect(find.text('Login with Google'), findsOneWidget);
      expect(find.byKey(const Key('auth_guest_button')), findsOneWidget);
      expect(
        find.byKey(const Key('auth_switch_to_login_button')),
        findsNothing,
      );
    });

    testWidgets('shows register form and fires login switch callback', (
      tester,
    ) async {
      var loginSwitchCalls = 0;

      await tester.pumpWidget(
        _wrapWithApp(
          AuthCard(
            isLoginMode: false,
            onShowLoginMode: () => loginSwitchCalls++,
            onShowRegisterMode: () {},
            metrics: _metrics,
          ),
        ),
      );

      expect(find.byType(RegisterForm), findsOneWidget);
      expect(find.byType(LoginForm), findsNothing);
      expect(find.text('Register with Google'), findsOneWidget);
      expect(find.byKey(const Key('auth_guest_button')), findsNothing);

      await tester.tap(find.byKey(const Key('auth_switch_to_login_button')));
      await tester.pumpAndSettle();

      expect(loginSwitchCalls, 1);
    });
  });
}
