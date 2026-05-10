import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines prepared meal template card.
class PreparedMealTemplateCard extends ConsumerWidget {
  /// The prepared meal template card.
  const PreparedMealTemplateCard({
    required this.template,
    required this.onOpenPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
    super.key,
  });

  /// The template.
  final PreparedMeal template;

  /// The on open pressed.
  final VoidCallback onOpenPressed;

  /// The on edit pressed.
  final Future<bool> Function(PreparedMeal template) onEditPressed;

  /// The on delete pressed.
  final Future<bool> Function(String templateId) onDeletePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderRadius = BorderRadius.circular(
      AppInventoryEditorial.cardRadius,
    );
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final imageRef = maybeLocalImageAssetRef(template.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onOpenPressed,
          child: Padding(
            padding: AppInsets.card,
            child: Row(
              children: [
                PreparedMealCover(
                  label: template.name,
                  imageBytes: storedImageBytes,
                  imageUrl: template.imageUrl,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    template.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                PopupMenuButton<_PreparedMealTemplateCardAction>(
                  tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                  onSelected: (action) {
                    switch (action) {
                      case _PreparedMealTemplateCardAction.edit:
                        unawaited(onEditPressed(template));
                      case _PreparedMealTemplateCardAction.delete:
                        unawaited(onDeletePressed(template.id));
                    }
                  },
                  itemBuilder: (context) {
                    return <PopupMenuEntry<_PreparedMealTemplateCardAction>>[
                      if (template.recipeUrl != null)
                        PopupMenuItem<_PreparedMealTemplateCardAction>(
                          value: _PreparedMealTemplateCardAction.edit,
                          child: Text(l10n.inventoryReceiptReviewEditAction),
                        ),
                      PopupMenuItem<_PreparedMealTemplateCardAction>(
                        value: _PreparedMealTemplateCardAction.delete,
                        child: Text(l10n.preparedMealTemplateDeleteAction),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PreparedMealTemplateCardAction { edit, delete }
