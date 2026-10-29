import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
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
}
