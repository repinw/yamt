import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/core/widgets/product_image_collage.dart';

/// Cover image of a prepared meal.
///
/// Without an own image the cover shows the product images of the meal's
/// foods: two side by side, three or four in a grid.
class PreparedMealCover extends StatelessWidget {
  /// The prepared meal cover.
  const new({
    required this.label,
    required this.imageBytes,
    super.key,
    this.imageUrl,
    this.componentImageUrls = const <String?>[],
    this.size = 64,
    this.borderRadius,
  });

  /// The label.
  final String label;

  /// The image bytes.
  final Uint8List? imageBytes;

  /// The image url.
  final String? imageUrl;

  /// Product images of the meal's foods, used without an own image.
  final List<String?> componentImageUrls;

  /// The size.
  final double size;

  /// The border radius.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.xl);
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
              : _componentCollage() ?? _PreparedMealCoverFallback(label: label),
        ),
      ),
    );
  }

  Widget? _componentCollage() {
    final urls = productCollageImageUrls(componentImageUrls);
    if (urls.isEmpty) {
      return null;
    }
    return ProductImageCollage(
      key: const Key('prepared_meal_cover_collage'),
      imageUrls: urls,
    );
  }
}

class _PreparedMealCoverFallback extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1);
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        initial.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: colors.primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}
