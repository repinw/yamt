import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Uses the shared network image cache so remote images stay fast and
/// consistent across the app.
class AppCachedNetworkImage extends StatelessWidget {
  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
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

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? cacheWidth;
  final int? cacheHeight;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final Alignment alignment;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final imageProvider = ResizeImage.resizeIfNeeded(
      cacheWidth,
      cacheHeight,
      CachedNetworkImageProvider(imageUrl),
    );

    return Image(
      image: imageProvider,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: errorBuilder,
    );
  }
}
