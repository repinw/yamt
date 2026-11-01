import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Thin progress line of the budget card: the eaten part, the planned part
/// as its own rounded pill in the plan color, and the overage in the error
/// color, against a track that reaches 120 % of the target with a goal
/// marker at 100 %. A [pace] adds a notch where the day should be by now.
///
/// Without a [target] (a pause day) it only shows the eaten and the planned
/// part, measured against [scaleKcal]. The parts grow and shrink to new
/// amounts, unless the system asks for less motion.
class DiaryBudgetLine extends StatelessWidget {
  /// Creates a line.
  const new({
    required this.eaten,
    required this.target,
    this.planned = 0,
    this.compact = false,
    this.eatenColor,
    this.scaleKcal,
    this.pace,
    super.key,
  });

  /// Eaten amount.
  final double eaten;

  /// Target amount; null draws no goal marker and no overage.
  final double? target;

  /// Planned amount after the eaten part.
  final double planned;

  /// Whether this is the thinner macro line.
  final bool compact;

  /// Color of the eaten part; ink by default.
  final Color? eatenColor;

  /// Amount at the goal marker when [target] is null.
  final double? scaleKcal;

  /// Amount the day should be at by now; null draws no pace marker.
  final double? pace;

  /// Key of the pace marker, for tests.
  static const paceKey = ValueKey<String>('diary-budget-line-pace');

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final error = Theme.of(context).colorScheme.error;
    final height = compact ? AppBudgetCard.macroLine : AppBudgetCard.line;
    final bar = compact ? AppBudgetCard.macroLineBar : AppBudgetCard.lineBar;
    final marker = compact
        ? AppBudgetCard.macroGoalMarker
        : AppBudgetCard.goalMarker;
    final goal = target;
    final scale = math.max<double>(goal ?? scaleKcal ?? 0, 1);

    return SizedBox(
      height: height,
      child: TweenAnimationBuilder(
        tween: _PartsTween(end: (eaten: eaten, planned: planned)),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppBudgetCard.fadeIn,
        curve: Curves.easeOutCubic,
        builder: (context, parts, _) => LayoutBuilder(
          builder: (context, constraints) {
            final (:eaten, :planned) = parts;
            final width = constraints.maxWidth;
            double at(double value) =>
                (math.max<double>(0, value) / scale / AppBudgetCard.lineScale)
                    .clamp(0.0, 1.0) *
                width;
            final total = eaten + planned;
            final eatenEnd = at(goal == null ? eaten : math.min(eaten, goal));
            final planEnd = at(goal == null ? total : math.min(total, goal));
            final goalAt = at(scale);
            final overEnd = goal != null && total > goal ? at(total) : goalAt;
            final top = (height - bar) / 2;
            final radius = Radius.circular(bar / 2);
            final paceAt = pace == null ? null : at(pace!);

            Widget part(
              double left,
              double right,
              Color color,
              BorderRadius r,
            ) => Positioned(
              left: left,
              top: top,
              width: math.max(0, right - left),
              height: bar,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, borderRadius: r),
              ),
            );

            return Stack(
              children: [
                part(0, width, colors.track, BorderRadius.all(radius)),
                part(
                  0,
                  eatenEnd,
                  eatenColor ?? colors.ink,
                  BorderRadius.all(radius),
                ),
                part(eatenEnd, planEnd, colors.plan, BorderRadius.all(radius)),
                if (goal != null)
                  part(
                    goalAt,
                    overEnd,
                    error,
                    BorderRadius.horizontal(right: radius),
                  ),
                if (goal != null)
                  Positioned(
                    left: goalAt - marker / 2,
                    top: 0,
                    width: marker,
                    height: height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.accentText,
                        borderRadius: BorderRadius.circular(marker / 2),
                      ),
                    ),
                  ),
                if (paceAt != null)
                  Positioned(
                    // At 0 % the triangle stays whole at the edge.
                    left: (paceAt - AppBudgetCard.paceMarker / 2).clamp(
                      0,
                      math.max(0, width - AppBudgetCard.paceMarker),
                    ),
                    top: 0,
                    width: AppBudgetCard.paceMarker,
                    height: top + bar,
                    child: CustomPaint(
                      key: paceKey,
                      painter: _PaceMarkerPainter(color: colors.ink, bar: bar),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Eaten and planned amount of a line, eased together.
class _PartsTween extends Tween<({double eaten, double planned})> {
  new({super.end});

  @override
  ({double eaten, double planned}) lerp(double t) => (
    eaten: begin!.eaten + (end!.eaten - begin!.eaten) * t,
    planned: begin!.planned + (end!.planned - begin!.planned) * t,
  );
}

/// The pace marker: a small triangle above the bar that points down at the
/// spot, and a thin stroke through the bar.
class _PaceMarkerPainter extends CustomPainter {
  const new({required this.color, required this.bar});

  final Color color;
  final double bar;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final tip = size.height - bar;
    canvas
      ..drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width / 2, tip)
          ..close(),
        paint,
      )
      ..drawRect(
        Rect.fromLTWH(
          (size.width - AppBudgetCard.paceStroke) / 2,
          tip,
          AppBudgetCard.paceStroke,
          bar,
        ),
        paint,
      );
  }

  @override
  bool shouldRepaint(_PaceMarkerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.bar != bar;
}
