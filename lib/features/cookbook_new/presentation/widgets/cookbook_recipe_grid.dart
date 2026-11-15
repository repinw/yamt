import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_recipe_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Recipes in two columns; each row is as tall as its taller card. Without
/// recipes, the ways to add one and "Rezept hinzufügen".
class CookbookRecipeGrid extends StatelessWidget {
  /// Creates the grid of [recipes].
  const new({
    required this.recipes,
    required this.onAdd,
    required this.onOpen,
    required this.onRemove,
    required this.onPlan,
    this.estimating = const {},
    super.key,
  });

  /// The recipes with their stock flags.
  final List<CookbookEntry> recipes;

  /// Key of "Rezept hinzufügen" while there is no recipe.
  static const addKey = ValueKey<String>('cookbook-recipes-add');

  /// Ids of the recipes whose estimate is running or waiting for its turn.
  final Set<String> estimating;

  /// Opens "Neues Rezept".
  final VoidCallback onAdd;

  /// Opens a recipe.
  final ValueChanged<CookbookEntry> onOpen;

  /// Removes a recipe.
  final ValueChanged<CookbookEntry> onRemove;

  /// Plans one portion of an entry for a day.
  final ValueChanged<CookbookEntry> onPlan;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.md,
        children: [
          Text(
            l10n.cookbookRecipesEmpty,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: FoodLabelColors.of(context).muted),
          ),
          FilledButton.icon(
            key: addKey,
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.cookbookRecipesAdd),
          ),
        ],
      );
    }
    return Column(
      spacing: AppSpacing.xl,
      children: [
        for (var index = 0; index < recipes.length; index += 2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.md,
            children: [
              Expanded(child: _card(recipes[index])),
              Expanded(
                child: index + 1 < recipes.length
                    ? _card(recipes[index + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _card(CookbookEntry entry) {
    return CookbookRecipeCard(
      key: CookbookRecipeCard.cardKey(entry.meal.id),
      entry: entry,
      isEstimating: estimating.contains(entry.meal.id),
      onOpen: () => onOpen(entry),
      onRemove: () => onRemove(entry),
      onPlan: () => onPlan(entry),
    );
  }
}
