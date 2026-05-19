import 'package:flutter/material.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';

/// Defines inventory item image tile.
class InventoryItemImageTile extends StatelessWidget {
  /// The inventory item image tile.
  const InventoryItemImageTile({super.key, this.imageUrl});

  static const double _size = AppInventoryClosedTile.imageSize;

  /// The image url.
  final String? imageUrl;

  int _resolveImageCacheDimension(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final imageSize = _size * devicePixelRatio;
    return imageSize.ceil();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final emojiTextStyle = Theme.of(context).textTheme.titleLarge;
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);
    final imageCacheDimension = _resolveImageCacheDimension(context);
    final backgroundColor = colors.surfaceContainerHigh.withValues(alpha: 0.8);
    final borderRadius = BorderRadius.circular(999);

    return ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: Clip.hardEdge,
      child: DecoratedBox(
        decoration: BoxDecoration(color: backgroundColor),
        child: SizedBox.square(
          dimension: _size,
          child: Center(
            child: normalizedImageUrl == null
                ? Text(
                    AppInventoryItemVisuals.fallbackEmoji,
                    style: emojiTextStyle,
                  )
                : AppCachedNetworkImage(
                    imageUrl: normalizedImageUrl,
                    width: _size,
                    height: _size,
                    fit: BoxFit.cover,
                    cacheWidth: imageCacheDimension,
                    cacheHeight: imageCacheDimension,
                    filterQuality: FilterQuality.low,
                    gaplessPlayback: true,
                    errorBuilder: (_, error, stackTrace) {
                      return Text(
                        AppInventoryItemVisuals.fallbackEmoji,
                        style: emojiTextStyle,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
