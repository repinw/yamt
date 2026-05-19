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

/// Redesigned, visual-first prepared meal template card.
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
    final borderRadius = BorderRadius.circular(AppEditorial.cardRadius);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top aspect-ratio cover area with floating actions
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: PreparedMealCover(
                      label: template.name,
                      imageBytes: storedImageBytes,
                      imageUrl: template.imageUrl,
                      size: double.infinity,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppEditorial.cardRadius),
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: _PreparedMealTemplateMenuButton(
                      template: template,
                      onEditPressed: onEditPressed,
                      onDeletePressed: onDeletePressed,
                      editLabel: l10n.inventoryReceiptReviewEditAction,
                      deleteLabel: l10n.preparedMealTemplateDeleteAction,
                    ),
                  ),
                ],
              ),
              // Card Details Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              height: 1.25,
                            ),
                      ),
                      const Spacer(),
                      if (hasActiveCookflow) ...[
                        _ResumeCookflowButton(onPressed: onOpenPressed),
                      ] else ...[
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant_rounded,
                              size: 13,
                              color: colors.primary.withValues(alpha: 0.72),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${template.totalPortions} '
                              '${l10n.preparedMealTemplatePortionsLabel}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface.withValues(alpha: 0.8),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.16),
        ),
      ),
      child: PopupMenuButton<_PreparedMealTemplateCardAction>(
        tooltip: MaterialLocalizations.of(context).showMenuTooltip,
        useRootNavigator: true,
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: colors.onSurface,
        ),
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
      ),
    );
  }
}

class _ResumeCookflowButton extends StatelessWidget {
  const _ResumeCookflowButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AppInkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          gradient: AppEditorialSurfaces.soulGradient(colors),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.play_circle_outline_rounded,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.cookflowResumeLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
