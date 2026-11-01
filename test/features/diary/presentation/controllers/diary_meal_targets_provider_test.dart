import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_balance_loaded_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_shares_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_targets_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_marker_controller.dart';

import '../../../../helpers/memory_app_preferences.dart';

const _markerKey = 'diary_pace_marker_v1';
const _sharesKey = 'diary_meal_shares_v1';

final _day = DateTime(2026, 4, 27);

DiaryDailyBalanceMetrics _daily(double target) => DiaryDailyBalanceMetrics(
  bufferAdjustmentKcal: 0,
  realEatenKcal: 0,
  eatenKcal: 0,
  realDayLeftKcal: target,
  dayLeftKcal: target,
  targetKcal: target,
);

DiaryBalanceCardData _loaded({double target = 2000, bool isPauseDay = false}) =>
    DiaryBalanceCardData.loaded(
      loadedMetrics: DiaryBalanceLoadedMetrics(
        selectedDay: _day,
        daily: _daily(target),
        state: DiaryBalanceLoadedState(
          isPauseDay: isPauseDay,
          showGameControls: false,
          runWeekNumber: 1,
        ),
        runWeekStart: _day,
      ),
    );

DiaryBalanceNotCountingDayData _notCounting(double target) =>
    DiaryBalanceNotCountingDayData(
      day: _day,
      startDate: DateTime(2026, 4, 29),
      daily: _daily(target),
    );

/// The targets in whole kcal per meal, which is how a heading shows them.
Map<MealType, int>? _rounded(Map<MealType, double>? targets) =>
    targets?.map((meal, kcal) => MapEntry(meal, kcal.round()));

void main() {
  ProviderContainer containerWith({
    DiaryBalanceCardData? card,
    bool markerOn = true,
    String? shares,
  }) {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(
          MemoryAppPreferences(
            initialInts: {if (markerOn) _markerKey: 1},
            initialStrings: {_sharesKey: ?shares},
          ),
        ),
        diaryBalanceCardProvider(_day).overrideWith((ref) => card),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('is null while the pace marker is off', () {
    final container = containerWith(card: _loaded(), markerOn: false);

    expect(container.read(diaryMealTargetsProvider(_day)), isNull);
  });

  test("splits the day's target by the parts of the day while the marker "
      'is on', () {
    final container = containerWith(card: _loaded());

    final targets = container.read(diaryMealTargetsProvider(_day));

    expect(_rounded(targets), {
      MealType.breakfast: 500,
      MealType.lunch: 700,
      MealType.dinner: 600,
      MealType.snack: 200,
    });
    expect(
      targets!.values.fold<double>(0, (sum, kcal) => sum + kcal),
      closeTo(2000, 1e-9),
    );
  });

  test('takes the target of the day, with its carryover', () {
    final container = containerWith(card: _loaded(target: 2218));

    expect(_rounded(container.read(diaryMealTargetsProvider(_day))), {
      MealType.breakfast: 555,
      MealType.lunch: 776,
      MealType.dinner: 665,
      MealType.snack: 222,
    });
  });

  test("is null while the day's card has not loaded", () {
    final container = containerWith();

    expect(container.read(diaryMealTargetsProvider(_day)), isNull);
  });

  test('is null on a pause day, which has no target', () {
    final container = containerWith(card: _loaded(isPauseDay: true));

    expect(container.read(diaryMealTargetsProvider(_day)), isNull);
  });

  test('leaves out a meal set to 0 %', () {
    final container = containerWith(card: _loaded(), shares: '0,60,30,10');

    final targets = container.read(diaryMealTargetsProvider(_day));

    expect(targets, isNot(contains(MealType.breakfast)));
    expect(_rounded(targets), {
      MealType.lunch: 1200,
      MealType.dinner: 600,
      MealType.snack: 200,
    });
  });

  test('splits the target of a practice day and of a day before a restart', () {
    final practice = containerWith(
      card: DiaryBalanceCardData.practiceDay(practiceDay: _notCounting(1200)),
    );
    final restart = containerWith(
      card: DiaryBalanceCardData.scheduledRestart(
        scheduledRestart: _notCounting(1600),
      ),
    );

    expect(_rounded(practice.read(diaryMealTargetsProvider(_day))), {
      MealType.breakfast: 300,
      MealType.lunch: 420,
      MealType.dinner: 360,
      MealType.snack: 120,
    });
    expect(_rounded(restart.read(diaryMealTargetsProvider(_day))), {
      MealType.breakfast: 400,
      MealType.lunch: 560,
      MealType.dinner: 480,
      MealType.snack: 160,
    });
  });

  test('follows the switch and the parts of the day the user sets', () async {
    final container = containerWith(card: _loaded(), markerOn: false);
    final values = <Map<MealType, int>?>[];
    container.listen(
      diaryMealTargetsProvider(_day),
      (_, next) => values.add(_rounded(next)),
      fireImmediately: true,
    );

    await container
        .read(diaryPaceMarkerControllerProvider.notifier)
        .show(visible: true);
    await container.pump();
    await container
        .read(diaryMealSharesControllerProvider.notifier)
        .select(const DiaryMealShares([40, 20, 20, 20]));
    await container.pump();
    await container
        .read(diaryPaceMarkerControllerProvider.notifier)
        .show(visible: false);
    await container.pump();

    expect(values, [
      null,
      {
        MealType.breakfast: 500,
        MealType.lunch: 700,
        MealType.dinner: 600,
        MealType.snack: 200,
      },
      {
        MealType.breakfast: 800,
        MealType.lunch: 400,
        MealType.dinner: 400,
        MealType.snack: 400,
      },
      null,
    ]);
  });
}
