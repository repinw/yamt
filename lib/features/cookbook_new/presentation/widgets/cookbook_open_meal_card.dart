import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_meal_picture.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Framed card of a meal that is still in the pot or has open rows: its
/// picture, its name, where it is and how many rows are open, and "Weiter"
/// back to the pot or "Füllen" for a meal already in the Vorrat.
class CookbookOpenMealCard extends ConsumerWidget {
  /// Creates the card for [meal].
  const new({required this.meal, required this.onContinue, super.key});

  /// The meal in the pot or with open rows.
  final PreparedMeal meal;

  /// Opens the pot, or the meal to fill its open rows.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final localizations = MaterialLocalizations.of(context);
    final created = meal.createdAt.toLocal();
    // A pot can stay open for days; then the day says more than the time.
    final since = DateUtils.isSameDay(created, ref.watch(clockProvider)())
        ? localizations.formatTimeOfDay(TimeOfDay.fromDateTime(created))
        : localizations.formatShortMonthDay(created);
    final openRows = meal.pendingRecipeIngredients.length;
    final status = !meal.isInPot
        ? l10n.cookbookOpenMealRows(openRows)
        : openRows > 0
        ? l10n.cookbookInPotOpenRows(openRows, since)
        : l10n.cookbookInPotSince(since);

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
                    status,
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
              child: Text(
                meal.isInPot
                    ? l10n.cookbookContinueAction
                    : l10n.cookedFillRows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
