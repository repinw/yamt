import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_count_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Row of the hub's meal view to say how many portions the picked foods
/// make. The count never drops below one.
class EatMealPortionsRow extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.portions,
    required this.onChanged,
    this.max,
    super.key,
  });

  /// Key of the button that takes one portion away.
  static const decreaseKey = Key('eat_meal_portions_decrease');

  /// Key of the button that adds one portion.
  static const increaseKey = Key('eat_meal_portions_increase');

  /// Current number of portions, at least one.
  final int portions;

  /// Called with the new number of portions.
  final ValueChanged<int> onChanged;

  /// Largest number of portions, or null without a limit.
  final int? max;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EatCountRow(
      label: l10n.eatPageMealPortions,
      count: portions,
      decreaseTooltip: l10n.inventoryItemEatSheetDecreasePortionCountAction,
      increaseTooltip: l10n.inventoryItemEatSheetIncreasePortionCountAction,
      onDecrease: portions > 1 ? () => onChanged(portions - 1) : null,
      onIncrease: max != null && portions >= max!
          ? null
          : () => onChanged(portions + 1),
      decreaseKey: decreaseKey,
      increaseKey: increaseKey,
      valueKey: const Key('eat_meal_portions_value'),
    );
  }
}
