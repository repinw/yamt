import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_chip.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Row of the hub's meal view to say how many portions the picked foods
/// make. The count never drops below one.
class EatMealPortionsRow extends StatelessWidget {
  /// Creates the row.
  const new({required this.portions, required this.onChanged, super.key});

  /// Key of the button that takes one portion away.
  static const decreaseKey = Key('eat_meal_portions_decrease');

  /// Key of the button that adds one portion.
  static const increaseKey = Key('eat_meal_portions_increase');

  /// Current number of portions, at least one.
  final int portions;

  /// Called with the new number of portions.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      spacing: AppSpacing.md,
      children: [
        Expanded(
          child: Text(
            l10n.eatPageMealPortions,
            style: textTheme.bodySmall?.copyWith(
              fontFamily: AppFonts.mono,
              color: colors.ink,
            ),
          ),
        ),
        Tooltip(
          message: l10n.inventoryItemEatSheetDecreasePortionCountAction,
          child: EatChip(
            key: decreaseKey,
            label: '−',
            isSelected: false,
            onPressed: portions > 1 ? () => onChanged(portions - 1) : () {},
          ),
        ),
        Text(
          '$portions',
          key: const Key('eat_meal_portions_value'),
          style: textTheme.titleMedium?.copyWith(
            fontFamily: AppFonts.mono,
            fontWeight: FontWeight.w700,
            color: colors.ink,
          ),
        ),
        Tooltip(
          message: l10n.inventoryItemEatSheetIncreasePortionCountAction,
          child: EatChip(
            key: increaseKey,
            label: '+',
            isSelected: false,
            onPressed: () => onChanged(portions + 1),
          ),
        ),
      ],
    );
  }
}
