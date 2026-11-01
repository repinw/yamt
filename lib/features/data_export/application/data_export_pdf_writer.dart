import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:yamt/features/data_export/application/data_export_labels.dart';
import 'package:yamt/features/data_export/application/data_export_pdf_charts.dart';
import 'package:yamt/features/data_export/application/data_export_pdf_day_table.dart';
import 'package:yamt/features/data_export/application/data_export_pdf_small_charts.dart';
import 'package:yamt/features/data_export/domain/data_export_report.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';

/// Writes [report] as a PDF: page 1 holds the key numbers, the goals, and
/// the charts; the pages after it the table of every day with its foods.
Future<Uint8List> writeDataExportPdf(
  DataExportReport report,
  DataExportLabels t,
) async {
  final regular = await rootBundle.load(
    'assets/fonts/PlusJakartaSans-Regular.ttf',
  );
  final bold = await rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf');
  final document = pw.Document(
    title: t.l10n.dataExportReportTitle,
    theme: pw.ThemeData.withFont(
      base: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    ),
  );
  const margin = pw.EdgeInsets.all(32);
  document
    ..addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: margin,
        build: (context) => _Overview(report: report, t: t),
      ),
    )
    ..addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: margin,
        maxPages: 1000,
        footer: (context) => _footer(context, t),
        build: (context) => [dataExportDayTable(context, report, t)],
      ),
    );
  return await document.save();
}

pw.Widget _footer(pw.Context context, DataExportLabels t) {
  final style = pw.Theme.of(context).defaultTextStyle
      .copyWith(fontSize: 7, color: DataExportPdfColors.muted);
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(t.l10n.dataExportFooter, style: style),
      pw.Text('${context.pageNumber} / ${context.pagesCount}', style: style),
    ],
  );
}

class _Overview extends pw.StatelessWidget {
  new({required this.report, required this.t});

  final DataExportReport report;
  final DataExportLabels t;

  @override
  pw.Widget build(pw.Context context) {
    final l10n = t.l10n;
    final base = pw.Theme.of(context).defaultTextStyle;
    final small = base.copyWith(fontSize: 8);
    final title = base.copyWith(fontSize: 10, fontWeight: pw.FontWeight.bold);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              l10n.dataExportReportTitle,
              style: base.copyWith(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              l10n.dataExportReportPeriod(
                t.date(report.from),
                t.date(report.to),
                report.days.length,
              ),
              style: small,
            ),
          ],
        ),
        pw.Divider(thickness: 1.5, color: DataExportPdfColors.ink),
        _Kpis(report: report, t: t),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: DataExportPdfColors.rule),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (report.goals.isEmpty)
                pw.Text(l10n.dataExportNoGoal, style: small),
              for (final goal in report.goals)
                pw.Text(t.goalLine(goal), style: small),
              pw.Text(t.mealShares(report), style: small),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(l10n.dataExportChartCombined, style: title),
        pw.SizedBox(height: 4),
        _combinedChart(report),
        pw.SizedBox(height: 3),
        dataExportLegend([
          (DataExportPdfColors.pause, l10n.dataExportLegendEaten),
          (DataExportPdfColors.ink, l10n.dataExportLegendTdee),
          (DataExportPdfColors.muted, l10n.dataExportLegendGoal),
          (DataExportPdfColors.weight, l10n.dataExportLegendWeight),
        ], small),
        pw.SizedBox(height: 14),
        DataExportPdfSmallCharts(report: report, t: t),
      ],
    );
  }
}

pw.Widget _combinedChart(DataExportReport report) {
  final days = report.days;
  final barScale = dataExportScale([
    0,
    for (final day in days) ...[day.kcal, day.countedGoalKcal, day.tdeeKcal],
  ]);
  final weights = [for (final day in days) day.trendWeightKg ?? day.weightKg];
  return dataExportChart(
    height: 150,
    bars: DataExportBarSeries(
      values: [for (final day in days) day.kcal],
      colors: [for (final day in days) _combinedBarColor(day)],
    ),
    barScale: barScale,
    lines: [
      DataExportLineSeries(
        values: [for (final day in days) day.tdeeKcal],
        color: DataExportPdfColors.ink,
        dashed: true,
      ),
      DataExportLineSeries(
        values: [for (final day in days) day.countedGoalKcal],
        color: DataExportPdfColors.muted,
        width: 0.8,
      ),
      DataExportLineSeries(
        values: weights,
        color: DataExportPdfColors.weight,
        width: 2,
      ),
    ],
    lineScales: [barScale, barScale, dataExportScale(weights, padding: 0.5)],
  );
}

PdfColor _combinedBarColor(DataExportDay day) =>
    day.dayType == DiaryDayType.training
    ? DataExportPdfColors.muted
    : DataExportPdfColors.pause;

class _Kpis extends pw.StatelessWidget {
  new({required this.report, required this.t});

  final DataExportReport report;
  final DataExportLabels t;

  @override
  pw.Widget build(pw.Context context) {
    final l10n = t.l10n;
    final weights = [for (final day in report.days) ?day.weightKg];
    final goal = report.averageGoal((day) => day.goalKcal);
    return pw.Row(
      children: [
        for (final (label, value, line) in [
          (
            l10n.dataExportKpiEaten,
            t.whole(report.averageLogged((day) => day.kcal)),
            l10n.dataExportKpiGoal(t.whole(goal)),
          ),
          (
            l10n.dataExportKpiTdee,
            t.whole(report.averageTdeeKcal),
            l10n.dataExportKcalUnit,
          ),
          (
            l10n.dataExportKpiWeight,
            weights.isEmpty
                ? dataExportMissingValue
                : t.signedOneDecimal(weights.last - weights.first),
            weights.isEmpty
                ? ''
                : l10n.dataExportKpiWeightRange(
                    t.oneDecimal(weights.first),
                    t.oneDecimal(weights.last),
                  ),
          ),
          (
            l10n.dataExportKpiDays,
            l10n.dataExportTrainingPauseCount(
              report.countOf(DiaryDayType.training),
              report.countOf(DiaryDayType.pause),
            ),
            '',
          ),
        ]) ...[
          pw.Expanded(child: _kpi(context, label, value, line)),
          pw.SizedBox(width: 6),
        ],
      ],
    );
  }

  pw.Widget _kpi(pw.Context context, String label, String value, String line) {
    final base = pw.Theme.of(context).defaultTextStyle;
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      color: DataExportPdfColors.tile,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: base.copyWith(fontSize: 7)),
          pw.Text(
            value,
            style: base.copyWith(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(line, style: base.copyWith(fontSize: 7)),
        ],
      ),
    );
  }
}
