import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search/domain/'
    'product_ai_search_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Ingredient nutrition estimate table for AI product drafts.
class AiIngredientTable extends StatelessWidget {
  /// Creates an ingredient table.
  const AiIngredientTable({required this.draft, super.key});

  /// Current AI draft.
  final ProductAiSearchDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final headerStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.inventoryManualAddAiSearchIngredientsTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                l10n.inventoryManualAddAiSearchAmountColumn,
                style: headerStyle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.inventoryNutritionCaloriesShortLabel,
                style: headerStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.caloriesProteinLabel,
                style: headerStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.inventoryNutritionCarbsShortLabel,
                style: headerStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.caloriesFatLabel,
                style: headerStyle,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Divider(color: colors.outlineVariant),
        for (final ingredient in draft.ingredients) ...[
          AiIngredientRow(ingredient: ingredient),
          const SizedBox(height: AppSpacing.sm),
        ],
        Divider(color: colors.outlineVariant),
        AiIngredientTotalRow(draft: draft),
      ],
    );
  }
}

/// Ingredient row in the AI estimate table.
class AiIngredientRow extends StatelessWidget {
  /// Creates an ingredient row.
  const AiIngredientRow({required this.ingredient, super.key});

  /// Ingredient estimate.
  final ProductAiSearchIngredientRow ingredient;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ingredient.label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(ingredient.amountText, style: valueStyle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _buildKcalText(),
                style: valueStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _formatMacro(ingredient.protein),
                style: valueStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _formatMacro(ingredient.carbs),
                style: valueStyle,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _formatMacro(ingredient.fat),
                style: valueStyle,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _buildKcalText() {
    if (ingredient.kcalMin == ingredient.kcalMax) {
      return formatManualProductDouble(ingredient.kcalMin);
    }
    return '${formatManualProductDouble(ingredient.kcalMin)} - '
        '${formatManualProductDouble(ingredient.kcalMax)}';
  }

  String _formatMacro(double? value) {
    if (value == null) {
      return '-';
    }
    return formatManualProductDouble(value);
  }
}

/// Total row in the AI estimate table.
class AiIngredientTotalRow extends StatelessWidget {
  /// Creates a total row.
  const AiIngredientTotalRow({required this.draft, super.key});

  /// Current AI draft.
  final ProductAiSearchDraft draft;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            AppLocalizations.of(context)!.inventoryManualAddAiSearchTotalLabel,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 4,
          child: Text(draft.totalWeightLabel, style: valueStyle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 3,
          child: Text(
            draft.totalKcalRangeLabel,
            style: valueStyle,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
