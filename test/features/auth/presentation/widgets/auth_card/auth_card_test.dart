import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_card/auth_card.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_layout_metrics/auth_layout_metrics.dart';
import 'package:yamt/features/auth/presentation/widgets/login_form/login_form.dart';
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
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('AuthCard', () {
    testWidgets('shows login form, Google login and guest actions', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapWithApp(const AuthCard(metrics: _metrics)));

      expect(find.byType(LoginForm), findsOneWidget);
      expect(find.text('Login with Google'), findsOneWidget);
      expect(find.byKey(const Key('auth_guest_button')), findsOneWidget);
    });
  });
}
