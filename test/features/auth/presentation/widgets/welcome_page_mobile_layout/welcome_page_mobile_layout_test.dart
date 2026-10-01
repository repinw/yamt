import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_card/auth_card.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_header/auth_header.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_layout_metrics/auth_layout_metrics.dart';
import 'package:yamt/features/auth/presentation/widgets/login_form/login_form.dart';
import 'package:yamt/features/auth/presentation/widgets/welcome_page_mobile_layout/welcome_page_mobile_layout.dart';
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
      home: Scaffold(body: SizedBox(width: 420, height: 900, child: child)),
    ),
  );
}

void main() {
  group('MobileAuthLayout', () {
    testWidgets('renders the login layout without a register prompt', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrapWithApp(const MobileAuthLayout(metrics: _metrics)),
      );

      expect(find.byType(AuthHeader), findsOneWidget);
      expect(find.byType(AuthCard), findsOneWidget);
      expect(find.byType(LoginForm), findsOneWidget);
      expect(
        find.byKey(const Key('auth_switch_to_register_button')),
        findsNothing,
      );
    });
  });
}
