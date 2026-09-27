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
    final colors = FoodLabelColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: _tile + AppSpacing.md,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(top: AppSpacing.md),
        children: [
          for (final (index, bytes) in photos.indexed)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colors.ink,
                        width: AppFoodLabel.outline,
                      ),
                    ),
                    child: Image.memory(
                      bytes,
                      width: _tile,
                      height: _tile,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -AppSpacing.lg,
                    right: -AppSpacing.lg,
                    child: IconButton.filled(
                      tooltip: l10n.foodEstimateRemovePhoto(index + 1),
                      onPressed: () => onRemove(index),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.ink,
                        foregroundColor: colors.paper,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox.square(
            dimension: _tile,
            child: OutlinedButton(
              key: addKey,
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.muted,
                side: BorderSide(
                  color: colors.rule,
                  width: AppFoodLabel.outline,
                ),
                shape: const RoundedRectangleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xs,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined),
                  Text(l10n.foodEstimateAddPhoto),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
