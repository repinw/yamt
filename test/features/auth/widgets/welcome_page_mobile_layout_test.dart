import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/auth/widgets/auth_card.dart';
import 'package:yamt/features/auth/widgets/auth_footer_prompt.dart';
import 'package:yamt/features/auth/widgets/auth_header.dart';
import 'package:yamt/features/auth/widgets/auth_layout_metrics.dart';
import 'package:yamt/features/auth/widgets/login_form.dart';
import 'package:yamt/features/auth/widgets/register_form.dart';
import 'package:yamt/features/auth/widgets/welcome_page_mobile_layout.dart';
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
      home: Scaffold(body: SizedBox(width: 420, height: 900, child: child)),
    ),
  );
}

void main() {
  group('MobileAuthLayout', () {
    testWidgets('renders login layout and register footer prompt', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var registerSwitchCalls = 0;

      await tester.pumpWidget(
        _wrapWithApp(
          MobileAuthLayout(
            isLoginMode: true,
            onShowLoginMode: () {},
            onShowRegisterMode: () => registerSwitchCalls++,
            metrics: _metrics,
          ),
        ),
      );

      expect(find.byType(AuthHeader), findsOneWidget);
      expect(find.byType(AuthCard), findsOneWidget);
      expect(find.byType(AuthFooterPrompt), findsOneWidget);
      expect(find.byType(LoginForm), findsOneWidget);
      expect(find.byType(RegisterForm), findsNothing);
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Register now'), findsOneWidget);

      await tester.tap(find.byKey(const Key('auth_switch_to_register_button')));
      await tester.pumpAndSettle();

      expect(registerSwitchCalls, 1);
    });
  });
}
