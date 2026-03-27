import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/inventory/domain/product_image_url.dart';

class PreparedMealComponentAvatar extends StatelessWidget {
  const PreparedMealComponentAvatar({
    super.key,
    required this.label,
    required this.imageUrl,
    this.size = 24,
  });

  final String label;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);
    if (normalizedImageUrl != null) {
      return SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: Image.network(
            normalizedImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return _PreparedMealComponentAvatarFallback(
                label: label,
                size: size,
              );
            },
          ),
        ),
      );
    }

    return _PreparedMealComponentAvatarFallback(label: label, size: size);
  }
}

class _PreparedMealComponentAvatarFallback extends StatelessWidget {
  const _PreparedMealComponentAvatarFallback({
    required this.label,
    required this.size,
  });

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppInventoryEditorial.primary.withValues(alpha: 0.12),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Text(
            initial.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppInventoryEditorial.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
