import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Photos of an AI food estimate. The camera comes first: a large camera
/// tile before the first photo, then the photo row with a tile for one
/// more. The gallery is a small link under both.
class FoodEstimatePhotoInput extends StatelessWidget {
  /// Creates the photo input.
  const new({
    required this.photos,
    required this.canAddPhoto,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
    super.key,
  });

  /// Key of the tile that opens the camera.
  static const cameraKey = Key('food_estimate_camera');

  /// Key of the link that opens the gallery.
  static const galleryKey = Key('food_estimate_gallery');

  /// Photos in the order they were added.
  final List<Uint8List> photos;

  /// Whether another photo fits. The tile for one more and the gallery
  /// link are hidden when not.
  final bool canAddPhoto;

  /// Opens the camera. The tile is disabled when null.
  final VoidCallback? onCamera;

  /// Opens the gallery. The link is disabled when null.
  final VoidCallback? onGallery;

  /// Removes the photo at the given index.
  final ValueChanged<int> onRemove;

  static const double _tile = AppFoodLabel.photoTile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        if (photos.isEmpty)
          _CameraTile(onPressed: onCamera)
        else
          SizedBox(
            height: _tile + AppSpacing.md,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.only(top: AppSpacing.md),
              itemCount: photos.length + (canAddPhoto ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
              itemBuilder: (context, index) => index < photos.length
                  ? _PhotoTile(
                      bytes: photos[index],
                      number: index + 1,
                      onRemove: () => onRemove(index),
                    )
                  : _MoreTile(onPressed: onCamera),
            ),
          ),
        if (canAddPhoto)
          Center(
            child: TextButton.icon(
              key: galleryKey,
              onPressed: onGallery,
              style: TextButton.styleFrom(foregroundColor: colors.muted),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                l10n.foodEstimateFromGallery,
                style: const TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ),
      ],
    );
  }
}

class _CameraTile extends StatelessWidget {
  const new({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: AppFoodLabel.cameraTile,
      child: OutlinedButton(
        key: FoodEstimatePhotoInput.cameraKey,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.card,
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.accent, width: AppFoodLabel.outline),
          shape: const RoundedRectangleBorder(),
        ),
        // Scales down under large text instead of overflowing the tile.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.md,
            children: [
              const _CameraBadge(size: AppFoodLabel.cameraBadge),
              Text(
                l10n.foodEstimateTakePhoto,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
              Text(
                l10n.foodEstimateTakePhotoHint,
                style: textTheme.bodySmall?.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const new({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return SizedBox.square(
      dimension: FoodEstimatePhotoInput._tile,
      child: OutlinedButton(
        key: FoodEstimatePhotoInput.cameraKey,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.card,
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.accent, width: AppFoodLabel.outline),
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.all(AppSpacing.xs),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xs,
            children: [
              const _CameraBadge(size: AppFoodLabel.cameraBadgeSmall),
              Text(AppLocalizations.of(context)!.foodEstimateAnotherPhoto),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraBadge extends StatelessWidget {
  const new({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
      child: SizedBox.square(
        dimension: size,
        child: Icon(
          Icons.photo_camera_outlined,
          color: colors.onAccent,
          size: size / 2,
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const new({
    required this.bytes,
    required this.number,
    required this.onRemove,
  });

  final Uint8List bytes;
  final int number;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colors.ink, width: AppFoodLabel.outline),
          ),
          child: Image.memory(
            bytes,
            width: FoodEstimatePhotoInput._tile,
            height: FoodEstimatePhotoInput._tile,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -AppSpacing.lg,
          right: -AppSpacing.lg,
          child: IconButton.filled(
            tooltip: AppLocalizations.of(context)!
                .foodEstimateRemovePhoto(number),
            onPressed: onRemove,
            style: IconButton.styleFrom(
              backgroundColor: colors.ink,
              foregroundColor: colors.paper,
            ),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    );
  }
}
