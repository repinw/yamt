import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_cook_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cookbook_section_title.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/portion_stepper.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_bottom_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_check_card.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_hero.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_ingredient_tile.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_step_list.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_stock_picker_sheet.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A saved recipe: its photo and name, the portions to cook, the
/// ingredients with the Vorrat items that supply them, and the steps.
/// "Kochen" puts the meal in the pot and goes on to the "Gekocht" step,
/// after the Kochhelfer when "Mit Anleitung kochen" is on.
class RecipePage extends ConsumerWidget {
  /// Creates the page of the recipe [recipeId].
  const new({required this.recipeId, super.key});

  /// Key of the "Kochen" button.
  static const cookKey = ValueKey<String>('recipe-cook');

  /// Key of the "Mit Anleitung kochen" checkbox.
  static const withGuideKey = ValueKey<String>('recipe-with-guide');

  /// Key of the portion count.
  static const portionsKey = ValueKey<String>('recipe-portions');

  /// Key of the button that adds a portion.
  static const morePortionsKey = ValueKey<String>('recipe-portions-more');

  /// Key of the retry button after a load failure.
  static const retryKey = ValueKey<String>('recipe-retry');

  /// Key of the note that the recipe is gone.
  static const notFoundKey = ValueKey<String>('recipe-not-found');

  /// The saved recipe.
  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final viewAsync = ref.watch(recipeViewProvider(recipeId, l10n.localeName));
    final (:isCooking, :withGuide) = ref.watch(
      recipeControllerProvider(recipeId).select(
        (draft) => (isCooking: draft.isCooking, withGuide: draft.withGuide),
      ),
    );

    return Scaffold(
      backgroundColor: colors.paper,
      body: viewAsync.when(
        data: (view) => view == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Text(
                    l10n.recipeNotFound,
                    key: notFoundKey,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : _RecipeBody(
                view: view,
                isCooking: isCooking,
                withGuide: withGuide,
              ),
        error: (_, _) => AppErrorRetryView(
          retryButtonKey: retryKey,
          message: l10n.recipeLoadFailed,
          retryLabel: l10n.inventoryRetryAction,
          onRetry: () => ref
            ..invalidate(cookbookTemplatesProvider)
            ..invalidate(inventoryQuickEatItemsProvider),
        ),
        loading: () => const AppLoadingView(),
      ),
    );
  }
}

class _RecipeBody extends ConsumerWidget {
  const new({
    required this.view,
    required this.isCooking,
    required this.withGuide,
  });

  final RecipeView view;
  final bool isCooking;
  final bool withGuide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final recipe = view.recipe;
    final provider = recipeControllerProvider(recipe.id);
    final activeCount = view.activeLines.length;
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.xl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              RecipeHero(recipe: recipe),
              if (activeCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    0,
                  ),
                  child: RecipeCheckCard(
                    recipeId: recipe.id,
                    onOpen: () => unawaited(
                      context.push(AppRoutes.homeRecipeCheckPath(recipe.id)),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.cookedPortions,
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.ink,
                            ),
                          ),
                          Text(
                            l10n.recipeOriginalPortions(view.basePortions),
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PortionStepper(
                      count: view.portions,
                      onChanged: (count) =>
                          ref.read(provider.notifier).setPortions(count),
                      lessTooltip: l10n.cookedPortionsLess,
                      moreTooltip: l10n.cookedPortionsMore,
                      countKey: RecipePage.portionsKey,
                      moreKey: RecipePage.morePortionsKey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: inset,
                child: CookbookSectionTitle(
                  title: l10n.freeCookingIngredientsTitle,
                  caption: l10n.freeCookingStockCount(
                    view.inStockCount,
                    activeCount,
                  ),
                ),
              ),
              for (final (index, line) in view.lines.indexed)
                Padding(
                  padding: inset,
                  child: RecipeIngredientTile(
                    key: RecipeIngredientTile.tileKey(index),
                    line: line,
                    onTap: line.candidates.isEmpty
                        ? null
                        : () => unawaited(_pick(context, ref, line)),
                  ),
                ),
              if (recipe.recipeInstructions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: inset,
                  child: CookbookSectionTitle(
                    title: l10n.recipeStepsTitle,
                    caption: l10n.recipeStepCount(
                      recipe.recipeInstructions.length,
                    ),
                  ),
                ),
                RecipeStepList(steps: recipe.recipeInstructions),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
        RecipeBottomBar(
          header: view.hasSteps
              ? AppCheckboxListTile(
                  key: RecipePage.withGuideKey,
                  value: withGuide,
                  onChanged: isCooking
                      ? null
                      : (value) => ref
                            .read(provider.notifier)
                            .setWithGuide(withGuide: value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l10n.recipeWithGuide),
                  subtitle: Text(l10n.recipeWithGuideHint),
                )
              : null,
          buttonKey: RecipePage.cookKey,
          label: l10n.freeCookingCookAction,
          onPressed: isCooking || activeCount == 0
              ? null
              : () => unawaited(_cook(context, ref)),
        ),
      ],
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    RecipeIngredientLine line,
  ) async {
    final pick = await showRecipeStockPicker(context: context, line: line);
    if (pick != null && context.mounted) {
      ref
          .read(recipeControllerProvider(view.recipe.id).notifier)
          .pick(line.key, pick.itemId);
    }
  }

  Future<void> _cook(BuildContext context, WidgetRef ref) async {
    final recipeId = view.recipe.id;
    if (!withGuide || !view.hasSteps) {
      await RecipeCookFlow.cook(context: context, ref: ref, recipeId: recipeId);
    } else if (ModalRoute.isCurrentOf(context) ?? false) {
      // A tap that reaches this page under the Kochhelfer does nothing.
      await context.push<void>(AppRoutes.homeRecipeGuidePath(recipeId));
    }
  }
}
