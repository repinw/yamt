import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/presentation/controllers/progress_scope_controller.dart';
import 'package:yamt/features/progress/presentation/progress_page.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_day_row.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_day_type_section.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_goal_card.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_goal_details.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_scope_switch.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_state.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_tdee_section.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_week_section.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weight_section.dart';
import 'package:yamt/l10n/app_localizations.dart';
import 'package:yamt/l10n/app_localizations_de.dart';

import '../../../helpers/progress_source_overrides.dart';
import '../../calories/support/fake_calories_repositories.dart';

Future<FakeCalorieLogRepository> _pumpProgressPage(
  WidgetTester tester, {
  CalorieGoalSettings? goals,
}) async {
  tester.view.physicalSize = const Size(1080, 6000);
  addTearDown(tester.view.reset);
  final settings = FakeCalorieSettingsRepository(
    initialSettings: goals ?? progressSettings(),
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
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return calorieLog;
}

void main() {
  testWidgets('shows the goal, the week, and the trends', (tester) async {
    await _pumpProgressPage(tester);

    expect(find.byKey(ProgressGoalCard.cardKey), findsOneWidget);
    expect(find.text('Abnehmen auf 78,0 kg'), findsOneWidget);
    expect(find.byKey(ProgressWeekSection.sectionKey), findsOneWidget);
    // The run started on Monday 21 September; today is Thursday.
    expect(find.byType(ProgressDayRow), findsNWidgets(7));
    expect(find.text('RUN 3 · TAG 4 VON 7'), findsOneWidget);
    expect(find.byKey(ProgressWeightSection.sectionKey), findsOneWidget);
    expect(find.byKey(ProgressTdeeSection.sectionKey), findsOneWidget);
    expect(find.byKey(ProgressDayTypeSection.sectionKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fills the goal bar as far as the weight got', (tester) async {
    await _pumpProgressPage(tester);

    // Start 84 kg, target 78 kg, trend near 82 kg: about a third of the way,
    // so the first quarter is full and the second partly.
    Size fill(int index) =>
        tester.getSize(find.byKey(ProgressGoalCard.shareFillKey(index)));
    final segment = tester.getSize(
      find
          .ancestor(
            of: find.byKey(ProgressGoalCard.shareFillKey(0)),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(fill(0), segment);
    expect(fill(1).height, segment.height);
    expect(fill(1).width, inExclusiveRange(0, segment.width));
    expect(fill(3).width, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides the goal menu chip with one goal', (tester) async {
    await _pumpProgressPage(tester);

    expect(find.byKey(ProgressScopeSwitch.goalMenuKey), findsNothing);
  });

  group('with two goals', () {
    ProgressScope scopeOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(ProgressPage)))
            .read(progressScopeControllerProvider);

    Future<void> pick(WidgetTester tester, int number) async {
      await tester.tap(find.byKey(ProgressScopeSwitch.goalMenuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ProgressScopeSwitch.goalEntryKey(number)));
      await tester.pumpAndSettle();
    }

    testWidgets('the newest entry selects the current goal', (tester) async {
      await _pumpProgressPage(tester, goals: progressTwoGoalSettings());
      await tester.tap(
        find.byKey(ProgressScopeSwitch.chipKey(ProgressScope.all)),
      );
      await tester.pumpAndSettle();

      await pick(tester, 2);

      expect(scopeOf(tester), ProgressScope.goal);
      expect(find.byKey(ProgressWeekSection.sectionKey), findsOneWidget);
      expect(find.byType(ProgressGoalDetails), findsNothing);
    });

    testWidgets('an older entry selects that past goal', (tester) async {
      await _pumpProgressPage(tester, goals: progressTwoGoalSettings());

      await pick(tester, 1);

      expect(scopeOf(tester), const ProgressPastGoalScope(1));
      expect(find.byKey(ProgressGoalCard.cardKey), findsOneWidget);
      expect(find.byType(ProgressGoalDetails), findsOneWidget);
      expect(find.text('Abnehmen auf 80,0 kg'), findsOneWidget);
      expect(
        find.text(
          AppLocalizationsDe().progressDayTypeKickerPastGoal(1).toUpperCase(),
        ),
        findsOneWidget,
      );
      expect(find.byKey(ProgressWeekSection.sectionKey), findsNothing);
      expect(find.byKey(ProgressWeightSection.sectionKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('hides the goal and the week under Gesamt', (tester) async {
    await _pumpProgressPage(tester);

    await tester.tap(
      find.byKey(ProgressScopeSwitch.chipKey(ProgressScope.all)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ProgressGoalCard.cardKey), findsNothing);
    expect(find.byKey(ProgressWeekSection.sectionKey), findsNothing);
    expect(find.byKey(ProgressWeightSection.sectionKey), findsOneWidget);
    expect(find.byKey(ProgressTdeeSection.sectionKey), findsOneWidget);
    expect(find.text('ALLE ZIELE · SCHNITT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the week visible while a new budget loads', (
    tester,
  ) async {
    final calorieLog = await _pumpProgressPage(tester);
    final entry = progressEntries().first;
    // A slow read keeps the intake loading for a few frames.
    calorieLog.onReadEntriesInRange = (start, end) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return [
        for (final entry in calorieLog.entries)
          if (!entry.loggedAt.isBefore(start) && entry.loggedAt.isBefore(end))
            entry,
      ];
    };

    // A new entry moves the daily TDEE, so the budget of the week reloads.
    await calorieLog.saveEntry(
      entry.copyWith(id: 'extra', loggedAt: entry.loggedAt),
    );
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(ProgressSectionLoading), findsNothing);
      expect(find.byKey(ProgressWeekSection.sectionKey), findsOneWidget);
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
