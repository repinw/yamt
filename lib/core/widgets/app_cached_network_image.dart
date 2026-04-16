import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Uses the shared network image cache so remote images stay fast and
/// consistent across the app.
class AppCachedNetworkImage extends StatelessWidget {
  /// Creates cached network image widget.
  const AppCachedNetworkImage({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit,
    this.cacheWidth,
    this.cacheHeight,
    this.filterQuality = FilterQuality.medium,
    this.gaplessPlayback = false,
    this.alignment = Alignment.center,
    this.errorBuilder,
  });

  /// Remote image URL.
  final String imageUrl;

  /// Target width.
  final double? width;

  /// Target height.
  final double? height;

  /// Box fit applied to the image.
  final BoxFit? fit;

  /// In-memory cache width.
  final int? cacheWidth;

  /// In-memory cache height.
  final int? cacheHeight;

  /// Filter quality used while painting image.
  final FilterQuality filterQuality;

  /// Whether old image should stay visible during URL changes.
  final bool gaplessPlayback;

  /// Alignment used while painting image.
  final Alignment alignment;

  /// Optional error widget builder.
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return errorBuilder?.call(context, Exception('Empty URL'), null) ??
          _buildPlaceholder(context);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      useOldImageOnUrlChange: gaplessPlayback,
      filterQuality: filterQuality,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      maxWidthDiskCache: cacheWidth,
      maxHeightDiskCache: cacheHeight,
      fadeInDuration: const Duration(milliseconds: 180),
      fadeOutDuration: const Duration(milliseconds: 120),
      placeholder: (context, _) => _buildPlaceholder(context),
      errorWidget: errorBuilder == null
          ? null
          : (context, _, error) => errorBuilder!(context, error, null),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = _resolveShortestSide(constraints);
        if (shortestSide == null || shortestSide < 32) {
          return const SizedBox.expand();
        }

        final colors = Theme.of(context).colorScheme;
        final iconSize = shortestSide < 56 ? 16.0 : 20.0;
        return ColoredBox(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.24),
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: iconSize,
              color: colors.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  double? _resolveShortestSide(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final hasBoundedWidth = width.isFinite && width > 0;
    final hasBoundedHeight = height.isFinite && height > 0;

    if (hasBoundedWidth && hasBoundedHeight) {
      return math.min(width, height);
    }
    if (hasBoundedWidth) {
      return width;
    }
    if (hasBoundedHeight) {
      return height;
    }
    return null;
  }
}
