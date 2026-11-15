import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sheet_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_idea_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_planned_nutrition.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_bottom_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_estimate_line.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_ingredient_tile.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_nutrition_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_section_header.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_step_list.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A recipe idea as the recipe page shows it, in a tall window: its picture
/// once it is there, the name, the estimate per portion, the portions, the
/// ingredients with a check for those the Vorrat holds (and no room for one
/// while it holds none), the food label of one portion and the nutrition of
/// each ingredient folded under them, and the steps.
/// "Im Kochbuch speichern" saves it and closes the window; `RecipeIdeaFlow`
/// says how saving went, also when the cook closes the window while it
/// saves. Closing it before saving drops the idea.
class RecipeIdeaSheet extends ConsumerStatefulWidget {
  /// Creates the window of [idea].
  const new({required this.idea, required this.onSaving, super.key});

  /// Key of "Im Kochbuch speichern".
  static const saveKey = ValueKey<String>('recipe-idea-save');

  /// Key of the place of the picture: "Bild wird generiert …" while it is
  /// made, plain when none comes.
  static const pictureKey = ValueKey<String>('recipe-idea-picture');

  /// Key of "Bild wird generiert …" in the picture's place while it is made.
  static const pictureComingKey = ValueKey<String>(
    'recipe-idea-picture-coming',
  );

  /// The recipe idea.
  final AiChefRecipeIdea idea;

  /// Gets the save when the cook starts it, and `null` when it failed while
  /// the window showed that. A save that runs when the window closes goes
  /// on, and its result is the caller's to tell.
  final ValueChanged<Future<PreparedMeal?>?> onSaving;

  /// Shows the window until the idea is saved or the cook closes it;
  /// [onSaving] gets the save.
  static Future<void> show(
    BuildContext context, {
    required AiChefRecipeIdea idea,
    required ValueChanged<Future<PreparedMeal?>?> onSaving,
  }) => showModalBottomSheet<void>(
    context: context,
    // Above the bottom navigation of the home tabs.
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: FoodLabelColors.of(context).paper,
    builder: (_) => FractionallySizedBox(
      heightFactor: AppSheetTokens.tallSheetHeightFactor,
      child: RecipeIdeaSheet(idea: idea, onSaving: onSaving),
    ),
  );

  @override
  ConsumerState<RecipeIdeaSheet> createState() => _RecipeIdeaSheetState();
}

class _RecipeIdeaSheetState extends ConsumerState<RecipeIdeaSheet> {
  bool _isSaving = false;
  bool _saveFailed = false;

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });
    unawaited(HapticFeedback.mediumImpact());
    final saving = ref
        .read(recipeIdeaControllerProvider(widget.idea).notifier)
        .save();
    widget.onSaving(saving);
    final saved = await saving;
    if (!mounted) return;
    if (saved == null) {
      widget.onSaving(null);
      setState(() {
        _isSaving = false;
        _saveFailed = true;
      });
      return;
    }
    // The cook may have closed the window already; then it is gone.
    if (ModalRoute.isCurrentOf(context) ?? false) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final picture = ref.watch(recipeIdeaControllerProvider(widget.idea));
    final view = ref.watch(
      recipeIdeaViewProvider(widget.idea, l10n.localeName),
    );
    final recipe = view.recipe;
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.xl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: inset,
                child: _IdeaPicture(picture: picture),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.sm,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (view.estimate case final estimate?)
                      RecipeEstimateLine(
                        portion: (
                          values: estimateValues(estimate),
                          estimated: true,
                        ),
                      ),
                    Text(
                      l10n.cookPortionsLabel(view.portions),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RecipeSectionHeader(title: l10n.cookingIngredientsTitle),
              // Without a check to show, the lines start at the text edge.
              for (final (index, line) in view.lines.indexed)
                Padding(
                  padding: inset,
                  child: RecipeIngredientTile(
                    key: RecipeIngredientTile.tileKey(index),
                    line: line,
                    inStock: view.anyLineInStock ? line.items.isNotEmpty : null,
                  ),
                ),
              RecipeNutritionSection(view: view),
              if (recipe.recipeInstructions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                RecipeSectionHeader(title: l10n.recipeStepsTitle),
                RecipeStepList(steps: recipe.recipeInstructions),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
        RecipeBottomBar(
          header: _saveFailed
              ? Text(
                  l10n.aiChefSaveError,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: colors.low),
                )
              : null,
          buttonKey: RecipeIdeaSheet.saveKey,
          label: l10n.aiChefSaveAction,
          onPressed: _isSaving ? null : () => unawaited(_save()),
        ),
      ],
    );
  }
}

// The picture of the idea: a calm plain place while it is made, then the
// picture fades in. When none comes the plain place stays, so nothing under
// it moves.
class _IdeaPicture extends StatelessWidget {
  const new({required this.picture});

  final AsyncValue<Uint8List> picture;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    // Each its own key, so the picture fades over the plain place.
    Widget framed(Widget child, {required bool isPicture}) => ClipRRect(
      key: ValueKey<bool>(isPicture),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AspectRatio(
        aspectRatio: AppGraphit.recipeIdeaPictureAspectRatio,
        child: child,
      ),
    );

    final plain = framed(ColoredBox(color: colors.card), isPicture: false);
    // While the picture is made the place says so, so it does not read as
    // a missing picture.
    final coming = framed(
      ColoredBox(
        color: colors.card,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.recipeIdeaPictureComing,
            key: RecipeIdeaSheet.pictureComingKey,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.muted),
          ),
        ),
      ),
      isPicture: false,
    );

    return AnimatedSwitcher(
      key: RecipeIdeaSheet.pictureKey,
      duration: AppGraphit.stateChange,
      child: picture.when(
        data: (bytes) =>
            framed(Image.memory(bytes, fit: BoxFit.cover), isPicture: true),
        loading: () => coming,
        error: (_, _) => plain,
      ),
    );
  }
}
