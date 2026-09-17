import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';

/// Displays an inventory or prepared-meal image with a themed fallback.
class DiaryInventoryFoodImage extends StatelessWidget {
  /// Creates an inventory food image.
  const new({
    required this.fallbackIcon,
    this.imageUrl,
    this.imageBytes,
    super.key,
  });

  static const double _size = 44;

  /// Icon shown when no image is available.
  final IconData fallbackIcon;

  /// Optional remote image URL.
  final String? imageUrl;

  /// Optional locally stored image bytes.
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: colors.secondaryContainer.withValues(alpha: 0.75),
      child: Center(
        child: Icon(fallbackIcon, size: 22, color: colors.onSecondaryContainer),
      ),
    );
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox.square(
        dimension: _size,
        child: imageBytes != null
            ? Image.memory(
                imageBytes!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              )
            : normalizedImageUrl == null
            ? fallback
            : AppCachedNetworkImage(
                imageUrl: normalizedImageUrl,
                fit: BoxFit.cover,
                cacheWidth: (_size * pixelRatio).round(),
                cacheHeight: (_size * pixelRatio).round(),
                filterQuality: FilterQuality.low,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
