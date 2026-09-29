import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/progress/presentation/progress_page.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_day_row.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_day_type_section.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_goal_card.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_tdee_section.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_week_section.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weight_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/progress_source_overrides.dart';
import '../../calories/support/fake_calories_repositories.dart';

Future<void> _pumpProgressPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 6000);
  addTearDown(tester.view.reset);
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
              builder: (context, state) => const Scaffold(body: ProgressPage()),
            ),
            GoRoute(
              path: AppRoutes.homeSettingsGoalArchive,
              builder: (context, state) => const Text(_archive),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _archive = 'goal archive';

void main() {
  testWidgets('shows the goal, the week, and the trends', (tester) async {
    await _pumpProgressPage(tester);

    expect(find.byKey(ProgressGoalCard.cardKey), findsOneWidget);
    expect(find.text('Abnehmen auf 78,0 kg'), findsOneWidget);
    expect(find.byKey(ProgressWeekSection.sectionKey), findsOneWidget);
    // The run started on Monday 21 September; today is Thursday.
    expect(find.byType(ProgressDayRow), findsNWidgets(7));
    expect(find.text('WOCHENBUDGET · TAG 4 VON 7'), findsOneWidget);
    expect(find.byKey(ProgressWeightSection.sectionKey), findsOneWidget);
    expect(find.byKey(ProgressTdeeSection.sectionKey), findsOneWidget);
    expect(find.byKey(ProgressDayTypeSection.sectionKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the goal archive from the goal card', (tester) async {
    await _pumpProgressPage(tester);

    await tester.tap(find.byKey(ProgressGoalCard.archiveButtonKey));
    await tester.pumpAndSettle();

    expect(find.text(_archive), findsOneWidget);
  });
}
