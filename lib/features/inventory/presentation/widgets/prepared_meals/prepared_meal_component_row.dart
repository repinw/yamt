import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/formatters/inventory_nutrition_format.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/prepared_meal_component_avatar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One bound ingredient of a prepared meal with its amount.
class PreparedMealComponentRow extends StatelessWidget {
  /// Creates the row for [component] showing [amount] of it.
  const new({required this.component, required this.amount, super.key});

  /// The bound ingredient.
  final PreparedMealComponent component;

  /// Amount to show, in the unit of [component].
  final double amount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        PreparedMealComponentAvatar(
          key: Key(
            'prepared_meal_ingredient_avatar_${component.inventoryItemId}',
          ),
          label: component.name,
          imageUrl: component.imageUrl,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(component.name)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          l10n.inventoryEatSheetAmountWithUnit(
            formatInventoryNutritionValue(amount),
            component.usedUnit.localizedName(l10n),
          ),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
