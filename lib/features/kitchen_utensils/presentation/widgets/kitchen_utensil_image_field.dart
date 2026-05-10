import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensil_cover.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Source used to pick a kitchen utensil image.
enum KitchenUtensilImageSource {
  /// Device camera.
  camera,

  /// File picker.
  file,
}

/// Image preview and picker controls for the kitchen utensil sheet.
class KitchenUtensilImageField extends StatelessWidget {
  /// Creates image picker field.
  const KitchenUtensilImageField({
    required this.label,
    required this.imageBytes,
    required this.imageUrl,
    required this.supportsCamera,
    required this.isPickingImage,
    required this.onPickImage,
    required this.onClearImage,
    super.key,
  });

  /// Label used by the image fallback.
  final String label;

  /// Locally picked image bytes.
  final Uint8List? imageBytes;

  /// Existing synced image URL.
  final String? imageUrl;

  /// Whether camera capture is available.
  final bool supportsCamera;

  /// Whether an image picker operation is running.
  final bool isPickingImage;

  /// Called when user chooses an image source.
  final ValueChanged<KitchenUtensilImageSource> onPickImage;

  /// Called when user clears the image.
  final VoidCallback onClearImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final hasImage = imageBytes != null || imageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.kitchenUtensilImageLabel,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KitchenUtensilCover(
              label: label,
              imageBytes: imageBytes,
              imageUrl: imageUrl,
              size: 88,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _KitchenUtensilImageActions(
                hasImage: hasImage,
                supportsCamera: supportsCamera,
                isPickingImage: isPickingImage,
                onPickImage: onPickImage,
                onClearImage: onClearImage,
                hintColor: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KitchenUtensilImageActions extends StatelessWidget {
  const _KitchenUtensilImageActions({
    required this.hasImage,
    required this.supportsCamera,
    required this.isPickingImage,
    required this.onPickImage,
    required this.onClearImage,
    required this.hintColor,
  });

  final bool hasImage;
  final bool supportsCamera;
  final bool isPickingImage;
  final ValueChanged<KitchenUtensilImageSource> onPickImage;
  final VoidCallback onClearImage;
  final Color hintColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (supportsCamera)
              FilledButton.tonalIcon(
                onPressed: isPickingImage
                    ? null
                    : () => onPickImage(KitchenUtensilImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l10n.kitchenUtensilImageCameraAction),
              ),
            FilledButton.tonalIcon(
              onPressed: isPickingImage
                  ? null
                  : () => onPickImage(KitchenUtensilImageSource.file),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                hasImage
                    ? l10n.kitchenUtensilChangeImageAction
                    : l10n.kitchenUtensilAddImageAction,
              ),
            ),
            if (hasImage)
              TextButton.icon(
                onPressed: isPickingImage ? null : onClearImage,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l10n.kitchenUtensilRemoveImageAction),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.kitchenUtensilImageHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: hintColor,
          ),
        ),
      ],
    );
  }
}
