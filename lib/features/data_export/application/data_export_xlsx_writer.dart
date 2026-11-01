import 'dart:typed_data';

import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/utils/xlsx_workbook.dart';
import 'package:yamt/features/data_export/application/data_export_labels.dart';
import 'package:yamt/features/data_export/domain/data_export_report.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';

/// Writes [report] as a spreadsheet with the sheets days, meals, foods, and
/// goals. Numbers stay numbers, so an advisor can calculate with them.
Uint8List writeDataExportXlsx(DataExportReport report, DataExportLabels t) {
  final l10n = t.l10n;
  return encodeXlsxWorkbook([
    XlsxSheet(name: l10n.dataExportSheetDays, rows: _days(report, t)),
    XlsxSheet(name: l10n.dataExportSheetMeals, rows: _meals(report, t)),
    XlsxSheet(name: l10n.dataExportSheetFoods, rows: _foods(report, t)),
    XlsxSheet(name: l10n.dataExportSheetGoals, rows: _goals(report, t)),
  ]);
}

double _round(double value, [int decimals = 0]) =>
    double.parse(value.toStringAsFixed(decimals));

List<List<Object?>> _days(DataExportReport report, DataExportLabels t) {
  final l10n = t.l10n;
  return [
    [
      l10n.dataExportColumnDate,
      l10n.dataExportColumnDayType,
      l10n.dataExportColumnGoal,
      l10n.dataExportColumnKcal,
      l10n.dataExportColumnProteinGoal,
      l10n.dataExportColumnProtein,
      l10n.dataExportColumnCarbsGoal,
      l10n.dataExportColumnCarbs,
      l10n.dataExportColumnFatGoal,
      l10n.dataExportColumnFat,
      l10n.dataExportColumnWeight,
      l10n.dataExportColumnTrend,
      l10n.dataExportColumnTdee,
      l10n.dataExportColumnTdeeDayValue,
    ],
    for (final day in report.days)
      [
        t.date(day.day),
        t.dayType(day.dayType),
        if (day.hasGoal) _round(day.goalKcal) else null,
        _round(day.kcal),
        if (day.hasGoal) _round(day.proteinGoalGrams) else null,
        _round(day.proteinGrams, 1),
        if (day.hasGoal) _round(day.carbsGoalGrams) else null,
        _round(day.carbsGrams, 1),
        if (day.hasGoal) _round(day.fatGoalGrams) else null,
        _round(day.fatGrams, 1),
        if (day.weightKg case final weight?) _round(weight, 2) else null,
        if (day.trendWeightKg case final trend?) _round(trend, 2) else null,
        if (day.tdeeKcal case final tdee?) _round(tdee) else null,
        if (day.tdeeDayValueKcal case final dayValue?)
          _round(dayValue)
        else
          null,
      ],
  ];
}

List<List<Object?>> _meals(DataExportReport report, DataExportLabels t) {
  final l10n = t.l10n;
  final shares = DiaryMealShares(report.mealSharePercents);
  return [
    [
      l10n.dataExportColumnDate,
      l10n.dataExportColumnMeal,
      l10n.dataExportColumnMealGoal,
      l10n.dataExportColumnKcal,
      l10n.dataExportColumnProtein,
      l10n.dataExportColumnCarbs,
      l10n.dataExportColumnFat,
    ],
    for (final day in report.days)
      for (final meal in day.meals)
        [
          t.date(day.day),
          t.meal(meal.mealType),
          // Pause days and days before the first goal have no meal goal.
          if (day.hasGoal)
            shares.splitKcal(day.goalKcal)[MealType.sectionOrder.indexOf(
              meal.mealType,
            )]
          else
            null,
          _round(meal.kcal),
          _round(meal.proteinGrams, 1),
          _round(meal.carbsGrams, 1),
          _round(meal.fatGrams, 1),
        ],
  ];
}

List<List<Object?>> _foods(DataExportReport report, DataExportLabels t) {
  final l10n = t.l10n;
  return [
    [
      l10n.dataExportColumnDate,
      l10n.dataExportColumnMeal,
      l10n.dataExportColumnFood,
      l10n.dataExportColumnBrand,
      l10n.dataExportColumnAmount,
      l10n.dataExportColumnUnit,
      l10n.dataExportColumnKcal,
      l10n.dataExportColumnProtein,
      l10n.dataExportColumnCarbs,
      l10n.dataExportColumnFat,
    ],
    for (final day in report.days)
      for (final meal in day.meals)
        for (final food in meal.foods)
          [
            t.date(day.day),
            t.meal(meal.mealType),
            t.foodName(food, withBrand: false),
            switch (food.brand) {
              final brand? => DataExportLabels.oneLine(brand),
              null => null,
            },
            _round(food.consumedAmount, 1),
            food.consumedUnit.jsonValue,
            _round(food.totalKcal),
            _round(food.totalProtein, 1),
            _round(food.totalCarbs, 1),
            _round(food.totalFat, 1),
          ],
  ];
}

List<List<Object?>> _goals(DataExportReport report, DataExportLabels t) {
  final l10n = t.l10n;
  return [
    [
      l10n.dataExportColumnNumber,
      l10n.dataExportColumnMode,
      l10n.dataExportColumnStart,
      l10n.dataExportColumnEnd,
      l10n.dataExportColumnStartWeight,
      l10n.dataExportColumnTargetWeight,
      l10n.dataExportColumnSpeed,
      l10n.dataExportColumnBaseKcal,
    ],
    for (final goal in report.goals)
      [
        goal.number,
        t.goalMode(goal.goalMode),
        t.date(goal.startDay),
        if (goal.endDay case final end?)
          t.date(end)
        else
          l10n.dataExportGoalRunning,
        if (goal.startWeightKg case final kg?) _round(kg, 1) else null,
        if (goal.targetWeightKg case final kg?) _round(kg, 1) else null,
        if (goal.speedKgPerWeek case final kg?) _round(kg, 2) else null,
        if (goal.baseKcal case final kcal?) _round(kcal) else null,
      ],
    <Object?>[],
    [l10n.dataExportColumnMeal, l10n.dataExportColumnShare],
    for (final (index, meal) in MealType.sectionOrder.indexed)
      [t.meal(meal), report.mealSharePercents[index]],
  ];
}
