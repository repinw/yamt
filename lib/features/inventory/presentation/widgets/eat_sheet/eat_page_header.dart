import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_image_tile.dart';

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
    this.collageImageUrls = const <String?>[],
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

  /// Product images of several foods, shown without an own image.
  final List<String?> collageImageUrls;

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
        EatImageTile(
          key: imageKey,
          imageUrl: imageUrl,
          imageBytes: imageBytes,
          collageImageUrls: collageImageUrls,
          fallbackKey: fallbackKey,
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
                    color: colors.muted,
                    letterSpacing: AppFoodLabel.brandTracking,
                  ),
                ),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                  height: 1,
                ),
              ),
              if (captionText != null)
                Text(
                  captionText,
                  style: textTheme.bodySmall?.copyWith(color: colors.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
