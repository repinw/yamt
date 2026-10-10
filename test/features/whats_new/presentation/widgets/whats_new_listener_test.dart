import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/whats_new/presentation/widgets/whats_new_listener.dart';
import 'package:yamt/features/whats_new/presentation/widgets/whats_new_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/memory_app_preferences.dart';

const _lastSeenKey = 'whats_new_last_seen_version_v1';

/// Pumps the app on [location] for a device that used the app before.
Future<(GoRouter, MemoryAppPreferences)> _pumpApp(
  WidgetTester tester, {
  required String location,
}) async {
  final preferences = MemoryAppPreferences(
    completedCalorieGoalOnboardingUserIds: {'user-1'},
  );
  final navigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: location,
    routes: [
      for (final path in [AppRoutes.welcome, AppRoutes.home])
        GoRoute(path: path, builder: (_, _) => const Scaffold()),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      appVersionProvider.overrideWith((ref) async => '3.7.0+70'),
      appPreferencesProvider.overrideWithValue(preferences),
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
  // The notes load from the asset bundle, outside the fake clock.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
  return (router, preferences);
}

void main() {
  // A cached asset future of an earlier test never completes in the next.
  tearDown(rootBundle.clear);

  testWidgets('the notice names the first new point and opens all notes', (
    tester,
  ) async {
    final (_, preferences) = await _pumpApp(tester, location: AppRoutes.home);

    expect(find.byKey(WhatsNewListener.noticeKey), findsOneWidget);
    expect(find.textContaining('New in 3.7.0: Recipe page'), findsOneWidget);
    expect(await preferences.getString(_lastSeenKey), '3.7.0');

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(find.byKey(WhatsNewSheet.listKey), findsOneWidget);
    expect(find.text('Improved'), findsOneWidget);
    expect(find.text('Fixed'), findsOneWidget);
  });

  testWidgets('the notice waits until the app is on its home pages', (
    tester,
  ) async {
    final (router, preferences) = await _pumpApp(
      tester,
      location: AppRoutes.welcome,
    );

    expect(find.byKey(WhatsNewListener.noticeKey), findsNothing);
    expect(await preferences.getString(_lastSeenKey), isNull);

    router.go(AppRoutes.home);
    await tester.pumpAndSettle();

    expect(find.byKey(WhatsNewListener.noticeKey), findsOneWidget);
  });
}
