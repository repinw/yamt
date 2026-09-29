import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_open_meal_card.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_recipe_grid.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_section_title.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_template_strip.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Sections of the Kochbuch: "Im Topf" when meals have open rows, the
/// Vorlagen strip, and the recipe grid.
class CookbookSections extends StatelessWidget {
  /// Creates the sections of [overview].
  const new({
    required this.overview,
    required this.onContinueMeal,
    required this.onCreateTemplate,
    required this.onOpenTemplate,
    super.key,
  });

  /// What the Kochbuch shows.
  final CookbookOverview overview;

  /// Opens a meal that still has open rows.
  final ValueChanged<PreparedMeal> onContinueMeal;

  /// Starts combining a new Vorlage.
  final VoidCallback onCreateTemplate;

  /// Opens a Vorlage or a recipe.
  final ValueChanged<PreparedMeal> onOpenTemplate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final horizontal = responsivePageHorizontalPadding(context);
    final inset = EdgeInsets.symmetric(horizontal: horizontal);

    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        bottom: homeShellPageBottomPadding(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xxl,
        children: [
          if (overview.openMeals.isNotEmpty)
            Padding(
              padding: inset,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.xs,
                children: [
                  CookbookSectionTitle(title: l10n.cookbookOpenMealsTitle),
                  for (final meal in overview.openMeals)
                    CookbookOpenMealCard(
                      meal: meal,
                      onContinue: () => onContinueMeal(meal),
                    ),
                ],
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              Padding(
                padding: inset,
                child: CookbookSectionTitle(
                  title: l10n.cookbookTemplatesTitle,
                  caption: l10n.cookbookTemplatesCaption,
                ),
              ),
              CookbookTemplateStrip(
                templates: overview.templates,
                horizontalPadding: horizontal,
                onCreate: onCreateTemplate,
                onOpen: (entry) => onOpenTemplate(entry.meal),
              ),
            ],
          ),
          Padding(
            padding: inset,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: [
                CookbookSectionTitle(title: l10n.cookbookRecipesTitle),
                CookbookRecipeGrid(
                  recipes: overview.recipes,
                  onOpen: (entry) => onOpenTemplate(entry.meal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
