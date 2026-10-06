import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_components_list.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The top of the "Gekocht" step: the meal's name, its ingredients with
/// amounts and kcal, and its open rows with "Füllen".
class CookedMealSummary extends StatelessWidget {
  /// Creates the summary of [meal].
  const new({required this.meal, required this.onFill, super.key});

  /// Key of the button that fills the open rows.
  static const fillKey = ValueKey<String>('cooked-fill');

  /// The meal in the pot.
  final PreparedMeal meal;

  /// Opens the meal to fill its open rows.
  final VoidCallback onFill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final openRows = meal.pendingRecipeIngredients.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          meal.name,
          style: textTheme.headlineSmall?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (meal.components.isNotEmpty)
          EatComponentsList(
            initiallyExpanded: true,
            components: [
              for (final component in meal.components)
                (
                  name: component.name,
                  amount: eatComponentAmount(
                    l10n,
                    preparedMealComponentDisplayAmount(component),
                    component.usedUnit,
                  ),
                  kcal: component.totalKcal,
                ),
            ],
          ),
        if (openRows > 0)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.cookedOpenRows(openRows),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.low,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                key: fillKey,
                onPressed: onFill,
                child: Text(l10n.cookedFillRows),
              ),
            ],
          ),
      ],
    );
  }
}
