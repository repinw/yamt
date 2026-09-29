import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_progress_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/progress/domain/progress_day.dart';

/// A goal in equal segments, filled with what was eaten.
///
/// The fill is split by the kcal share of protein, carbohydrates and fat.
/// Above the goal the bar spans everything eaten and hatches the part over
/// the goal.
class ProgressSegmentBar extends StatelessWidget {
  /// Creates a segment bar.
  const new({
    required this.proteinKcal,
    required this.carbsKcal,
    required this.fatKcal,
    required this.eatenKcal,
    required this.goalKcal,
    this.segments = AppProgress.dayBarSegments,
    super.key,
  });

  /// Creates the bar of one [day], in quarters of its goal.
  factory day(ProgressDay day) {
    final eaten = day.isFuture ? 0.0 : day.eatenKcal;
    return ProgressSegmentBar(
      proteinKcal: day.proteinKcal,
      carbsKcal: day.carbsKcal,
      fatKcal: day.fatKcal,
      eatenKcal: eaten,
      goalKcal: day.goalKcal,
    );
  }

  /// Kilocalories from protein.
  final double proteinKcal;

  /// Kilocalories from carbohydrates.
  final double carbsKcal;

  /// Kilocalories from fat.
  final double fatKcal;

  /// Eaten kilocalories, which the macro shares are scaled to.
  final double eatenKcal;

  /// The goal that the segments split.
  final double goalKcal;

  /// Number of segments.
  final int segments;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final macros = MetricAccentColors.of(context);
    return SizedBox(
      height: AppProgress.dayBarHeight,
      child: CustomPaint(
        size: Size.infinite,
        painter: _SegmentBarPainter(
          parts: _parts(macros, colors.ink),
          goalKcal: goalKcal,
          segments: segments,
          track: colors.track,
          hatch: colors.low,
        ),
      ),
    );
  }

  List<(double, Color)> _parts(MetricAccentColors macros, Color ink) {
    if (eatenKcal <= 0) return const [];
    final macroKcal = proteinKcal + carbsKcal + fatKcal;
    if (macroKcal <= 0) return [(eatenKcal, ink)];
    // Scale the macro shares to the eaten kcal, which is the number shown.
    final scale = eatenKcal / macroKcal;
    return [
      (proteinKcal * scale, macros.protein),
      (carbsKcal * scale, macros.carbs),
      (fatKcal * scale, macros.fat),
    ];
  }
}

class _SegmentBarPainter extends CustomPainter {
  const new({
    required this.parts,
    required this.goalKcal,
    required this.segments,
    required this.track,
    required this.hatch,
  });

  final List<(double, Color)> parts;
  final double goalKcal;
  final int segments;
  final Color track;
  final Color hatch;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = AppProgress.dayBarGap;
    final segmentWidth = (size.width - gap * (segments - 1)) / segments;
    final eaten = parts.fold<double>(0, (sum, part) => sum + part.$1);
    final span = math.max(eaten, goalKcal);
    final goalShare = span <= 0 ? 1.0 : goalKcal / span;

    for (var index = 0; index < segments; index++) {
      final left = index * (segmentWidth + gap);
      final segment = Rect.fromLTWH(left, 0, segmentWidth, size.height);
      canvas
        ..save()
        ..clipRect(segment)
        ..drawRect(segment, Paint()..color = track);
      if (span > 0) {
        _paintFill(canvas, segment, index / segments, span);
        if (goalShare < 1) {
          _paintHatch(canvas, segment, index / segments, goalShare);
        }
      }
      canvas.restore();
    }
  }

  /// Draws the parts that fall into the segment starting at [start].
  void _paintFill(Canvas canvas, Rect segment, double start, double span) {
    final share = 1 / segments;
    var from = 0.0;
    for (final (kcal, color) in parts) {
      final to = from + kcal / span;
      final left = math.max(from, start);
      final right = math.min(to, start + share);
      if (right > left) {
        canvas.drawRect(
          Rect.fromLTRB(
            segment.left + (left - start) / share * segment.width,
            segment.top,
            segment.left + (right - start) / share * segment.width,
            segment.bottom,
          ),
          Paint()..color = color,
        );
      }
      from = to;
    }
  }

  /// Hatches the part of the segment that lies over the goal.
  void _paintHatch(Canvas canvas, Rect segment, double start, double goal) {
    final share = 1 / segments;
    final from = math.max(goal, start);
    if (from >= start + share) return;
    final area = Rect.fromLTRB(
      segment.left + (from - start) / share * segment.width,
      segment.top,
      segment.right,
      segment.bottom,
    );
    canvas
      ..drawRect(area, Paint()..color = track)
      ..clipRect(area);
    final stripe = Paint()
      ..color = hatch
      ..strokeWidth = AppProgress.hatchStripe;
    const step = AppProgress.hatchStripe + AppProgress.hatchGap;
    for (var x = area.left - area.height; x < area.right; x += step) {
      canvas.drawLine(
        Offset(x, area.bottom),
        Offset(x + area.height, area.top),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(_SegmentBarPainter oldDelegate) {
    return oldDelegate.parts != parts ||
        oldDelegate.goalKcal != goalKcal ||
        oldDelegate.segments != segments ||
        oldDelegate.track != track ||
        oldDelegate.hatch != hatch;
  }
}
