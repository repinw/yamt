import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_component_avatar.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/l10n/app_localizations.dart';

class PreparedMealTemplateCard extends ConsumerWidget {
  const PreparedMealTemplateCard({
    super.key,
    required this.template,
    required this.onOpenPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  final PreparedMeal template;
  final VoidCallback onOpenPressed;
  final Future<bool> Function(PreparedMeal template) onEditPressed;
  final Future<bool> Function(String templateId) onDeletePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final imageRef = maybeLocalImageAssetRef(template.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    final metadata = _buildMetadata(l10n);
    final recipeSourceHost = _recipeSourceHost();

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
                  imageBytes: storedImageBytes,
                  imageUrl: template.imageUrl,
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
                  tooltip: l10n.preparedMealTemplateOpenAction,
                  onPressed: onOpenPressed,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
                if (template.recipeUrl != null)
                  IconButton(
                    tooltip: l10n.inventoryReceiptReviewEditAction,
                    onPressed: () => onEditPressed(template),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                IconButton(
                  tooltip: l10n.preparedMealTemplateDeleteAction,
                  onPressed: () => onDeletePressed(template.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (recipeSourceHost != null) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    l10n.preparedMealTemplateRecipeSource(recipeSourceHost),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
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
            if (template.components.isEmpty &&
                template.recipeIngredients.isEmpty)
              Text(
                l10n.preparedMealTemplateNoIngredientsYet,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              )
            else if (template.components.isEmpty)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: template.recipeIngredients
                    .map((ingredient) => Chip(label: Text(ingredient)))
                    .toList(growable: false),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: template.components
                    .map((component) {
                      return Chip(
                        avatar: PreparedMealComponentAvatar(
                          label: component.name,
                          imageUrl: component.imageUrl,
                        ),
                        label: Text(
                          '${component.name} • ${component.usedAmount} '
                          '${component.usedUnit.code}',
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

  String _buildMetadata(AppLocalizations l10n) {
    final parts = <String>[];
    if (template.components.isNotEmpty) {
      parts.add(l10n.preparedMealIngredientsCount(template.components.length));
    } else if (template.recipeIngredients.isNotEmpty) {
      parts.add(
        l10n.preparedMealIngredientsCount(template.recipeIngredients.length),
      );
    } else if (template.recipeUrl != null) {
      parts.add(l10n.preparedMealTemplateRecipePlaceholder);
    }
    parts.add(l10n.preparedMealTemplatePortions(template.totalPortions));
    return parts.join(' • ');
  }

  String? _recipeSourceHost() {
    final recipeUrl = template.recipeUrl;
    if (recipeUrl == null || recipeUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(recipeUrl);
    if (uri == null || uri.host.isEmpty) {
      return null;
    }
    return uri.host.replaceFirst(RegExp(r'^www\.'), '');
  }
}
