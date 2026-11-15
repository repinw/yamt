import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/cookbook_new/domain/cookbook_overview.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_recipe_grid.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_running_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_section_title.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_template_strip.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Sections of the Kochbuch: "Läuft" when cook runs are running or old meals
/// are in the pot or have open rows, the Vorlagen strip, and the recipe grid.
class CookbookSections extends StatelessWidget {
  /// Creates the sections of [overview].
  const new({
    required this.overview,
    required this.onContinueMeal,
    required this.onCreateTemplate,
    required this.onAddRecipe,
    required this.onOpenTemplate,
    required this.onOpenRecipe,
    required this.onRemove,
    required this.onPlan,
    this.estimating = const {},
    super.key,
  });

  /// What the Kochbuch shows.
  final CookbookOverview overview;

  /// Ids of the recipes whose estimate is running or waiting for its turn.
  final Set<String> estimating;

  /// Opens an old meal that is in the pot or still has open rows.
  final ValueChanged<PreparedMeal> onContinueMeal;

  /// Starts combining a new Vorlage.
  final VoidCallback onCreateTemplate;

  /// Opens "Neues Rezept".
  final VoidCallback onAddRecipe;

  /// Opens a Vorlage.
  final ValueChanged<PreparedMeal> onOpenTemplate;

  /// Opens the recipe page of a recipe.
  final ValueChanged<PreparedMeal> onOpenRecipe;

  /// Removes a Vorlage or recipe from the Kochbuch.
  final ValueChanged<PreparedMeal> onRemove;

  /// Plans one portion of a Vorlage or recipe for a day.
  final ValueChanged<PreparedMeal> onPlan;

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
          if (overview.runs.isNotEmpty || overview.openMeals.isNotEmpty)
            Padding(
              padding: inset,
              child: CookbookRunningSection(
                runs: overview.runs,
                openMeals: overview.openMeals,
                onContinueMeal: onContinueMeal,
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
                onRemove: (entry) => onRemove(entry.meal),
                onPlan: (entry) => onPlan(entry.meal),
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
                  estimating: estimating,
                  recipes: overview.recipes,
                  onAdd: onAddRecipe,
                  onOpen: (entry) => onOpenRecipe(entry.meal),
                  onRemove: (entry) => onRemove(entry.meal),
                  onPlan: (entry) => onPlan(entry.meal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
