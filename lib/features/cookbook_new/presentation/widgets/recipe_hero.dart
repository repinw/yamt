import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cookbook_meal_picture.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// The top of the recipe page: the recipe photo with its source and name
/// over the lower edge, and the back button on it. Text over a photo needs
/// the dark palette in both themes.
class RecipeHero extends StatelessWidget {
  /// Creates the header of [recipe].
  const new({required this.recipe, super.key});

  /// The recipe.
  final PreparedMeal recipe;

  @override
  Widget build(BuildContext context) {
    const photo = FoodLabelColors.dark;
    final textTheme = Theme.of(context).textTheme;
    final source = switch (Uri.tryParse(recipe.recipeUrl ?? '')?.host) {
      final host? when host.isNotEmpty => host.replaceFirst('www.', ''),
      _ => null,
    };

    final top = MediaQuery.paddingOf(context).top;
    // The photo is at least the hero height and grows with a long name or
    // large text; the name stays below the back button.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: AppGraphit.recipeHeroHeight + top),
      child: Stack(
        alignment: AlignmentDirectional.bottomStart,
        children: [
          Positioned.fill(child: CookbookMealPicture(meal: recipe)),
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
              ],
            ),
          ),
          Positioned(
            top: top + AppSpacing.sm,
            left: AppSpacing.sm,
            child: IconButton.filled(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              style: IconButton.styleFrom(
                backgroundColor: photo.paper.withValues(
                  alpha: AppGraphit.photoButtonOpacity,
                ),
                foregroundColor: photo.ink,
              ),
              onPressed: () => context.pop(),
              icon: const BackButtonIcon(),
            ),
          ),
        ],
      ),
    );
  }
}
