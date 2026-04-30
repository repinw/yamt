import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_learned_tdee_goal_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../support/fake_calories_repositories.dart';

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  _FakeBurnWeekRunStateRepository(this.state);

  BurnWeekRunState state;
  int saveCallCount = 0;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState nextState) async {
    saveCallCount += 1;
    state = nextState;
    return true;
  }
}

Widget _buildHarness({
  required CalorieGoalSettings initialSettings,
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                unawaited(
                  showCalorieLearnedTdeeGoalSheet(
                    context,
                    initialSettings: initialSettings,
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('keeps existing goal start date when editing learned TDEE goal', (
    tester,
  ) async {
    final goalStartDate = DateTime(2026, 4, 10, 16, 30);
    final countingStartDate = DateTime(2026, 4, 12);
    final initialSettings = CalorieGoalSettings.single(
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
      countingStartDate: countingStartDate,
      source: CalorieGoalSource.calculator,
      weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: DateTime(2026, 4, 8),
        windowEndDate: DateTime(2026, 4, 14),
        trendWeightChangePerDay: -0.08,
        calculatedTrueTdeeKcal: 2450,
        averageActiveKcal: 210,
        lowConfidence: false,
      ),
    );

    await tester.pumpWidget(
      _buildHarness(initialSettings: initialSettings),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final goalStartValue = tester.widget<Text>(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalStartValue),
    );

    expect(
      goalStartValue.data,
      DateFormat.yMMMd('en').format(countingStartDate),
    );
  });

  testWidgets('saving unchanged learned goal does not restart Burn Week', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    final goalStartDate = today.subtract(const Duration(days: 2));
    final learnedSnapshot = CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: goalStartDate.subtract(const Duration(days: 7)),
      windowEndDate: goalStartDate.subtract(const Duration(days: 1)),
      trendWeightChangePerDay: -0.08,
      calculatedTrueTdeeKcal: 2450,
      averageActiveKcal: 210,
      lowConfidence: false,
    );
    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.female,
      weightKg: 65,
      heightCm: 170,
      ageYears: 28,
      activityLevel: 1.7,
      goalMode: CalorieGoalMode.maintain,
      goalSpeedKgPerWeek: 0,
    );
    final initialSettings = CalorieGoalSettings.single(
      dailyKcalGoal: 2450,
      calculatorProfile: profile,
      expectedActivityKcal: learnedSnapshot.averageActiveKcal,
      effectiveDate: goalStartDate,
      countingStartDate: goalStartDate,
      source: CalorieGoalSource.calculator,
      weeklyCheckInSnapshot: learnedSnapshot,
    );
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: initialSettings,
    );
    final logRepository = FakeCalorieLogRepository();
    final initialRunState = BurnWeekRunState(
      currentWeekStartDayKey: diaryDayKey(
        goalStartDate.subtract(const Duration(days: 7)),
      ),
      lastActiveDayKey: diaryDayKey(today),
      runWeekNumber: 3,
      starCount: 2,
      heartCount: 1,
      heartCreditKcal: 375,
      starBrokeThisWeek: true,
      missedTrackingThisWeek: true,
    );
    final runStateRepository = _FakeBurnWeekRunStateRepository(
      initialRunState,
    );
    addTearDown(settingsRepository.dispose);
    addTearDown(logRepository.dispose);

    await tester.pumpWidget(
      _buildHarness(
        initialSettings: initialSettings,
        overrides: <Override>[
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          burnWeekRunStateRepositoryProvider.overrideWithValue(
            runStateRepository,
          ),
        ],
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CalorieLearnedTdeeSheetKeys.saveButton));
    await tester.pumpAndSettle();

    expect(runStateRepository.saveCallCount, 0);
    expect(runStateRepository.state, initialRunState);
    expect(find.byKey(CalorieLearnedTdeeSheetKeys.sheet), findsNothing);
  });
}
