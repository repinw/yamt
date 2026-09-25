import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_hero_image.dart';

/// Head of the eat page: a tilted image tile, the brand, the name and a
/// short caption.
class EatPageHeader extends StatelessWidget {
  /// Creates the header.
  const new({
    required this.title,
    this.brand,
    this.caption,
    this.imageUrl,
    this.imageBytes,
    this.imageKey,
    this.fallbackKey,
    super.key,
  });

  /// Food name.
  final String title;

  /// Brand, shown small above the name.
  final String? brand;

  /// Line under the name, such as the stock.
  final String? caption;

  /// Image address.
  final String? imageUrl;

  /// Local image.
  final Uint8List? imageBytes;

  /// Key of the image tile.
  final Key? imageKey;

  /// Key of the placeholder icon shown without an image.
  final Key? fallbackKey;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final brandText = brand?.trim();
    final captionText = caption;

    return Row(
      spacing: AppSpacing.xl,
      children: [
        Transform.rotate(
          angle: AppFoodLabel.imageTilt,
          child: DecoratedBox(
            key: imageKey,
            decoration: BoxDecoration(
              color: colors.tile,
              border: Border.all(
                color: colors.ink,
                width: AppFoodLabel.outline,
              ),
            ),
            child: SizedBox.square(
              dimension: AppFoodLabel.imageTile,
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
                        size: AppFoodLabel.imageFallbackIcon,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              if (brandText != null && brandText.isNotEmpty)
                Text(
                  brandText.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    fontFamily: AppFonts.mono,
                    color: colors.muted,
                    letterSpacing: AppFoodLabel.brandTracking,
                  ),
                ),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.displaySmall?.copyWith(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                  height: 1,
                ),
              ),
              if (captionText != null)
                Text(
                  captionText,
                  style: textTheme.labelMedium?.copyWith(
                    fontFamily: AppFonts.mono,
                    color: colors.muted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
