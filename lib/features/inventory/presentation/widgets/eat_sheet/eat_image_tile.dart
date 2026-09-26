import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_hero_image.dart';

/// Tilted, framed food image of the food label pages, with a fallback icon.
class EatImageTile extends StatelessWidget {
  /// Creates the tile.
  const new({
    this.imageUrl,
    this.imageBytes,
    this.size = AppFoodLabel.imageTile,
    this.angle = AppFoodLabel.imageTilt,
    this.fallbackKey,
    super.key,
  });

  /// Image address.
  final String? imageUrl;

  /// Local image.
  final Uint8List? imageBytes;

  /// Edge length of the tile.
  final double size;

  /// Tilt in radians.
  final double angle;

  /// Key of the placeholder icon shown without an image.
  final Key? fallbackKey;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return Transform.rotate(
      angle: angle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.tile,
          border: Border.all(color: colors.ink, width: AppFoodLabel.outline),
        ),
        child: SizedBox.square(
          dimension: size,
          // The image sits inside the frame, so the frame stays visible.
          child: Padding(
            padding: const EdgeInsets.all(AppFoodLabel.outline),
            child: ClipRect(
              child: EatSheetHeroImage(
                imageUrl: imageUrl,
                imageBytes: imageBytes,
                fallback: Center(
                  child: Icon(
                    Icons.restaurant_rounded,
                    key: fallbackKey,
                    color: colors.onTile,
                    size: size * AppFoodLabel.imageFallbackIconShare,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
