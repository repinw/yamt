import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
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
