import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_meal_picture.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Framed card of a meal that is still in the pot: its picture, its name,
/// how many rows are open since when, and "Weiter".
class CookbookOpenMealCard extends StatelessWidget {
  /// Creates the card for [meal].
  const new({required this.meal, required this.onContinue, super.key});

  /// The meal with open rows.
  final PreparedMeal meal;

  /// Opens the meal to fill its open rows.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final since = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(meal.createdAt.toLocal()));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.ink, width: AppFoodLabel.chipOutline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Transform.rotate(
              angle: AppFoodLabel.imageTilt,
              child: CookbookMealPicture(
                meal: meal,
                size: AppGraphit.buttonHeight,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xxs,
                children: [
                  Text(
                    meal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    meal.hasPendingRecipeIngredients
                        ? l10n.cookbookOpenMealRows(
                            meal.pendingRecipeIngredients.length,
                            since,
                          )
                        : l10n.cookbookInPotSince(since),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.low,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: onContinue,
              child: Text(l10n.cookbookContinueAction),
            ),
          ],
        ),
      ),
    );
  }
}
