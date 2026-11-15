import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_planned_nutrition.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cookbook_meal_picture.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_estimate_line.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The top of the recipe page: the recipe photo with its source, name, and
/// estimate per portion (or that it is being made) over the lower edge, and
/// the back, "Planen",
/// "Bearbeiten", and "Entfernen" buttons on it. Text over a photo needs the
/// dark palette in both themes, so the plain background under a missing
/// photo is dark too; without a picture the header is only as tall as its
/// text and buttons.
class RecipeHero extends StatelessWidget {
  /// Creates the header of [recipe].
  const new({
    required this.recipe,
    required this.onRemove,
    this.onEdit,
    this.editKey,
    this.portion,
    this.isEstimating = false,
    super.key,
  });

  /// Key of the "Planen" button.
  static const planKey = ValueKey<String>('recipe-plan');

  /// Key of the "Entfernen" button.
  static const removeKey = ValueKey<String>('recipe-remove');

  /// The recipe.
  final PreparedMeal recipe;

  /// Removes the recipe from the Kochbuch; `null` turns the button off.
  final VoidCallback? onRemove;

  /// Opens the recipe editor; `null` hides "Bearbeiten".
  final VoidCallback? onEdit;

  /// Key of "Bearbeiten".
  final Key? editKey;

  /// One portion ([recipePortionProvider]), shown under the name.
  final RecipePortion? portion;

  /// Whether the estimate is being made; without a [portion], the header
  /// says so in its place.
  final bool isEstimating;

  @override
  Widget build(BuildContext context) {
    const photo = FoodLabelColors.dark;
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final buttonStyle = IconButton.styleFrom(
      backgroundColor: photo.paper.withValues(
        alpha: AppGraphit.photoButtonOpacity,
      ),
      foregroundColor: photo.ink,
      disabledBackgroundColor: photo.paper.withValues(
        alpha: AppGraphit.photoButtonOpacity,
      ),
      disabledForegroundColor: photo.muted,
    );
    final source = switch (Uri.tryParse(recipe.recipeUrl ?? '')?.host) {
      final host? when host.isNotEmpty => host.replaceFirst('www.', ''),
      _ => null,
    };

    final top = MediaQuery.paddingOf(context).top;
    final hasPicture =
        recipe.imageAssetId != null ||
        (recipe.imageUrl?.isNotEmpty ?? false) ||
        recipe.components.any((component) => component.imageUrl != null);
    // The photo is at least the hero height and grows with a long name or
    // large text; the name stays below the back button.
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: hasPicture ? AppGraphit.recipeHeroHeight + top : 0,
      ),
      child: Stack(
        alignment: AlignmentDirectional.bottomStart,
        children: [
          // The name stands large on the picture, so no initial under it.
          Positioned.fill(
            child: CookbookMealPicture(
              meal: recipe,
              showInitial: false,
              background: photo.card,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    photo.paper.withValues(alpha: 0),
                    photo.paper.withValues(alpha: AppGraphit.photoScrimOpacity),
                  ],
                  stops: const [0.35, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              top + AppSpacing.sm * 2 + kMinInteractiveDimension,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs,
              children: [
                if (source != null)
                  Text(
                    source.toUpperCase(),
                    style: textTheme.labelMedium?.copyWith(
                      color: photo.muted,
                      letterSpacing: AppGraphit.kickerTracking,
                    ),
                  ),
                Text(
                  recipe.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineMedium?.copyWith(
                    color: photo.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (portion case final portion?)
                  RecipeEstimateLine(portion: portion, palette: photo)
                else if (isEstimating)
                  const RecipeEstimateLine.waiting(palette: photo),
              ],
            ),
          ),
          Positioned(
            top: top + AppSpacing.sm,
            left: AppSpacing.sm,
            child: IconButton.filled(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              style: buttonStyle,
              onPressed: () => context.pop(),
              icon: const BackButtonIcon(),
            ),
          ),
          Positioned(
            top: top + AppSpacing.sm,
            right: AppSpacing.sm,
            child: Row(
              spacing: AppSpacing.sm,
              children: [
                // Planning from the page is not built yet; the Kochbuch
                // card's long press plans.
                IconButton.filled(
                  key: planKey,
                  tooltip: l10n.eatPagePlanIconTooltip,
                  style: buttonStyle,
                  onPressed: null,
                  icon: const Icon(Icons.event_rounded),
                ),
                if (onEdit case final onEdit?)
                  IconButton.filled(
                    key: editKey,
                    tooltip: l10n.recipeEditorEdit,
                    style: buttonStyle,
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                IconButton.filled(
                  key: removeKey,
                  tooltip: l10n.cookbookRemoveAction,
                  style: buttonStyle,
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
