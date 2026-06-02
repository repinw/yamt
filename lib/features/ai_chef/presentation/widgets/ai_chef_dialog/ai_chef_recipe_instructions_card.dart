import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// Displays generated recipe instructions.
class AiChefRecipeInstructionsCard extends StatelessWidget {
  /// Creates recipe instructions card.
  const AiChefRecipeInstructionsCard({
    required this.recipe,
    super.key,
  });

  /// Generated recipe.
  final PreparedMeal recipe;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: _cardDecoration(colors),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: recipe.recipeInstructions.asMap().entries.map((entry) {
            return _InstructionRow(index: entry.key + 1, step: entry.value);
          }).toList(),
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({required this.index, required this.step});

  final int index;
  final String step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepNumberBadge(index: index),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              step,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepNumberBadge extends StatelessWidget {
  const _StepNumberBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$index',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colors.primary,
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
