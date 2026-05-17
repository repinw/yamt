import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/cooking_flow/data/'
    'cooking_flow_session_local_store.dart';
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
      AppEditorial.cardRadius,
    );
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final activeSession = ref
        .watch(cookingFlowSessionSnapshotProvider)
        .asData
        ?.value;
    final hasActiveCookflow = activeSession?.templateId == template.id;
    final imageRef = maybeLocalImageAssetRef(template.imageAssetId);
    final storedImageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;

    return DecoratedBox(
      decoration: AppEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        child: AppInkWell(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        template.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (hasActiveCookflow) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        _ResumeCookflowBadge(
                          onPressed: onOpenPressed,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: hasActiveCookflow ? AppSpacing.sm : AppSpacing.xs,
                ),
                _PreparedMealTemplateMenuButton(
                  template: template,
                  onEditPressed: onEditPressed,
                  onDeletePressed: onDeletePressed,
                  editLabel: l10n.inventoryReceiptReviewEditAction,
                  deleteLabel: l10n.preparedMealTemplateDeleteAction,
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

class _PreparedMealTemplateMenuButton extends StatelessWidget {
  const _PreparedMealTemplateMenuButton({
    required this.template,
    required this.onEditPressed,
    required this.onDeletePressed,
    required this.editLabel,
    required this.deleteLabel,
  });

  final PreparedMeal template;
  final Future<bool> Function(PreparedMeal template) onEditPressed;
  final Future<bool> Function(String templateId) onDeletePressed;
  final String editLabel;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PreparedMealTemplateCardAction>(
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
              child: Text(editLabel),
            ),
          PopupMenuItem<_PreparedMealTemplateCardAction>(
            value: _PreparedMealTemplateCardAction.delete,
            child: Text(deleteLabel),
          ),
        ];
      },
    );
  }
}

class _ResumeCookflowBadge extends StatelessWidget {
  const _ResumeCookflowBadge({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AppInkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.play_circle_outline_rounded,
              size: 16,
              color: colors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.cookflowResumeLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
