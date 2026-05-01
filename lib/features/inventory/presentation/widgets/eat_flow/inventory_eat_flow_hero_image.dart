import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';

const _heroImageThumbSize = 64.0;

/// Shared hero image for inventory eat flows.
class InventoryEatFlowHeroImage extends StatelessWidget {
  /// Creates shared hero image.
  const InventoryEatFlowHeroImage({
    required this.fallback,
    super.key,
    this.imageUrl,
    this.imageBytes,
  });

  /// Optional image URL.
  final String? imageUrl;

  /// Optional local image bytes.
  final Uint8List? imageBytes;

  /// Fallback widget.
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);
    if (normalizedImageUrl == null) {
      return fallback;
    }

    return AppCachedNetworkImage(
      imageUrl: normalizedImageUrl,
      fit: BoxFit.cover,
      cacheWidth: (_heroImageThumbSize * MediaQuery.devicePixelRatioOf(context))
          .round(),
      cacheHeight:
          (_heroImageThumbSize * MediaQuery.devicePixelRatioOf(context))
              .round(),
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
