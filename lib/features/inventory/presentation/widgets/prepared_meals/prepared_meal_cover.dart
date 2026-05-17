import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';

/// Defines prepared meal cover.
class PreparedMealCover extends StatelessWidget {
  /// The prepared meal cover.
  const PreparedMealCover({
    required this.label,
    required this.imageBytes,
    super.key,
    this.imageUrl,
    this.size = 64,
    this.borderRadius,
  });

  /// The label.
  final String label;

  /// The image bytes.
  final Uint8List? imageBytes;

  /// The image url.
  final String? imageUrl;

  /// The size.
  final double size;

  /// The border radius.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius =
        borderRadius ?? BorderRadius.circular(AppEditorial.cardRadius);
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.14),
            colors.surfaceContainerLow,
          ],
        ),
        borderRadius: radius,
      ),
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: radius,
          child: imageBytes != null
              ? Image.memory(
                  imageBytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return _PreparedMealCoverFallback(label: label);
                  },
                )
              : normalizedImageUrl != null
              ? AppCachedNetworkImage(
                  imageUrl: normalizedImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return _PreparedMealCoverFallback(label: label);
                  },
                )
              : _PreparedMealCoverFallback(label: label),
        ),
      ),
    );
  }
}

class _PreparedMealCoverFallback extends StatelessWidget {
  const _PreparedMealCoverFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        initial.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
