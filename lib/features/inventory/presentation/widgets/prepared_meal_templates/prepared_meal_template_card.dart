import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/l10n/app_localizations.dart';

class PreparedMealTemplateCard extends StatelessWidget {
  const PreparedMealTemplateCard({
    super.key,
    required this.template,
    required this.onDeletePressed,
  });

  final PreparedMeal template;
  final Future<bool> Function(String templateId) onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final metadata =
        '${l10n.preparedMealIngredientsCount(template.components.length)} • '
        '${l10n.preparedMealTemplatePortions(template.totalPortions)}';

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PreparedMealCover(
                  label: template.name,
                  imageBytes: template.imageBytes,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        metadata,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  tooltip: l10n.preparedMealTemplateDeleteAction,
                  onPressed: () => onDeletePressed(template.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  '${template.totalKcal.toStringAsFixed(0)} '
                  '${l10n.caloriesUnitKcal}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: template.components
                  .map((component) {
                    return Chip(
                      avatar: _TemplateIngredientAvatar(
                        label: component.name,
                        imageUrl: component.imageUrl,
                      ),
                      label: Text(
                        '${component.name} • ${component.usedAmount} '
                        '${_amountUnitCode(component.usedUnit)}',
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateIngredientAvatar extends StatelessWidget {
  const _TemplateIngredientAvatar({
    required this.label,
    required this.imageUrl,
  });

  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: Colors.transparent,
      );
    }

    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);
    return CircleAvatar(
      backgroundColor: AppInventoryEditorial.primary.withValues(alpha: 0.12),
      child: Text(initial.toUpperCase()),
    );
  }
}

String _amountUnitCode(InventoryAmountUnit unit) {
  return switch (unit) {
    InventoryAmountUnit.gram => 'g',
    InventoryAmountUnit.milliliter => 'ml',
    InventoryAmountUnit.piece => 'pc',
  };
}
