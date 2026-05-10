import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';

/// Square cover for kitchen utensils.
class KitchenUtensilCover extends StatelessWidget {
  /// Creates cover.
  const KitchenUtensilCover({
    required this.label,
    required this.imageBytes,
    super.key,
    this.imageUrl,
    this.size = 64,
    this.borderRadius,
  });

  /// Fallback label.
  final String label;

  /// In-memory image bytes.
  final Uint8List? imageBytes;

  /// Network image URL.
  final String? imageUrl;

  /// Square size.
  final double size;

  /// Border radius.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius =
        borderRadius ?? BorderRadius.circular(AppInventoryEditorial.cardRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
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
                    return _KitchenUtensilCoverFallback(label: label);
                  },
                )
              : imageUrl != null
              ? AppCachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return _KitchenUtensilCoverFallback(label: label);
                  },
                )
              : _KitchenUtensilCoverFallback(label: label),
        ),
      ),
    );
  }
}

class _KitchenUtensilCoverFallback extends StatelessWidget {
  const _KitchenUtensilCoverFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final colors = Theme.of(context).colorScheme;
    if (trimmed.isEmpty) {
      return Icon(Icons.kitchen_rounded, color: colors.primary);
    }

    return Center(
      child: Text(
        trimmed.substring(0, 1).toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
