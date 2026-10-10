import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/whats_new/presentation/widgets/whats_new_listener.dart';
import 'package:yamt/features/whats_new/presentation/widgets/whats_new_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/memory_app_preferences.dart';

Future<void> _pumpVisibleStep(WidgetTester tester) async {
  await tester.pump();
  await Future<void>.delayed(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('an updated app shows what is new on home, then all notes', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: AppRoutes.welcome,
      routes: [
        for (final path in [AppRoutes.welcome, AppRoutes.home])
          GoRoute(path: path, builder: (_, _) => const Scaffold()),
      ],
    );
    addTearDown(router.dispose);
    // A device where the onboarding was finished: the app was used before.
    final container = ProviderContainer(
      overrides: [
        appVersionProvider.overrideWith((ref) async => '3.7.0+70'),
        appPreferencesProvider.overrideWithValue(
          MemoryAppPreferences(
            completedCalorieGoalOnboardingUserIds: {'user-1'},
          ),
        ),
        navigatorKeyProvider.overrideWithValue(navigatorKey),
        appRouterProvider.overrideWithValue(router),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => WhatsNewListener(child: child!),
        ),
      ),
    );
    await _pumpVisibleStep(tester);

    // Not over sign-in.
    final notice = find.byKey(WhatsNewListener.noticeKey);
    expect(notice, findsNothing);

    router.go(AppRoutes.home);
    await _pumpVisibleStep(tester);

    expect(notice, findsOneWidget);
    await tester.tap(
      find.descendant(of: notice, matching: find.byType(TextButton)),
    );
    await _pumpVisibleStep(tester);

    expect(find.byKey(WhatsNewSheet.listKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
