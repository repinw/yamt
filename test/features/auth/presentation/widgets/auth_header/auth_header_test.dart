import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_header/auth_header.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_layout_metrics/auth_layout_metrics.dart';
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
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('AuthHeader', () {
    testWidgets('renders centered login copy on narrow layout', (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          const AuthHeader(
            isLoginMode: true,
            isWide: false,
            metrics: _metrics,
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Yamt'));

      expect(find.byKey(const Key('auth_header_badge')), findsOneWidget);
      expect(find.text('Yet Another Meal Tracker'), findsOneWidget);
      expect(title.textAlign, TextAlign.center);
    });

    testWidgets('renders register copy without badge on wide layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithApp(
          const AuthHeader(
            isLoginMode: false,
            isWide: true,
            metrics: _metrics,
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('Register'));

      expect(find.byKey(const Key('auth_header_badge')), findsNothing);
      expect(find.text('Create your account and get started.'), findsOneWidget);
      expect(title.textAlign, TextAlign.start);
    });
  });
}
