import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_action_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Mahlzeit" card of a meal's detail page: edit, recipe, weight, unbundle
/// and throw away. A null callback disables its line, for example while an
/// action runs.
class EatMealActionsCard extends StatelessWidget {
  /// Creates the card for [meal].
  const new({
    required this.meal,
    required this.onEdit,
    required this.onSaveTemplate,
    required this.onChangeWeight,
    required this.onUnbundle,
    required this.onThrowAway,
    super.key,
  });

  /// Key of the action that weighs the food again.
  static const weightKey = Key('eat_meal_action_weight');

  /// The meal as the Vorrat holds it now.
  final PreparedMeal meal;

  /// Opens the meal's editor.
  final VoidCallback? onEdit;

  /// Saves the meal as a cookbook recipe.
  final VoidCallback? onSaveTemplate;

  /// Weighs the food again.
  final VoidCallback? onChangeWeight;

  /// Puts the ingredients back into the Vorrat.
  final VoidCallback? onUnbundle;

  /// Throws portions away. Disabled once the meal is eaten up.
  final VoidCallback? onThrowAway;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);

    return EatActionCard(
      title: l10n.eatPageMealTitle,
      actions: [
        (
          key: const Key('eat_meal_action_edit'),
          icon: Icons.edit_outlined,
          label: l10n.inventoryReceiptReviewEditAction,
          color: colors.ink,
          onPressed: onEdit,
        ),
        (
          key: const Key('eat_meal_action_save_template'),
          icon: Icons.bookmark_add_outlined,
          label: l10n.preparedMealSaveTemplateAction,
          color: colors.ink,
          onPressed: onSaveTemplate,
        ),
        // Pieces, a pot and an eaten-up meal have no weight to change.
        if (meal.allows(PreparedMealAction.changeWeight))
          (
            key: weightKey,
            icon: Icons.scale_outlined,
            label: l10n.preparedMealWeightAction,
            color: colors.ink,
            onPressed: onChangeWeight,
          ),
        (
          key: const Key('eat_meal_action_unbundle'),
          icon: Icons.call_split_rounded,
          label: l10n.preparedMealUnbundleAction,
          color: colors.ink,
          onPressed: onUnbundle,
        ),
        (
          key: const Key('eat_meal_action_throw_away'),
          icon: Icons.delete_outline_rounded,
          label: l10n.inventoryItemThrowAwayAction,
          color: colors.low,
          onPressed: meal.isDepleted ? null : onThrowAway,
        ),
      ],
    );
  }
}
