import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/macro_grams.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_planned_nutrition.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_entry_ink_well.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_meal_picture.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_stock_line.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Recipe in the Kochbuch grid: square picture, name, the AI's kcal and
/// macros per portion, and the lines its cook run assigned by hand. A tap
/// opens the recipe page.
class CookbookRecipeCard extends ConsumerWidget {
  /// Creates the card for [entry].
  const new({
    required this.entry,
    required this.onOpen,
    required this.onRemove,
    required this.onPlan,
    this.isEstimating = false,
    super.key,
  });

  /// Key of the card of the recipe [id].
  static ValueKey<String> cardKey(String id) =>
      ValueKey<String>('cookbook-recipe-$id');

  /// Key of the indicator that the estimate of the recipe [id] is coming.
  static ValueKey<String> estimatingKey(String id) =>
      ValueKey<String>('cookbook-recipe-estimating-$id');

  /// Key of the estimate line of the recipe [id].
  static ValueKey<String> estimateKey(String id) =>
      ValueKey<String>('cookbook-recipe-estimate-$id');

  /// The recipe with its stock flags.
  final CookbookEntry entry;

  /// Opens the recipe.
  final VoidCallback onOpen;

  /// Removes the recipe.
  final VoidCallback onRemove;

  /// Plans one portion of the recipe for a day.
  final VoidCallback onPlan;

  /// Whether the recipe's estimate is running or waiting for its turn; a
  /// small spinner stands where the estimate will be.
  final bool isEstimating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    // Two lines are kept for every name and two for the estimate, so the
    // lines of a grid row line up and a card keeps its height when the
    // estimate arrives.
    final titleStyle = textTheme.titleSmall!.copyWith(
      color: colors.ink,
      fontWeight: FontWeight.w800,
      height: _titleLineHeight,
    );
    final titleHeight =
        MediaQuery.textScalerOf(context).scale(titleStyle.fontSize!) *
        _titleLineHeight *
        2;
    return CookbookEntryInkWell(
      onOpen: onOpen,
      onRemove: onRemove,
      onPlan: onPlan,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(
            color: colors.rule,
            width: AppFoodLabel.chipOutline,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow
                  .withValues(alpha: AppGraphit.recipeCardShadowAlpha),
              blurRadius: AppGraphit.recipeCardShadowBlur,
              offset: const Offset(0, AppGraphit.recipeCardShadowOffset),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: AppGraphit.recipeCardPicture,
              child: CookbookMealPicture(meal: entry.meal),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.xs,
                children: [
                  SizedBox(
                    // Fixed, so one and two lines of a name end the same.
                    height: titleHeight.ceilToDouble(),
                    child: Text(
                      entry.meal.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                      strutStyle: StrutStyle.fromTextStyle(
                        titleStyle,
                        forceStrutHeight: true,
                      ),
                    ),
                  ),
                  _CardEstimate(
                    key: estimateKey(entry.meal.id),
                    portion: ref.watch(recipePortionProvider(entry.meal.id)),
                    isEstimating: isEstimating,
                    estimatingKey: estimatingKey(entry.meal.id),
                  ),
                  if (entry.inStock.isNotEmpty) CookbookStockLine(entry: entry),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _titleLineHeight = 1.25;

// One line of [text] that keeps its height while [text] is empty.
Widget _line(String text, TextStyle style) => Text(
  text,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: style,
  strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: true),
);

// The AI's kcal and macros per portion, the macro numbers in their colors,
// two lines that keep their height until [portion] comes, with a small
// spinner while [isEstimating]. While cooking, each planned line brings its
// real values, and with every line planned there is no "≈".
class _CardEstimate extends StatelessWidget {
  const new({
    required this.portion,
    required this.isEstimating,
    required this.estimatingKey,
    super.key,
  });

  final RecipePortion? portion;
  final bool isEstimating;
  final Key estimatingKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final portion = this.portion;
    final estimate = portion?.values;
    final kcalStyle = textTheme.labelLarge!.copyWith(color: colors.ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (estimate == null && isEstimating)
          _Estimating(key: estimatingKey, style: kcalStyle, color: colors.muted)
        else
          _line(
            estimate == null
                ? ''
                : portion!.estimated
                ? l10n.cookbookCardEstimate(estimate.kcal.round())
                : l10n.cookbookCardKcal(estimate.kcal.round()),
            kcalStyle,
          ),
        if (estimate == null)
          _line(
            '',
            textTheme.labelSmall!.copyWith(
              color: colors.muted,
              fontFamily: AppFonts.mono,
            ),
          )
        else
          MacroGrams.line(
            protein: estimate.protein,
            carbs: estimate.carbs,
            fat: estimate.fat,
          ),
      ],
    );
  }
}

// A small spinner in a line of [style], where the kcal will stand.
class _Estimating extends StatelessWidget {
  const new({required this.style, required this.color, super.key});

  final TextStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height:
        MediaQuery.textScalerOf(context).scale(style.fontSize!) *
        (style.height ?? 1),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox.square(
        dimension: AppGraphit.recipeCardSpinner,
        child: CircularProgressIndicator(
          strokeWidth: AppGraphit.recipeCardSpinnerStroke,
          color: color,
        ),
      ),
    ),
  );
}
