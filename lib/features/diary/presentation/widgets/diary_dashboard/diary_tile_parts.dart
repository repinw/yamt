import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// The big number of a tile in Geist, shrunk to fit the space it gets.
///
/// Give it the room it may fill (for example with `Expanded`); it never
/// wraps and scales down instead of cutting off.
class DiaryTileNumber extends StatelessWidget {
  /// Creates the number [text], optionally followed by a smaller [unit].
  const new(
    this.text, {
    this.unit,
    this.color,
    this.alignment = AlignmentDirectional.centerStart,
    super.key,
  });

  /// The number as shown, already formatted.
  final String text;

  /// Unit after the number, such as "kcal".
  final String? unit;

  /// Color of the number; ink by default.
  final Color? color;

  /// Where the number sits when it is smaller than its space.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final numberStyle = textTheme.displaySmall?.copyWith(
      fontFamily: AppFonts.geist,
      fontWeight: FontWeight.w800,
      height: AppBudgetCard.bigNumberLineHeight,
      color: color ?? colors.ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final unitStyle = textTheme.bodyMedium?.copyWith(
      fontFamily: AppFonts.geist,
      fontWeight: FontWeight.w500,
      color: colors.muted,
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text, style: numberStyle),
            if (unit case final unit?)
              TextSpan(text: ' $unit', style: unitStyle),
          ],
        ),
        maxLines: 1,
      ),
    );
  }
}

/// One muted line of a tile: an optional icon and a short text that ends
/// with an ellipsis when the tile is narrow.
class DiaryTileCaption extends StatelessWidget {
  /// Creates the caption [text].
  const new(this.text, {this.icon, this.color, super.key});

  /// The text.
  final String text;

  /// Icon before the text.
  final IconData? icon;

  /// Color of icon and text; muted by default.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? FoodLabelColors.of(context).muted;
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontFamily: AppFonts.geist, color: color);

    return Row(
      spacing: AppDashboard.captionGap,
      children: [
        if (icon case final icon?)
          Icon(icon, size: AppDashboard.captionIcon, color: color),
        Flexible(
          child: Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
