import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/data_export/application/data_export_labels.dart';
import 'package:yamt/features/data_export/domain/data_export_report.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';

/// Writes [report] as Markdown for the user's own AI: a question on top,
/// the fields explained, the goals, an overview, and every day with its
/// meals and foods.
String writeDataExportMarkdown(DataExportReport report, DataExportLabels t) {
  final l10n = t.l10n;
  final period = l10n.dataExportReportPeriod(
    t.date(report.from),
    t.date(report.to),
    report.days.length,
  );
  final lines = <String>[
    '# ${l10n.dataExportReportTitle} · $period',
    '',
    '> ${l10n.dataExportAiPrompt}',
    '',
    '## ${l10n.dataExportFieldsHeader}',
    l10n.dataExportFieldsText,
    '',
    '## ${l10n.dataExportGoalsHeader}',
    if (report.goals.isEmpty) l10n.dataExportNoGoal,
    for (final goal in report.goals) '- ${t.goalLine(goal)}',
    '- ${t.mealShares(report)}',
    '',
    '## ${l10n.dataExportOverviewHeader}',
    for (final line in _overview(report, t)) '- $line',
    '',
    '## ${l10n.dataExportDaysHeader}',
    for (final day in report.days) ..._day(day, t),
  ];
  return '${lines.join('\n')}\n';
}

List<String> _overview(DataExportReport report, DataExportLabels t) {
  final l10n = t.l10n;
  final weights = [for (final day in report.days) ?day.weightKg];
  return [
    l10n.dataExportOverviewLine(
      t.whole(report.averageLogged((day) => day.kcal)),
      t.whole(report.averageLogged((day) => day.proteinGrams)),
      t.whole(report.averageLogged((day) => day.carbsGrams)),
      t.whole(report.averageLogged((day) => day.fatGrams)),
      t.whole(report.averageTdeeKcal),
    ),
    if (weights.isNotEmpty)
      l10n.dataExportWeightLine(
        t.oneDecimal(weights.first),
        t.oneDecimal(weights.last),
        t.signedOneDecimal(weights.last - weights.first),
      ),
    l10n.dataExportDayTypesLine(
      report.countOf(DiaryDayType.training),
      report.countOf(DiaryDayType.normal),
      report.countOf(DiaryDayType.pause),
    ),
  ];
}

List<String> _day(DataExportDay day, DataExportLabels t) {
  final l10n = t.l10n;
  final head = l10n.dataExportDayLine(
    t.weekdayDate(day.day),
    t.dayType(day.dayType),
    t.whole(day.kcal),
    t.whole(day.countedGoalKcal),
    t.whole(day.proteinGrams),
    t.whole(day.hasGoal ? day.proteinGoalGrams : null),
    t.whole(day.carbsGrams),
    t.whole(day.hasGoal ? day.carbsGoalGrams : null),
    t.whole(day.fatGrams),
    t.whole(day.hasGoal ? day.fatGoalGrams : null),
  );
  return [
    '',
    '### $head',
    if (day.weightKg != null)
      l10n.dataExportDayWeight(
        t.oneDecimal(day.weightKg),
        t.oneDecimal(day.trendWeightKg),
      ),
    if (day.tdeeKcal != null) l10n.dataExportDayTdee(t.whole(day.tdeeKcal)),
    if (day.meals.isEmpty) l10n.dataExportNoEntries,
    for (final meal in day.meals) ...[
      _bold(l10n.dataExportMealLine(t.meal(meal.mealType), t.whole(meal.kcal))),
      for (final food in meal.foods) '- ${_food(food, t)}',
    ],
  ];
}

String _food(CalorieEntry food, DataExportLabels t) =>
    t.l10n.dataExportFoodLine(
      t.foodName(food),
      t.amount(food),
      t.whole(food.totalKcal),
      t.whole(food.totalProtein),
      t.whole(food.totalCarbs),
      t.whole(food.totalFat),
    );

String _bold(String text) => '**$text**';
