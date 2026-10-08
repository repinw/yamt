import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_chip.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Row of the eat page with a label and a count between a minus and a plus
/// button, such as the portions of a meal.
class EatCountRow extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.label,
    required this.count,
    required this.decreaseTooltip,
    required this.increaseTooltip,
    required this.onDecrease,
    required this.onIncrease,
    this.decreaseKey,
    this.increaseKey,
    this.valueKey,
    super.key,
  });

  /// Text before the count.
  final String label;

  /// Current count, such as 2 or 1.5.
  final num count;

  /// Tooltip of the minus button.
  final String decreaseTooltip;

  /// Tooltip of the plus button.
  final String increaseTooltip;

  /// Called by the minus button, or null when the count cannot drop.
  final VoidCallback? onDecrease;

  /// Called by the plus button; null leaves the button without effect.
  final VoidCallback? onIncrease;

  /// Key of the minus button.
  final Key? decreaseKey;

  /// Key of the plus button.
  final Key? increaseKey;

  /// Key of the count.
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      spacing: AppSpacing.md,
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: colors.ink),
          ),
        ),
        Tooltip(
          message: decreaseTooltip,
          child: EatChip(
            key: decreaseKey,
            label: '−',
            isSelected: false,
            onPressed: onDecrease,
          ),
        ),
        Text(
          formatEatCount(AppLocalizations.of(context)!, count),
          key: valueKey,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.ink,
          ),
        ),
        Tooltip(
          message: increaseTooltip,
          child: EatChip(
            key: increaseKey,
            label: '+',
            isSelected: false,
            onPressed: onIncrease,
          ),
        ),
      ],
    );
  }
}
