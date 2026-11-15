import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_line_states.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_planned_nutrition.dart';
import 'package:yamt/features/cookbook_new/presentation/cookbook_remove_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_cook_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_async_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_bottom_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_hero.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_ingredient_tile.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_line_status_card.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_nutrition_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_portions_row.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_section_header.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_step_list.dart';
import 'package:yamt/features/recipes/application/cook_run_providers.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A saved recipe or Vorlage: photo, name, portions, ingredients and steps,
/// which "Bearbeiten" changes in the recipe editor. While it has a cook run,
/// a card and each ingredient show what is ready, on the shopping list, left
/// out, or open.
/// "Vorbereiten" and "Weiter" open "Zuweisen" while the cook run's lines
/// need assigning, "Kochen" and "Weiter" the cooking page after; a Vorlage's
/// "Kochen" puts it into the pot and goes on to "Gekocht".
/// Opening a recipe whose estimate does not fit its lines estimates it in
/// the background; until it comes, the header says that it is being made.
class RecipePage extends ConsumerStatefulWidget {
  /// Creates the page of the recipe [recipeId].
  const new({required this.recipeId, super.key});

  /// Key of the "Vorbereiten", "Weiter", or "Kochen" button.
  static const cookKey = ValueKey<String>('recipe-cook');

  /// Key of the portion count.
  static const portionsKey = ValueKey<String>('recipe-portions');

  /// Key of the button that adds a portion.
  static const morePortionsKey = ValueKey<String>('recipe-portions-more');

  /// Key of "Bearbeiten" on the photo.
  static const editKey = ValueKey<String>('recipe-edit');

  /// Key of the note that cooking needs every ingredient settled.
  static const openHintKey = ValueKey<String>('recipe-open-hint');

  /// Key of the retry button after a load failure.
  static const retryKey = ValueKey<String>('recipe-retry');

  /// Key of the note that the recipe is gone.
  static const notFoundKey = ValueKey<String>('recipe-not-found');

  /// The saved recipe.
  final String recipeId;

