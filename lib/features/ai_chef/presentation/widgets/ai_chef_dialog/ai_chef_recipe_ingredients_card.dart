import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Displays generated recipe ingredients.
class AiChefRecipeIngredientsCard extends StatelessWidget {
  /// Creates recipe ingredients card.
  const AiChefRecipeIngredientsCard({
    required this.recipe,
    required this.inventoryIngredients,
    super.key,
  });

  /// Generated recipe.
  final PreparedMeal recipe;

  /// Active inventory names used to mark matching ingredients.
  final List<String> inventoryIngredients;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: _cardDecoration(colors),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: recipe.recipeIngredients.map((ingredient) {
            return _IngredientRow(
              ingredient: ingredient,
              isFromInventory: _matchesInventory(
                ingredient,
                inventoryIngredients,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _matchesInventory(String ingredient, List<String> inventory) {
    final lowerIngredient = ingredient.toLowerCase();
    return inventory.any((item) {
      final lowerItem = item.toLowerCase().trim();
      if (lowerItem.isEmpty || lowerItem.length < 3) {
        return false;
      }
      return lowerIngredient.contains(lowerItem);
    });
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.isFromInventory,
  });

  final String ingredient;
  final bool isFromInventory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IngredientBullet(isFromInventory: isFromInventory),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              ingredient,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
          if (isFromInventory) ...[
            const SizedBox(width: AppSpacing.xs),
            const _InventoryMatchBadge(),
          ],
        ],
      ),
    );
  }
}

class _IngredientBullet extends StatelessWidget {
  const _IngredientBullet({required this.isFromInventory});

  final bool isFromInventory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Text(
      '-',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isFromInventory ? Colors.green.shade600 : colors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _InventoryMatchBadge extends StatelessWidget {
  const _InventoryMatchBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 10,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 2),
            Text(
              l10n.aiChefFromInventory,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(ColorScheme colors) {
  return BoxDecoration(
    color: colors.surfaceContainerLow,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
  );
}
