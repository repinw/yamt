import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_meal_picture.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_stock_line.dart';

/// Recipe in the Kochbuch grid: square picture, name, and the stock line of
/// its ingredients.
class CookbookRecipeCard extends StatelessWidget {
  /// Creates the card for [entry].
  const new({required this.entry, required this.onOpen, super.key});

  /// The recipe with its stock flags.
  final CookbookEntry entry;

  /// Opens the recipe.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return AppInkWell(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          SizedBox(
            height: AppGraphit.recipeCardPicture,
            child: CookbookMealPicture(meal: entry.meal),
          ),
          Text(
            entry.meal.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: colors.ink, fontWeight: FontWeight.w800),
          ),
          if (entry.inStock.isNotEmpty) CookbookStockLine(entry: entry),
        ],
      ),
    );
  }
}
