import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/progress/presentation/progress_page.dart';
import 'package:yamt/features/progress/presentation/progress_photo_compare_page.dart';
import 'package:yamt/features/progress/presentation/progress_photos_page.dart';
import 'package:yamt/features/progress/presentation/widgets/'
    'progress_photo_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/helpers/fake_progress_photo_repository.dart';
import '../../test/helpers/progress_photo_harness.dart';
import '../../test/helpers/progress_source_overrides.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Fortschritt opens all photos, deletes one, and compares before and after',
    (tester) async {
      final settings = FakeCalorieSettingsRepository(
        initialSettings: progressSettings(),
      );
      addTearDown(settings.dispose);
      final calorieLog = FakeCalorieLogRepository(
        initialEntries: progressEntries(),
      );
      addTearDown(calorieLog.dispose);
      final photos = FakeProgressPhotoRepository(
        photos: progressPhotoExamples(),
      );
      addTearDown(photos.dispose);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: ProgressPage()),
          ),
          GoRoute(
            path: AppRoutes.homeProgressPhotos,
            builder: (context, state) => const ProgressPhotosPage(),
          ),
          GoRoute(
            path: AppRoutes.homeProgressPhotoCompare,
            builder: (context, state) => ProgressPhotoComparePage(
              poseName: state
                  .uri
                  .queryParameters[AppRoutes.homeProgressPhotoPoseParam],
            ),
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

      await tester.ensureVisible(find.byKey(ProgressPhotoSection.allKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ProgressPhotoSection.allKey));
      await tester.pumpAndSettle();
      expect(find.byKey(ProgressPhotosPage.photoKey('mid')), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(ProgressPhotosPage.photoKey('mid')),
      );
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(ProgressPhotosPage.photoKey('mid')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ProgressPhotosPage.deleteConfirmKey));
      await tester.pumpAndSettle();
      expect(find.byKey(ProgressPhotosPage.photoKey('mid')), findsNothing);
      expect(photos.photos.map((photo) => photo.id), ['old', 'new', 'side']);

      router.pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(ProgressPhotoSection.compareKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ProgressPhotoSection.compareKey));
      await tester.pumpAndSettle();

      final slider = find.byKey(ProgressPhotoComparePage.sliderKey);
      await tester.scrollUntilVisible(slider, 300);
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(slider).value, 0.5);
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(slider).value, greaterThan(0.5));
      expect(tester.takeException(), isNull);
    },
  );
}
