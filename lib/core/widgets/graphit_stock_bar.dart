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
    super.key,
  });

  /// Remaining stock from 0 (empty) to 1 (full).
  final double share;

  /// Number of packs or portions.
  final int segments;

  /// Whether the stock is almost used up; the fill then turns to the low
  /// color.
  final bool isLow;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final fill = isLow ? colors.low : colors.ink;
    final count = segments < 1 || segments > AppGraphit.stockBarMaxSegments
        ? 1
        : segments;
    final clampedShare = share.clamp(0.0, 1.0);
    return Row(
      spacing: AppGraphit.stockBarGap,
      children: [
        for (var index = 0; index < count; index++)
          Expanded(
            child: _Segment(
              fill: (clampedShare * count - index).clamp(0.0, 1.0),
              fillColor: fill,
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
    required this.fillColor,
    required this.trackColor,
  });

  final double fill;
  final Color fillColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppGraphit.stockBarHeight,
      child: ColoredBox(
        color: trackColor,
        child: FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: fill,
          child: ColoredBox(color: fillColor),
        ),
      ),
    );
  }
}
