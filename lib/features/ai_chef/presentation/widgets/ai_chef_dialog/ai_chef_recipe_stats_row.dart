import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Displays generated recipe nutrition and portions.
class AiChefRecipeStatsRow extends StatelessWidget {
  /// Creates recipe stats row.
  const AiChefRecipeStatsRow({required this.recipe, super.key});

  /// Generated recipe.
  final PreparedMeal recipe;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        _StatBadge(
          label: l10n.aiChefPortionsLabel(recipe.totalPortions),
          color: colors.primary.withValues(alpha: 0.1),
          textColor: colors.primary,
        ),
        _StatBadge(
          label: l10n.aiChefCaloriesLabel(recipe.totalKcal.round()),
          color: colors.secondary.withValues(alpha: 0.1),
          textColor: colors.secondary,
        ),
        _StatBadge(
          label: l10n.aiChefProteinLabel(recipe.totalProtein.round()),
          color: Colors.green.withValues(alpha: 0.1),
          textColor: Colors.green.shade700,
        ),
        _StatBadge(
          label: l10n.aiChefCarbsLabel(recipe.totalCarbs.round()),
          color: Colors.orange.withValues(alpha: 0.1),
          textColor: Colors.orange.shade700,
        ),
        _StatBadge(
          label: l10n.aiChefFatLabel(recipe.totalFat.round()),
          color: Colors.pink.withValues(alpha: 0.1),
          textColor: Colors.pink.shade700,
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
