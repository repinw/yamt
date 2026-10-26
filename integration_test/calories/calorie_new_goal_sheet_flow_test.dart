import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_new_goal_flow.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';

const _openButtonKey = ValueKey<String>('open-new-goal-sheet');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a new goal is set with the target slider and the pace wheel', (
    tester,
  ) async {
    final harness = await _pumpHarness(tester);
    await _openSheet(tester);

    await tester.tapAt(
      tester.getCenter(find.byType(Slider)) -
          Offset(tester.getSize(find.byType(Slider)).width / 4, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.paceRow));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(CalorieLearnedTdeeSheetKeys.paceWheel),
      const Offset(0, -(34 + kDragSlopDefault)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.saveButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CalorieGoalStartFoodTrackingDialogKeys.noButton),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
    expect(harness.results, [true]);
    final profile = (await harness.settings.readSettings())
        .sortedGoalHistory
        .last
        .calculatorProfile!;
    expect(profile.goalMode, CalorieGoalMode.lose);
    expect(profile.goalSpeedKgPerWeek, closeTo(0.55, 0.001));
  });

  testWidgets('cancel and a swipe down close the sheet without a goal', (
    tester,
  ) async {
    final harness = await _pumpHarness(tester);

    await _openSheet(tester);
    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.cancelButton));
    await tester.pumpAndSettle();
    await _openSheet(tester);
    await tester.drag(
      find.byKey(CalorieLearnedTdeeSheetKeys.goalValue),
      const Offset(0, 600),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
    expect(harness.results, [false, false]);
    final settings = await harness.settings.readSettings();
    expect(settings.sortedGoalHistory, hasLength(1));
  });
}

final class _Harness {
  new(this.settings);

  final FakeCalorieSettingsRepository settings;
  final results = <bool?>[];
}

Future<_Harness> _pumpHarness(WidgetTester tester) async {
  final settings = FakeCalorieSettingsRepository(
    initialSettings: _learnedSettings(),
  );
  final log = FakeCalorieLogRepository();
  addTearDown(settings.dispose);
  addTearDown(log.dispose);
  final harness = _Harness(settings);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        calorieSettingsRepositoryProvider.overrideWithValue(settings),
        calorieLogRepositoryProvider.overrideWithValue(log),
        burnWeekRunStateRepositoryProvider.overrideWithValue(
          FakeBurnWeekRunStateRepository(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              key: _openButtonKey,
              onPressed: () async => harness.results.add(
                await showCalorieNewGoalSheet(
                  context,
                  currentWeightKg: 64,
                  showBackButton: true,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  return harness;
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(_openButtonKey));
  await tester.pumpAndSettle();
}

CalorieGoalSettings _learnedSettings() {
  final goalStartDate = normalizeLocalDay(DateTime.now())
      .subtract(const Duration(days: 20));
  return CalorieGoalSettings.single(
    dailyKcalGoal: 2450,
    calculatorProfile: const CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.female,
      weightKg: 65,
      heightCm: 170,
      ageYears: 28,
      activityLevel: 1.7,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
    ),
    effectiveDate: goalStartDate,
    countingStartDate: goalStartDate,
    source: CalorieGoalSource.calculator,
    weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: goalStartDate.subtract(const Duration(days: 7)),
      windowEndDate: goalStartDate.subtract(const Duration(days: 1)),
      trendWeightChangePerDay: -0.08,
      calculatedTdeeKcal: 2450,
      lowConfidence: false,
    ),
  );
}
