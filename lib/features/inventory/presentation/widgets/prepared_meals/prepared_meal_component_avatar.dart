import 'package:flutter/material.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';

/// Defines prepared meal component avatar.
class PreparedMealComponentAvatar extends StatelessWidget {
  /// The prepared meal component avatar.
  const PreparedMealComponentAvatar({
    required this.label,
    required this.imageUrl,
    super.key,
    this.size = 24,
  });

  /// The label.
  final String label;

  /// The image url.
  final String? imageUrl;

  /// The size.
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = normalizeProductImageUrl(imageUrl);
    if (normalizedImageUrl != null) {
      return SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: AppCachedNetworkImage(
            imageUrl: normalizedImageUrl,
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
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primary.withValues(alpha: 0.12),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Text(
            initial.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
