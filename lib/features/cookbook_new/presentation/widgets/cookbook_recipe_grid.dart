import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_recipe_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Recipes in two columns; each row is as tall as its taller card.
class CookbookRecipeGrid extends StatelessWidget {
  /// Creates the grid of [recipes].
  const new({required this.recipes, required this.onOpen, super.key});

  /// The recipes with their stock flags.
  final List<CookbookEntry> recipes;

  /// Opens a recipe.
  final ValueChanged<CookbookEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.cookbookRecipesEmpty,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: FoodLabelColors.of(context).muted),
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
    return CookbookRecipeCard(entry: entry, onOpen: () => onOpen(entry));
  }
}
