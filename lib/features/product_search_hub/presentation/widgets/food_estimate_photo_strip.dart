import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Row of the photos picked for an AI food estimate, with a tile that adds
/// more from the gallery.
class FoodEstimatePhotoStrip extends StatelessWidget {
  /// Creates the strip.
  const new({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  /// Key of the tile that adds photos.
  static const addKey = Key('food_estimate_add_photo');

  /// Photos in the order they were added.
  final List<Uint8List> photos;

  /// Opens the gallery.
  final VoidCallback? onAdd;

  /// Removes the photo at the given index.
  final ValueChanged<int> onRemove;

  static const double _tile = AppFoodLabel.imageTile + AppSpacing.xxl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _tile + AppSpacing.md,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(top: AppSpacing.md),
        itemCount: photos.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, index) => index < photos.length
            ? _PhotoTile(
                bytes: photos[index],
                number: index + 1,
                onRemove: () => onRemove(index),
              )
            : _AddTile(onAdd: onAdd),
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
            width: FoodEstimatePhotoStrip._tile,
            height: FoodEstimatePhotoStrip._tile,
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

class _AddTile extends StatelessWidget {
  const new({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return SizedBox.square(
      dimension: FoodEstimatePhotoStrip._tile,
      child: OutlinedButton(
        key: FoodEstimatePhotoStrip.addKey,
        onPressed: onAdd,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.muted,
          side: BorderSide(color: colors.rule, width: AppFoodLabel.outline),
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.all(AppSpacing.xs),
        ),
        // Scales the label down under large text instead of overflowing
        // the fixed tile.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xs,
            children: [
              const Icon(Icons.add_photo_alternate_outlined),
              Text(AppLocalizations.of(context)!.foodEstimateAddPhoto),
            ],
          ),
        ),
      ),
    );
  }
}
