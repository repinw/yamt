import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
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
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Renders the generated recipe result card.
@Dependencies([InventoryItemsController])
class AiChefResultView extends ConsumerWidget {
  /// Creates a recipe result view.
  const AiChefResultView({
    required this.recipe,
    required this.onSave,
    required this.onClose,
    required this.isSaving,
    super.key,
  });

  /// The generated recipe.
  final PreparedMeal recipe;

  /// Triggered when the user saves the recipe.
  final VoidCallback onSave;

  /// Triggered when the user closes/discards the view.
  final VoidCallback onClose;

  /// Whether the save action is currently running.
  final bool isSaving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colors = theme.colorScheme;
    final inventoryIngredients = _activeInventoryNames(
      ref.watch(inventoryItemsControllerProvider),
    );

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

List<String> _activeInventoryNames(AsyncValue<List<InventoryItem>> state) {
  final items = state.asData?.value;
  if (items == null) {
    return const <String>[];
  }
  return items
      .where((item) => !item.isFullyConsumed)
      .map((item) => item.name)
      .toList(growable: false);
}
