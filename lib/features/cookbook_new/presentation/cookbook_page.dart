import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/core/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_estimates_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/'
    'cookbook_remove_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_editor_route_args.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_idea_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_link_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_plan_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_sections.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'new_recipe_sheet.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_template_create_flow.dart';
import 'package:yamt/features/inventory/presentation/'
    'prepared_meal_detail_flow.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensils_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Kochbuch tab: meals still in the pot, Vorlagen combined from the Vorrat,
/// and recipes with the stock state of their ingredients.
class CookbookPage extends ConsumerWidget {
  /// Creates the Kochbuch page.
  const new({super.key});

  /// Key of the retry button after a load failure.
  static const retryKey = ValueKey<String>('cookbook-retry');

  /// Key of the header tool that opens "Neues Rezept".
  static const newRecipeKey = ValueKey<String>('cookbook-new-recipe');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = cookbookControllerProvider(l10n.localeName);
    final overviewAsync = ref.watch(provider);
    final recipeCount = overviewAsync.asData?.value.recipes.length;
    final estimating = ref.watch(recipeEstimatesControllerProvider);

    final body = overviewAsync.when(
      data: (overview) => SliverToBoxAdapter(
        child: CookbookSections(
          overview: overview,
          estimating: estimating,
          onContinueMeal: (meal) => unawaited(
            meal.isInPot
                ? context.push(AppRoutes.homeCookedMealPath(meal.id))
                : PreparedMealDetailFlow.open(
                    context: context,
                    ref: ref,
                    meal: meal,
                  ),
          ),
          onCreateTemplate: () => unawaited(
            InventoryTemplateCreateFlow.create(context: context, ref: ref),
          ),
          onAddRecipe: () => unawaited(_newRecipe(context, ref)),
          onOpenTemplate: (template) =>
              unawaited(context.push(AppRoutes.homeRecipePath(template.id))),
          onOpenRecipe: (recipe) =>
              unawaited(context.push(AppRoutes.homeRecipePath(recipe.id))),
          onRemove: (template) =>
              unawaited(CookbookRemoveFlow.remove(context, template: template)),
          onPlan: (template) => unawaited(
            RecipePlanFlow.plan(
              context: context,
              ref: ref,
              recipeId: template.id,
            ),
          ),
        ),
      ),
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: AppLoadingView(),
      ),
      error: (error, stackTrace) => SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorRetryView(
          retryButtonKey: retryKey,
          message: l10n.cookbookLoadFailed,
          retryLabel: l10n.inventoryRetryAction,
          onRetry: () => ref.read(provider.notifier).retry(),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          HomeShellTabTopChrome(
            title: l10n.homeCookbook,
            kicker: recipeCount == null
                ? null
                : l10n.cookbookRecipeCount(recipeCount),
            tools: [
              HomeHeaderTool(
                key: newRecipeKey,
                symbol: const Icon(Icons.add_rounded),
                label: l10n.cookbookNewTool,
                onPressed: () => unawaited(_newRecipe(context, ref)),
              ),
              const KitchenUtensilsButton(),
            ],
          ),
          body,
        ],
      ),
    );
  }

  /// Asks how the new recipe starts and starts it.
  static Future<void> _newRecipe(BuildContext context, WidgetRef ref) async {
    final choice = await NewRecipeSheet.show(context);
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case NewRecipeChoice.scan:
        _openEditor(context, RecipeEditorStart.scan);
      case NewRecipeChoice.paste:
        _openEditor(context, RecipeEditorStart.paste);
      case NewRecipeChoice.type:
        _openEditor(context, RecipeEditorStart.blank);
      case NewRecipeChoice.link:
        unawaited(RecipeLinkFlow.start(context, ref));
      case NewRecipeChoice.ai:
        unawaited(RecipeIdeaFlow.start(context));
    }
  }

  static void _openEditor(BuildContext context, RecipeEditorStart start) =>
      unawaited(
        context.push(
          AppRoutes.homeRecipeNew,
          extra: RecipeEditorRouteArgs(start: start),
        ),
      );
}
