import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Square stock bar with one segment per pack or portion. Each segment fills
/// with what is left of it, so two packs with one and a half left show one
/// full and one half segment.
///
/// More than [AppGraphit.stockBarMaxSegments] segments draw one continuous
/// bar instead.
class GraphitStockBar extends StatelessWidget {
  /// Creates the bar for [share] of the full stock split into [segments].
  const new({
    required this.share,
    required this.segments,
    this.isLow = false,
    this.plannedShare = 0,
    super.key,
  });

  /// Remaining stock from 0 (empty) to 1 (full).
  final double share;

  /// Number of packs or portions.
  final int segments;

  /// Whether the stock is almost used up; the fill then turns to the low
  /// color.
  final bool isLow;

  /// Part of [share] kept for plans, drawn in the accent color at the end
  /// of the fill.
  final double plannedShare;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final fill = isLow ? colors.low : colors.ink;
    final count = segments < 1 || segments > AppGraphit.stockBarMaxSegments
        ? 1
        : segments;
    final clampedShare = share.clamp(0.0, 1.0);
    final freeShare = (clampedShare - plannedShare).clamp(0.0, clampedShare);
    return Row(
      spacing: AppGraphit.stockBarGap,
      children: [
        for (var index = 0; index < count; index++)
          Expanded(
            child: _Segment(
              fill: (clampedShare * count - index).clamp(0.0, 1.0),
              free: (freeShare * count - index).clamp(0.0, 1.0),
              fillColor: fill,
              plannedColor: colors.accent,
              trackColor: colors.track,
            ),
          ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const new({
    required this.fill,
    required this.free,
    required this.fillColor,
    required this.plannedColor,
    required this.trackColor,
  });

  final double fill;

  /// The part of [fill] that no plan keeps.
  final double free;
  final Color fillColor;
  final Color plannedColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppGraphit.stockBarHeight,
      child: ColoredBox(
        color: trackColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (fill > free)
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: fill,
                child: ColoredBox(color: plannedColor),
              ),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: free,
              child: ColoredBox(color: fillColor),
            ),
          ],
        ),
      ),
    );
  }
}
