import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/data_export/application/data_export_labels.dart';
import 'package:yamt/features/data_export/application/data_export_pdf_charts.dart';
import 'package:yamt/features/data_export/domain/data_export_report.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';

/// The four small charts of the report's first page: weight as bars, the
/// TDEE as a line, kcal eaten against the goal by day type, and the
/// average macros against their goals with the parts of the day.
class DataExportPdfSmallCharts extends pw.StatelessWidget {
  /// Creates the small charts of [report].
  new({required this.report, required this.t});

  /// The exported days.
  final DataExportReport report;

  /// Words and number formats.
  final DataExportLabels t;

  @override
  pw.Widget build(pw.Context context) {
    final l10n = t.l10n;
    final base = pw.Theme.of(context).defaultTextStyle;
    final small = base.copyWith(fontSize: 7);
    final title = base.copyWith(fontSize: 9, fontWeight: pw.FontWeight.bold);
    final days = report.days;
    final weights = [for (final day in days) day.weightKg];
    final tdee = [for (final day in days) day.tdeeKcal];
    final kcalScale = dataExportScale([
      0,
      for (final day in days) ...[day.kcal, day.countedGoalKcal],
    ]);
    pw.Widget cell(String heading, List<pw.Widget> children) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(heading, style: title),
        pw.SizedBox(height: 4),
        ...children,
      ],
    );
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: cell(l10n.dataExportChartWeight, [
                dataExportChart(
                  height: 90,
                  bars: DataExportBarSeries(
                    values: weights,
                    colors: [for (final _ in days) DataExportPdfColors.weight],
                  ),
                  barScale: dataExportScale(weights, padding: 1),
                ),
              ]),
            ),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: cell(l10n.dataExportChartTdee, [
                dataExportChart(
                  height: 90,
                  lines: [
                    DataExportLineSeries(
                      values: tdee,
                      color: DataExportPdfColors.ink,
                      width: 2,
                    ),
                  ],
                  lineScales: [dataExportScale(tdee, padding: 50)],
                ),
              ]),
            ),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: cell(l10n.dataExportChartKcal, [
                dataExportChart(
                  height: 90,
                  bars: DataExportBarSeries(
                    values: [for (final day in days) day.kcal],
                    colors: [for (final day in days) _dayColor(day.dayType)],
                  ),
                  barScale: kcalScale,
                  lines: [
                    DataExportLineSeries(
                      values: [for (final day in days) day.countedGoalKcal],
                      color: DataExportPdfColors.ink,
                      dashed: true,
                      width: 0.8,
                    ),
                  ],
                  lineScales: [kcalScale],
                ),
                pw.SizedBox(height: 3),
                dataExportLegend([
                  (DataExportPdfColors.training, l10n.diaryDayTypeTraining),
                  (DataExportPdfColors.normal, l10n.diaryDayTypeNormal),
                  (DataExportPdfColors.pause, l10n.diaryDayTypePause),
                ], small),
              ]),
            ),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: cell(l10n.dataExportChartMacros, _macros(small)),
            ),
          ],
        ),
      ],
    );
  }

  List<pw.Widget> _macros(pw.TextStyle style) {
    final l10n = t.l10n;
    double average(double Function(DataExportDay day) value) =>
        report.averageLogged(value) ?? 0;
    final macros = [
      (
        l10n.caloriesProteinLabel,
        average((day) => day.proteinGrams),
        report.averageGoal((day) => day.proteinGoalGrams) ?? 0,
        DataExportPdfColors.protein,
      ),
      (
        l10n.caloriesCarbsLabel,
        average((day) => day.carbsGrams),
        report.averageGoal((day) => day.carbsGoalGrams) ?? 0,
        DataExportPdfColors.carbs,
      ),
      (
        l10n.caloriesFatLabel,
        average((day) => day.fatGrams),
        report.averageGoal((day) => day.fatGoalGrams) ?? 0,
        DataExportPdfColors.fat,
      ),
    ];
    return [
      for (final (label, value, goal, color) in macros) ...[
        dataExportGoalBar(
          label: l10n.dataExportMacroBar(label, t.whole(value), t.whole(goal)),
          value: value,
          goal: goal,
          color: color,
          style: style,
        ),
        pw.SizedBox(height: 5),
      ],
      pw.Text(_eatenShares(), style: style),
    ];
  }

  /// The parts of the day as eaten, in the same words as the planned ones.
  String _eatenShares() {
    final kcal = {
      for (final meal in MealType.sectionOrder)
        meal: report.days.fold<double>(
          0,
          (sum, day) =>
              sum +
              day.meals
                  .where((entry) => entry.mealType == meal)
                  .fold<double>(0, (total, entry) => total + entry.kcal),
        ),
    };
    final total = kcal.values.fold<double>(0, (sum, value) => sum + value);
    return t.l10n.dataExportMealShares(
      [
        for (final meal in MealType.sectionOrder)
          t.l10n.dataExportMealShare(
            t.meal(meal),
            total == 0 ? 0 : (kcal[meal]! / total * 100).round(),
          ),
      ].join(t.l10n.dataExportListSeparator),
    );
  }
}

PdfColor _dayColor(DiaryDayType type) => switch (type) {
  DiaryDayType.training => DataExportPdfColors.training,
  DiaryDayType.normal => DataExportPdfColors.normal,
  DiaryDayType.pause => DataExportPdfColors.pause,
};