  @override
  ConsumerState<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends ConsumerState<RecipePage> {
  @override
  void initState() {
    super.initState();
    // Each version of the lines and portions the page shows is estimated
    // once; the header waits for it from the first frame.
    ref.listenManual(cookbookTemplatesProvider, (_, next) {
      final recipe = next.value?.firstWhereOrNull(
        (t) => t.id == widget.recipeId,
      );
      if (recipe != null) {
        ref
            .read(recipeControllerProvider(widget.recipeId).notifier)
            .estimateIfMissing(recipe);
      }
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final recipeId = widget.recipeId;
    final l10n = AppLocalizations.of(context)!;
    final viewAsync = ref.watch(recipeViewProvider(recipeId, l10n.localeName));
    final isCooking = ref.watch(
      recipeControllerProvider(recipeId).select((draft) => draft.isCooking),
    );
    final lineStates = ref.watch(recipeLineStatesProvider(recipeId));

    return Scaffold(
      backgroundColor: FoodLabelColors.of(context).paper,
      body: RecipeAsyncView(
        value: viewAsync,
        notFoundKey: RecipePage.notFoundKey,
        retryKey: RecipePage.retryKey,
        data: (view) => _RecipeBody(
          view: view,
          isCooking: isCooking,
          lineStates: lineStates,
        ),
      ),
    );
  }
}

class _RecipeBody extends ConsumerWidget {
  const new({
    required this.view,
    required this.isCooking,
    required this.lineStates,
  });

  final RecipeView view;
  final bool isCooking;
  final Map<int, RecipeLineState>? lineStates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final recipe = view.recipe;
    final provider = recipeControllerProvider(recipe.id);
    final lineStates = this.lineStates;
    final counts = lineStates == null || lineStates.isEmpty
        ? null
        : recipeLineCounts(lineStates);
    final hasOpenLines = (counts?.open ?? 0) > 0;
    final isEstimating = ref.watch(
      provider.select((draft) => draft.waitsForEstimate(view.saved)),
    );
    final runAsync = ref.watch(recipeCookRunProvider(recipe.id));
    final run = view.isVorlage ? null : runAsync.value;
    // A Vorlage is combined from Vorrat foods; the editor writes recipes.
    // A cook run keeps the lines it started with, which an edit would leave
    // behind, so the editor also waits while the run is not known.
    final onEdit =
        view.isVorlage || isCooking || run != null || !runAsync.hasValue
        ? null
        : () =>
              unawaited(context.push(AppRoutes.homeRecipeEditPath(recipe.id)));
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.xl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scrolled content never runs under the status bar, which keeps the
        // page's paper behind it; the photo starts below it.
        Expanded(
          child: SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                RecipeHero(
                  recipe: recipe,
                  portion: ref.watch(recipePortionProvider(recipe.id)),
                  isEstimating: isEstimating,
                  onEdit: onEdit,
                  editKey: RecipePage.editKey,
                  onRemove: isCooking
                      ? null
                      : () => unawaited(
                          CookbookRemoveFlow.remove(
                            context,
                            template: view.saved,
                            closePage: true,
                          ),
                        ),
                ),
                if (counts != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      0,
                    ),
                    child: RecipeLineStatusCard(
                      ready: counts.ready,
                      shopping: counts.shopping,
                      ignored: counts.ignored,
                      open: counts.open,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    0,
                  ),
                  child: RecipePortionsRow(
                    portions: view.portions,
                    basePortions: view.basePortions,
                    onChanged: run == null
                        ? (count) =>
                              ref.read(provider.notifier).setPortions(count)
                        : null,
                    countKey: RecipePage.portionsKey,
                    moreKey: RecipePage.morePortionsKey,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                RecipeSectionHeader(title: l10n.cookingIngredientsTitle),
                for (final (index, line) in view.lines.indexed)
                  Padding(
                    padding: inset,
                    child: RecipeIngredientTile(
                      key: RecipeIngredientTile.tileKey(index),
                      line: line,
                      // A shifted or renamed line shows no state rather than
                      // another food's stock.
                      state: switch (lineStates?[index]) {
                        final state? when state.text == line.ingredient =>
                          state,
                        _ => null,
                      },
                    ),
                  ),
                RecipeNutritionSection(view: view),
                // Without steps there is no "Zubereitung" either.
                if (recipe.recipeInstructions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  RecipeSectionHeader(title: l10n.recipeStepsTitle),
                  RecipeStepList(steps: recipe.recipeInstructions),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
        RecipeBottomBar(
          header: hasOpenLines
              ? Text(
                  l10n.recipeCookNeedsAllLines,
                  key: RecipePage.openHintKey,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: colors.muted),
                )
              : null,
          buttonKey: RecipePage.cookKey,
          label: switch ((view.isVorlage, run)) {
            // A Vorlage goes straight into the pot.
            (true, _) => l10n.cookingCookAction,
            (false, null) => l10n.recipePrepareAction,
            (
              false,
              CookRun(
                needsAssigning: false,
                step: CookRunStep.pots || CookRunStep.assign,
              ),
            ) =>
              l10n.cookingCookAction,
            (false, _) => l10n.cookbookContinueAction,
          },
          onPressed: isCooking || (run == null && view.activeLines.isEmpty)
              ? null
              : () => _cook(context, ref, run),
        ),
      ],
    );
  }

  void _cook(BuildContext context, WidgetRef ref, CookRun? run) {
    if (view.isVorlage) {
      unawaited(
        RecipeCookFlow.cook(
          context: context,
          ref: ref,
          recipeId: view.recipe.id,
        ),
      );
    } else {
      RecipeCookFlow.open(
        context: context,
        recipeId: view.recipe.id,
        run: run,
        portions: view.portions,
      );
    }
  }
}
