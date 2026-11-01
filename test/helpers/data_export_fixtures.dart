import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/data_export/application/data_export_labels.dart';
import 'package:yamt/features/data_export/domain/data_export_report.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// English labels in the `en` locale.
Future<DataExportLabels> englishLabels() async {
  await initializeDateFormatting('en');
  return DataExportLabels(lookupAppLocalizations(const Locale('en')), 'en');
}

/// A 100 g oat entry of [mealType] with known macros: 400 kcal, 12 g
/// protein, 60 g carbs, 8 g fat.
CalorieEntry oatEntry({
  String id = 'oat',
  MealType mealType = MealType.breakfast,
  String? brand = 'Farm & <Co>',
}) => CalorieEntry.create(
  id: id,
  userId: 'u1',
  name: 'Oats',
  brand: brand,
  mealType: mealType,
  consumedAmount: 100,
  consumedUnit: ConsumedUnit.grams,
  per100Kcal: 400,
  per100Protein: 12,
  per100Carbs: 60,
  per100Fat: 8,
  loggedAt: DateTime(2026, 9, 20, 8),
);

/// A day with [meals], a goal of 2000 kcal unless it is a pause day.
DataExportDay exportDay(
  DateTime day, {
  DiaryDayType type = DiaryDayType.normal,
  double goalKcal = 2000,
  List<DataExportMeal> meals = const [],
  double? weightKg,
  double? trendWeightKg,
  double? tdeeKcal,
  double? tdeeDayValueKcal,
}) => DataExportDay(
  day: day,
  dayType: type,
  goalKcal: goalKcal,
  proteinGoalGrams: 150,
  carbsGoalGrams: 200,
  fatGoalGrams: 60,
  meals: meals,
  weightKg: weightKg,
  trendWeightKg: trendWeightKg,
  tdeeKcal: tdeeKcal,
  tdeeDayValueKcal: tdeeDayValueKcal,
);

/// A one goal report over [days].
DataExportReport exportReport(
  List<DataExportDay> days, {
  bool withGoal = true,
}) => DataExportReport(
  from: days.first.day,
  to: days.last.day,
  goals: [
    if (withGoal)
      DataExportGoal(
        number: 1,
        startDay: days.first.day,
        endDay: null,
        goalMode: CalorieGoalMode.lose,
        startWeightKg: 84,
        targetWeightKg: 78,
        speedKgPerWeek: 0.5,
        baseKcal: 2000,
      ),
  ],
  mealSharePercents: const [25, 35, 30, 10],
  days: days,
);

/// A report of three days: a logged normal day with a weighing, TDEE, and
/// TDEE day value, a logged training day, and a pause day without entries.
DataExportReport sampleReport() => exportReport([
  exportDay(
    DateTime(2026, 9, 20),
    meals: [
      DataExportMeal(mealType: MealType.breakfast, foods: [oatEntry()]),
    ],
    weightKg: 83.4,
    trendWeightKg: 83.6,
    tdeeKcal: 2500,
    tdeeDayValueKcal: 2650,
  ),
  exportDay(
    DateTime(2026, 9, 21),
    type: DiaryDayType.training,
    goalKcal: 2250,
    meals: [
      DataExportMeal(
        mealType: MealType.lunch,
        foods: [oatEntry(id: 'oat2', mealType: MealType.lunch, brand: null)],
      ),
      DataExportMeal(
        mealType: MealType.dinner,
        foods: [oatEntry(id: 'oat3', mealType: MealType.dinner)],
      ),
    ],
  ),
  exportDay(DateTime(2026, 9, 22), type: DiaryDayType.pause, goalKcal: 0),
]);
