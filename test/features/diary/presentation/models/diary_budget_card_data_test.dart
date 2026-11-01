import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/diary/application/diary_balance_provider.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_balance_loaded_metrics.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_balance_metrics.dart';
import 'package:yamt/features/diary/application/diary_open_plans.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';

DiaryBudgetCardData _data({
  DiaryDayStatus status = DiaryDayStatus.today,
  bool isPauseDay = false,
  double dayLeftKcal = 1000,
  ({double protein, double carbs, double fat}) eaten = (
    protein: 50,
    carbs: 100,
    fat: 30,
  ),
  DiaryOpenPlans? openPlans,
}) {
  DiaryBudgetMacro macro(DiaryBudgetMacroKind kind, double grams) =>
      (kind: kind, eaten: grams, planned: 0, target: 100);
  return DiaryBudgetCardData(
    day: DateTime(2026, 4, 27),
    status: status,
    metrics: DiaryDailyBalanceMetrics(
      bufferAdjustmentKcal: 0,
      realEatenKcal: 2000 - dayLeftKcal,
      eatenKcal: 2000 - dayLeftKcal,
      realDayLeftKcal: dayLeftKcal,
      dayLeftKcal: dayLeftKcal,
      targetKcal: 2000,
    ),
    isPauseDay: isPauseDay,
    openPlans: openPlans,
    macros: [
      macro(DiaryBudgetMacroKind.protein, eaten.protein),
      macro(DiaryBudgetMacroKind.carbs, eaten.carbs),
      macro(DiaryBudgetMacroKind.fat, eaten.fat),
    ],
  );
}

void main() {
  group('lowestMacro', () {
    test('is the macro with the lowest share of its target', () {
      expect(_data().lowestMacro, DiaryBudgetMacroKind.fat);
    });

    test('is none on a past day, a pause day, or with equal shares', () {
      expect(_data(status: DiaryDayStatus.past).lowestMacro, isNull);
      expect(_data(isPauseDay: true).lowestMacro, isNull);
      expect(
        _data(eaten: (protein: 40, carbs: 40, fat: 40)).lowestMacro,
        isNull,
      );
    });

    test('is none once every macro reached its target', () {
      expect(
        _data(eaten: (protein: 120, carbs: 100, fat: 110)).lowestMacro,
        isNull,
      );
    });

    test('a future day has one', () {
      expect(
        _data(status: DiaryDayStatus.planned).lowestMacro,
        DiaryBudgetMacroKind.fat,
      );
    });
  });

  group('kcal left', () {
    const plans = DiaryOpenPlans(
      kcal: 300,
      protein: 10,
      carbs: 50,
      fat: 5,
      counted: true,
    );

    test('counted plans come off what is left', () {
      final data = _data(openPlans: plans);

      expect(data.countsPlans, isTrue);
      expect(data.leftKcal, 700);
    });

    test('plans the user does not count leave it as it is', () {
      final data = _data(
        openPlans: const DiaryOpenPlans(
          kcal: 300,
          protein: 10,
          carbs: 50,
          fat: 5,
          counted: false,
        ),
      );

      expect(data.countsPlans, isFalse);
      expect(data.leftKcal, 1000);
    });

    test('is over below zero, but never on a pause day', () {
      expect(_data(dayLeftKcal: -1).isOver, isTrue);
      expect(_data(dayLeftKcal: 200, openPlans: plans).isOver, isTrue);
      expect(_data(dayLeftKcal: -500, isPauseDay: true).isOver, isFalse);
    });
  });

  group('paceKcal', () {
    final day = DateTime(2026, 4, 27);

    DiaryDailyBalanceMetrics daily(double target) => DiaryDailyBalanceMetrics(
      bufferAdjustmentKcal: 0,
      realEatenKcal: 0,
      eatenKcal: 0,
      realDayLeftKcal: target,
      dayLeftKcal: target,
      targetKcal: target,
    );

    DiaryBalanceCardData loaded({
      double target = 2000,
      bool isPauseDay = false,
    }) => DiaryBalanceCardData.loaded(
      loadedMetrics: DiaryBalanceLoadedMetrics(
        selectedDay: day,
        daily: daily(target),
        state: DiaryBalanceLoadedState(
          isPauseDay: isPauseDay,
          showGameControls: false,
          runWeekNumber: 1,
        ),
        runWeekStart: day,
      ),
    );

    DiaryBalanceNotCountingDayData notCounting(double target) =>
        DiaryBalanceNotCountingDayData(
          day: day,
          startDate: DateTime(2026, 4, 29),
          daily: daily(target),
        );

    double? paceKcal(DiaryBalanceCardData card, {double? paceShare}) =>
        DiaryBudgetCardData.from(
          card: card,
          today: day,
          paceShare: paceShare,
        ).paceKcal;

    test("is the day's target times the share due by now", () {
      expect(paceKcal(loaded(), paceShare: 0.25), 500);
      expect(paceKcal(loaded(target: 2218), paceShare: 0.5), 1109);
      expect(paceKcal(loaded(), paceShare: 1), 2000);
    });

    test('is 0 before the day starts, so the marker still shows', () {
      expect(paceKcal(loaded(), paceShare: 0), 0);
    });

    test('is null without a share, which is the marker off or a day that '
        'is not today', () {
      expect(paceKcal(loaded()), isNull);
    });

    test('is null on a pause day, which has no target to pace', () {
      expect(paceKcal(loaded(isPauseDay: true), paceShare: 0.5), isNull);
    });

    test('marks a practice day and a day before a restart against their '
        'own target', () {
      expect(
        paceKcal(
          DiaryBalanceCardData.practiceDay(practiceDay: notCounting(1200)),
          paceShare: 0.5,
        ),
        600,
      );
      expect(
        paceKcal(
          DiaryBalanceCardData.scheduledRestart(
            scheduledRestart: notCounting(1600),
          ),
          paceShare: 0.25,
        ),
        400,
      );
    });
  });
}
