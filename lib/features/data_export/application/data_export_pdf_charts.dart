import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Colors of the exported report. The report is printed on white, so it
/// keeps its own palette instead of the app theme.
abstract final class DataExportPdfColors {
  /// Text and axes.
  static final ink = PdfColor.fromHex('#141414');

  /// Secondary text.
  static final muted = PdfColor.fromHex('#5c5c58');

  /// Tile background.
  static final tile = PdfColor.fromHex('#f1f1ee');

  /// Thin rules and empty bars.
  static final rule = PdfColor.fromHex('#d6d6d1');

  /// Weight.
  static final weight = PdfColor.fromHex('#e0662a');

  /// Training day.
  static final training = PdfColor.fromHex('#e8a33b');

  /// Normal day.
  static final normal = PdfColor.fromHex('#6fb3df');

  /// Pause day.
  static final pause = PdfColor.fromHex('#cfcfca');

  /// Protein.
  static final protein = PdfColor.fromHex('#d64545');

  /// Carbohydrates.
  static final carbs = PdfColor.fromHex('#3f7fd6');

  /// Fat.
  static final fat = PdfColor.fromHex('#e2b321');
}

/// One bar per day, each with its own color; null leaves the slot empty.
class DataExportBarSeries {
  /// Creates bars of [values] in [colors].
  const new({required this.values, required this.colors});

  /// Value per slot.
  final List<double?> values;

  /// Color per slot.
  final List<PdfColor> colors;
}

/// A line through the slot centers; null breaks the line.
class DataExportLineSeries {
  /// Creates a line of [values] in [color].
  const new({
    required this.values,
    required this.color,
    this.dashed = false,
    this.width = 1.5,
  });

  /// Value per slot.
  final List<double?> values;

  /// Line color.
  final PdfColor color;

  /// Whether the line is dashed.
  final bool dashed;

  /// Line width in points.
  final double width;
}

/// The smallest and largest of [values] with [padding] around them, or null
/// when no value is set.
({double min, double max})? dataExportScale(
  Iterable<double?> values, {
  double padding = 0,
}) {
  final set = values.nonNulls.toList();
  if (set.isEmpty) return null;
  final low = set.reduce(math.min) - padding;
  final high = set.reduce(math.max) + padding;
  return (min: low, max: high > low ? high : low + 1);
}

/// A chart of [height] points: [bars] on the scale [barScale] and [lines],
/// each line on its own scale from [lineScales].
pw.Widget dataExportChart({
  required double height,
  DataExportBarSeries? bars,
  ({double min, double max})? barScale,
  List<DataExportLineSeries> lines = const [],
  List<({double min, double max})?> lineScales = const [],
}) {
  return pw.SizedBox(
    height: height,
    child: pw.CustomPaint(
      size: PdfPoint(double.infinity, height),
      painter: (canvas, size) {
        final slots = math.max(
          bars?.values.length ?? 0,
          lines.fold(0, (count, line) => math.max(count, line.values.length)),
        );
        if (slots == 0) return;
        final slot = size.x / slots;
        if (bars != null && barScale != null) {
          _paintBars(canvas, size, slot, bars, barScale);
        }
        for (final (index, line) in lines.indexed) {
          final scale = index < lineScales.length ? lineScales[index] : null;
          if (scale != null) _paintLine(canvas, size, slot, line, scale);
        }
        canvas
          ..setStrokeColor(DataExportPdfColors.ink)
          ..setLineWidth(0.6)
          ..setLineDashPattern()
          ..moveTo(0, 0)
          ..lineTo(size.x, 0)
          ..strokePath();
      },
    ),
  );
}

double _y(double value, PdfPoint size, ({double min, double max}) scale) =>
    ((value - scale.min) / (scale.max - scale.min)).clamp(0, 1) * size.y;

void _paintBars(
  PdfGraphics canvas,
  PdfPoint size,
  double slot,
  DataExportBarSeries bars,
  ({double min, double max}) scale,
) {
  final gap = math.min(slot * 0.2, 2);
  for (final (index, value) in bars.values.indexed) {
    if (value == null) continue;
    canvas
      ..setFillColor(bars.colors[index])
      ..drawRect(index * slot + gap / 2, 0, slot - gap, _y(value, size, scale))
      ..fillPath();
  }
}

void _paintLine(
  PdfGraphics canvas,
  PdfPoint size,
  double slot,
  DataExportLineSeries line,
  ({double min, double max}) scale,
) {
  canvas
    ..setStrokeColor(line.color)
    ..setLineWidth(line.width)
    ..setLineDashPattern(line.dashed ? const [3, 2] : const []);
  var drawing = false;
  var hasSegment = false;
  for (final (index, value) in line.values.indexed) {
    if (value == null) {
      drawing = false;
      continue;
    }
    final x = index * slot + slot / 2;
    final y = _y(value, size, scale);
    if (drawing) {
      canvas.lineTo(x, y);
      hasSegment = true;
    } else {
      canvas.moveTo(x, y);
      drawing = true;
    }
  }
  if (hasSegment) canvas.strokePath();
}

/// A horizontal bar of [value] against [goal], with [label] above it.
pw.Widget dataExportGoalBar({
  required String label,
  required double value,
  required double goal,
  required PdfColor color,
  required pw.TextStyle style,
}) {
  final filled = goal <= 0
      ? 0
      : ((value / goal).clamp(0.0, 1.0) * 1000).round();
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label, style: style),
      pw.SizedBox(height: 2),
      pw.Container(
        height: 7,
        color: DataExportPdfColors.tile,
        child: pw.Row(
          children: [
            if (filled > 0)
              pw.Expanded(
                flex: filled,
                child: pw.Container(color: color),
              ),
            if (filled < 1000)
              pw.Expanded(flex: 1000 - filled, child: pw.SizedBox()),
          ],
        ),
      ),
    ],
  );
}

/// A legend row of colored squares with their labels.
pw.Widget dataExportLegend(List<(PdfColor, String)> items, pw.TextStyle style) {
  return pw.Wrap(
    spacing: 10,
    runSpacing: 2,
    children: [
      for (final (color, label) in items)
        pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Container(width: 7, height: 7, color: color),
            pw.SizedBox(width: 3),
            pw.Text(label, style: style),
          ],
        ),
    ],
  );
}
