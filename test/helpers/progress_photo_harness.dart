import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../features/calories/support/fake_calories_repositories.dart';
import 'fake_progress_photo_repository.dart';
import 'progress_source_overrides.dart';

/// Photos of the Fortschritt examples: one before the goal (7 September), two
/// front photos and one side photo during it.
List<ProgressPhoto> progressPhotoExamples() => [
  ProgressPhoto(
    id: 'old',
    day: DateTime(2026, 9),
    pose: ProgressPhotoPose.front,
    weightKg: 86,
  ),
  ProgressPhoto(
    id: 'mid',
    day: DateTime(2026, 9, 10),
    pose: ProgressPhotoPose.front,
  ),
  ProgressPhoto(
    id: 'new',
    day: DateTime(2026, 9, 20),
    pose: ProgressPhotoPose.front,
    weightKg: 82,
  ),
  ProgressPhoto(
    id: 'side',
    day: DateTime(2026, 9, 20),
    pose: ProgressPhotoPose.side,
  ),
];

/// Pumps [home] at `/` with the Fortschritt sources and [photos]; every path
/// in [stubRoutes] shows a [Text] with that path.
Future<GoRouter> pumpProgressPhotoHarness(
  WidgetTester tester, {
  required Widget home,
  required FakeProgressPhotoRepository photos,
  List<String> stubRoutes = const [],
  List<GoRoute> routes = const [],
}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  addTearDown(tester.view.reset);
  final settings = FakeCalorieSettingsRepository(
    initialSettings: progressSettings(),
  );
  addTearDown(settings.dispose);
  final calorieLog = FakeCalorieLogRepository(
    initialEntries: progressEntries(),
  );
  addTearDown(calorieLog.dispose);
  addTearDown(photos.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: home),
      ),
      ...routes,
      for (final path in stubRoutes)
        GoRoute(
          path: path,
          builder: (context, state) =>
              Text(state.uri.toString(), textDirection: TextDirection.ltr),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: progressSourceOverrides(
        settingsRepository: settings,
        calorieLog: calorieLog,
        photos: photos,
      ),
      child: MaterialApp.router(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
