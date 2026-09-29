import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/progress/presentation/progress_page.dart';
import 'package:yamt/features/progress/presentation/widgets/'
    'progress_day_type_section.dart';
import 'package:yamt/features/progress/presentation/widgets/'
    'progress_goal_card.dart';
import 'package:yamt/features/progress/presentation/widgets/'
    'progress_tdee_section.dart';
import 'package:yamt/features/progress/presentation/widgets/'
    'progress_weight_section.dart';
import 'package:yamt/features/progress/presentation/widgets/'
    'progress_week_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/helpers/progress_source_overrides.dart';

const _archiveKey = ValueKey<String>('progress-smoke-archive');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the Fortschritt tab shows every section and opens the archive', (
    tester,
  ) async {
    final settings = FakeCalorieSettingsRepository(
      initialSettings: progressSettings(),
    );
    addTearDown(settings.dispose);
    final calorieLog = FakeCalorieLogRepository(
      initialEntries: progressEntries(),
    );
    addTearDown(calorieLog.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: progressSourceOverrides(
          settingsRepository: settings,
          calorieLog: calorieLog,
        ),
        child: MaterialApp.router(
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const Scaffold(body: ProgressPage()),
              ),
              GoRoute(
                path: AppRoutes.homeSettingsGoalArchive,
                builder: (context, state) =>
                    const Scaffold(body: SizedBox(key: _archiveKey)),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ProgressGoalCard.cardKey), findsOneWidget);
    expect(find.byKey(ProgressWeekSection.sectionKey), findsOneWidget);
    for (final key in [
      ProgressWeightSection.sectionKey,
      ProgressTdeeSection.sectionKey,
      ProgressDayTypeSection.sectionKey,
    ]) {
      await tester.scrollUntilVisible(find.byKey(key), 300);
      expect(find.byKey(key), findsOneWidget);
    }

    await tester.scrollUntilVisible(
      find.byKey(ProgressGoalCard.archiveButtonKey),
      -300,
    );
    await tester.tap(find.byKey(ProgressGoalCard.archiveButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(_archiveKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
