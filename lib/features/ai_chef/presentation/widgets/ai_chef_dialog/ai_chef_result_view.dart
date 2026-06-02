import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_action_buttons_row.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_recipe_ingredients_card.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_recipe_instructions_card.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_recipe_section_title.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_recipe_stats_row.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Renders the generated recipe result card.
class AiChefResultView extends StatelessWidget {
  /// Creates a recipe result view.
  const AiChefResultView({
    required this.recipe,
    required this.inventoryIngredients,
    required this.onSave,
    required this.onClose,
    required this.isSaving,
    super.key,
  });

  /// The generated recipe.
  final PreparedMeal recipe;

  /// Active inventory names used to mark matching ingredients.
  final List<String> inventoryIngredients;

  /// Triggered when the user saves the recipe.
  final VoidCallback onSave;

  /// Triggered when the user closes/discards the view.
  final VoidCallback onClose;

  /// Whether the save action is currently running.
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colors = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          if (recipe.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: AppCachedNetworkImage(
                imageUrl: recipe.imageUrl!,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            recipe.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AiChefRecipeStatsRow(recipe: recipe),
          const SizedBox(height: AppSpacing.lg),
          AiChefRecipeSectionTitle(
            title: l10n.preparedMealIngredientsTitle,
            icon: Icons.kitchen_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          AiChefRecipeIngredientsCard(
            recipe: recipe,
            inventoryIngredients: inventoryIngredients,
          ),
          const SizedBox(height: AppSpacing.lg),
          AiChefRecipeSectionTitle(
            title: l10n.preparedMealTemplateImportReviewInstructionsTitle,
            icon: Icons.format_list_numbered_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          AiChefRecipeInstructionsCard(recipe: recipe),
          const SizedBox(height: AppSpacing.xl),
          AiChefActionButtonsRow(
            onClose: onClose,
            onSave: onSave,
            isSaving: isSaving,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
