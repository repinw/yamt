import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/product_image_collage.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_hero_image.dart';

/// Tilted, framed food image of the food label pages. Without an own image
/// it shows the product images of the foods in [collageImageUrls], and
/// without those a fallback icon.
class EatImageTile extends StatelessWidget {
  /// Creates the tile.
  const new({
    this.imageUrl,
    this.imageBytes,
    this.collageImageUrls = const <String?>[],
    this.size = AppFoodLabel.imageTile,
    this.angle = AppFoodLabel.imageTilt,
    this.fallbackKey,
    this.fallbackLetter,
    super.key,
  });

  /// Image address.
  final String? imageUrl;

  /// Local image.
  final Uint8List? imageBytes;

  /// Product images of several foods, shown without an own image.
  final List<String?> collageImageUrls;

  /// Edge length of the tile.
  final double size;

  /// Tilt in radians.
  final double angle;

  /// Key of the placeholder shown without an image.
  final Key? fallbackKey;

  /// Letter shown without an image instead of the fallback icon, such as the
  /// first letter of the food's name.
  final String? fallbackLetter;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final collageUrls = collageImageUrls;
    final collage = productCollageImageUrls(collageUrls);
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
                fallback: collage.isNotEmpty
                    ? ProductImageCollage(
                        key: const Key('eat_image_tile_collage'),
                        imageUrls: collage,
                      )
                    : Center(
                        child: _Fallback(
                          key: fallbackKey,
                          letter: fallbackLetter,
                          size: size,
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

class _Fallback extends StatelessWidget {
  const new({required this.letter, required this.size, super.key});

  final String? letter;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final letter = this.letter;
    if (letter == null) {
      return Icon(
        Icons.restaurant_rounded,
        color: colors.onTile,
        size: size * AppFoodLabel.imageFallbackIconShare,
      );
    }
    return Text(
      letter,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: colors.ink,
        fontSize: size * AppFoodLabel.imageFallbackLetterShare,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    );
  }
}
