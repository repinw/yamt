import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensil_cover.dart';
import 'package:yamt/features/kitchen_utensils/provider/'
    'kitchen_utensil_image_url_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Kitchen utensil list card.
class KitchenUtensilCard extends ConsumerWidget {
  /// Creates card.
  const KitchenUtensilCard({
    required this.utensil,
    required this.onEditPressed,
    required this.onDeletePressed,
    super.key,
  });

  /// Utensil.
  final KitchenUtensil utensil;

  /// Edit callback.
  final Future<bool> Function(KitchenUtensil utensil) onEditPressed;

  /// Delete callback.
  final Future<bool> Function(String utensilId) onDeletePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(
      AppEditorial.cardRadius,
    );
    final imagePath = utensil.imageStoragePath;
    final imageUrl = imagePath == null
        ? null
        : ref.watch(kitchenUtensilImageUrlProvider(imagePath)).asData?.value;
    final displayName = utensil.name ?? l10n.kitchenUtensilUnnamedLabel;

    return DecoratedBox(
      decoration: AppEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          children: [
            KitchenUtensilCover(
              label: displayName,
              imageBytes: null,
              imageUrl: imageUrl,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.kitchenUtensilWeightValue(utensil.weightGrams),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<_KitchenUtensilCardAction>(
              tooltip: MaterialLocalizations.of(context).showMenuTooltip,
              onSelected: (action) {
                switch (action) {
                  case _KitchenUtensilCardAction.edit:
                    unawaited(onEditPressed(utensil));
                  case _KitchenUtensilCardAction.delete:
                    unawaited(onDeletePressed(utensil.id));
                }
              },
              itemBuilder: (context) {
                return <PopupMenuEntry<_KitchenUtensilCardAction>>[
                  PopupMenuItem<_KitchenUtensilCardAction>(
                    value: _KitchenUtensilCardAction.edit,
                    child: Text(l10n.inventoryReceiptReviewEditAction),
                  ),
                  PopupMenuItem<_KitchenUtensilCardAction>(
                    value: _KitchenUtensilCardAction.delete,
                    child: Text(l10n.kitchenUtensilDeleteAction),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _KitchenUtensilCardAction { edit, delete }
