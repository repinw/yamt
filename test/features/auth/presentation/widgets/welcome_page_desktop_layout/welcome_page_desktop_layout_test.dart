import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_card/auth_card.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_footer_prompt/auth_footer_prompt.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_header/auth_header.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_layout_metrics/auth_layout_metrics.dart';
import 'package:yamt/features/auth/presentation/widgets/welcome_page_desktop_layout/welcome_page_desktop_layout.dart';
import 'package:yamt/features/auth/presentation/widgets/welcome_page_editorial_aside/welcome_page_editorial_aside.dart';
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
      home: Scaffold(body: SizedBox(width: 1120, height: 720, child: child)),
    ),
  );
}

void main() {
  group('DesktopAuthLayout', () {
    testWidgets('renders wide auth sections and register switch', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var registerSwitchCalls = 0;

      await tester.pumpWidget(
        _wrapWithApp(
          DesktopAuthLayout(
            isLoginMode: true,
            onShowLoginMode: () {},
            onShowRegisterMode: () => registerSwitchCalls++,
            metrics: _metrics,
          ),
        ),
      );

      expect(find.byType(EditorialAside), findsOneWidget);
      expect(find.byType(AuthHeader), findsOneWidget);
      expect(find.byType(AuthCard), findsOneWidget);
      expect(find.byType(AuthFooterPrompt), findsOneWidget);
      expect(find.text('Yamt'), findsWidgets);
      expect(find.text('Login with Google'), findsOneWidget);

      await tester.tap(find.byKey(const Key('auth_switch_to_register_button')));
      await tester.pumpAndSettle();

      expect(registerSwitchCalls, 1);
    });
  });
}
