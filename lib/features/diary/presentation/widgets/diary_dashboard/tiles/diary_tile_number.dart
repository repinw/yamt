import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/utils/text_measure.dart';

/// The big number of a tile in Geist, shrunk to fit the space it gets.
///
/// Give it the room it may fill (for example with `Expanded`); it never
/// wraps and scales down instead of cutting off. At large text, numbers
/// that sit side by side share one size, so they all take the size that the
/// widest one needs: measure it once per tile with [sharedWidth] and give
/// it to each number.
class DiaryTileNumber extends StatelessWidget {
  /// Creates the number [text], optionally followed by a smaller [unit].
  const new(
    this.text, {
    this.unit,
    this.color,
    this.sharedWidth,
    this.compact = false,
    this.minScale = 0,
    this.alignment = AlignmentDirectional.centerStart,
    super.key,
  });

  /// The number as shown, already formatted.
  final String text;

  /// Unit after the number, such as "kcal".
  final String? unit;

  /// Color of the number; ink by default.
  final Color? color;

  /// Width of the widest number of the tile, from [sharedWidthOf]; null where
  /// each number takes its own size.
  final double? sharedWidth;

  /// Whether the number is set small, in a row with other text.
  final bool compact;

  /// Smallest share of the [sharedWidth] the number may shrink to; below it
  /// the number drops out instead of showing too small to read. Without a
  /// [sharedWidth] the number never drops out.
  final double minScale;

  /// Where the number sits when it is smaller than its space.
  final AlignmentGeometry alignment;

  /// The width that the widest of [texts] needs, for the numbers of one tile
  /// to give [sharedWidth]; null at the default text size, where each number
  /// takes its own size.
  static double? sharedWidthOf(
    BuildContext context,
    Iterable<String> texts, {
    String? unit,
    bool compact = false,
  }) {
    if (!isLargeText(context)) return null;
    final (numberStyle, unitStyle) = _styles(context, compact: compact);
    return texts
        .map(
          (text) => measureLineWidth(
            context,
            _span(text, unit, numberStyle, unitStyle),
          ),
        )
        .fold<double>(0, math.max);
  }

  static (TextStyle?, TextStyle?) _styles(
    BuildContext context, {
    required bool compact,
    Color? color,
  }) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final numberStyle =
        (compact ? textTheme.titleMedium : textTheme.displaySmall)?.copyWith(
          fontFamily: AppFonts.geist,
          fontWeight: compact ? FontWeight.w700 : FontWeight.w800,
          height: compact ? null : AppBudgetCard.bigNumberLineHeight,
          color: color ?? colors.ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    final unitStyle = textTheme.bodyMedium?.copyWith(
      fontFamily: AppFonts.geist,
      fontWeight: FontWeight.w500,
      color: colors.muted,
    );
    return (numberStyle, unitStyle);
  }

  static TextSpan _span(
    String text,
    String? unit,
    TextStyle? numberStyle,
    TextStyle? unitStyle,
  ) => TextSpan(
    children: [
      TextSpan(text: text, style: numberStyle),
      if (unit != null) TextSpan(text: ' $unit', style: unitStyle),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final (numberStyle, unitStyle) = _styles(
      context,
      compact: compact,
      color: color,
    );
    final span = _span(text, unit, numberStyle, unitStyle);
    final width = sharedWidth;

    final fitted = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: width == null
          ? Text.rich(span, maxLines: 1)
          : SizedBox(
              width: width,
              child: Align(
                alignment: alignment,
                child: Text.rich(span, maxLines: 1, softWrap: false),
              ),
            ),
    );
    // Keeps the line height in a row: the fitted box alone would take the
    // height its aspect ratio gives the full row width.
    final content = compact
        ? Align(alignment: alignment, heightFactor: 1, child: fitted)
        : fitted;
    if (width == null || minScale == 0) return content;
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < width * minScale
          ? Semantics(
              label: unit == null ? text : '$text $unit',
              child: const SizedBox.shrink(),
            )
          : content,
    );
  }
}
