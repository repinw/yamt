import 'package:pdf/widgets.dart' as pw;
import 'package:yamt/features/data_export/application/data_export_labels.dart';
import 'package:yamt/features/data_export/application/data_export_pdf_charts.dart';
import 'package:yamt/features/data_export/domain/data_export_report.dart';

/// The table of every day of [report]: a shaded row per day with its totals
/// against the goals, weight, and TDEE, then one row per eaten food. It
/// breaks across pages.
pw.Widget dataExportDayTable(
  pw.Context context,
  DataExportReport report,
  DataExportLabels t,
) {
  final l10n = t.l10n;
  final base = pw.Theme.of(context).defaultTextStyle.copyWith(fontSize: 7);
  final bold = base.copyWith(fontWeight: pw.FontWeight.bold);
  pw.Widget text(String value, {pw.TextStyle? style, bool end = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1.5),
        child: pw.Text(
          value,
          style: style ?? base,
          textAlign: end ? pw.TextAlign.right : pw.TextAlign.left,
        ),
      );
  pw.TableRow row(
    List<String> cells, {
    pw.TextStyle? style,
    pw.BoxDecoration? decoration,
  }) => pw.TableRow(
    decoration: decoration,
    children: [
      for (final (index, cell) in cells.indexed)
        text(cell, style: style, end: index >= 3),
    ],
  );
  final dayDecoration = pw.BoxDecoration(color: DataExportPdfColors.tile);
  return pw.Table(
    columnWidths: const {
      0: pw.FlexColumnWidth(1.6),
      1: pw.FlexColumnWidth(3.4),
      2: pw.FlexColumnWidth(1.2),
      3: pw.FlexColumnWidth(1.4),
      4: pw.FlexColumnWidth(1.1),
      5: pw.FlexColumnWidth(1.1),
      6: pw.FlexColumnWidth(1.1),
    },
    border: pw.TableBorder(
      horizontalInside: pw.BorderSide(
        color: DataExportPdfColors.rule,
        width: 0.4,
      ),
    ),
    children: [
      row([
        l10n.dataExportColumnDate,
        l10n.dataExportColumnFood,
        l10n.dataExportColumnAmount,
        l10n.dataExportColumnKcal,
        l10n.dataExportColumnProtein,
        l10n.dataExportColumnCarbs,
        l10n.dataExportColumnFat,
      ], style: bold),
      for (final day in report.days) ...[
        row(
          [
            t.date(day.day),
            [
              t.dayType(day.dayType),
              if (day.weightKg != null)
                l10n.dataExportWeightValue(t.oneDecimal(day.weightKg)),
              if (day.tdeeKcal != null)
                l10n.dataExportDayTdee(t.whole(day.tdeeKcal)),
              if (day.tdeeDayValueKcal != null)
                l10n.dataExportDayTdeeDayValue(t.whole(day.tdeeDayValueKcal)),
            ].join(l10n.dataExportPartsSeparator),
            '',
            for (final (eaten, goal) in [
              (day.kcal, day.countedGoalKcal),
              (day.proteinGrams, day.hasGoal ? day.proteinGoalGrams : null),
              (day.carbsGrams, day.hasGoal ? day.carbsGoalGrams : null),
              (day.fatGrams, day.hasGoal ? day.fatGoalGrams : null),
            ])
              l10n.dataExportValueOfGoal(t.whole(eaten), t.whole(goal)),
          ],
          style: bold,
          decoration: dayDecoration,
        ),
        for (final meal in day.meals)
          for (final food in meal.foods)
            row([
              t.meal(meal.mealType),
              t.foodName(food),
              t.amount(food),
              t.whole(food.totalKcal),
              t.whole(food.totalProtein),
              t.whole(food.totalCarbs),
              t.whole(food.totalFat),
            ]),
      ],
    ],
  );
}
