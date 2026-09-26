import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';

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
    final urls = componentImageUrls
        .map(normalizeProductImageUrl)
        .nonNulls
        .take(_maxCollageImages)
        .toList(growable: false);
    if (urls.isEmpty) {
      return null;
    }
    Widget image(String url) => AppCachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    Widget row(List<String> rowUrls) => Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSizes.dividerThickness,
        children: [for (final url in rowUrls) Expanded(child: image(url))],
      ),
    );
    if (urls.length < 3) {
      return Column(
        key: const Key('prepared_meal_cover_collage'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [row(urls)],
      );
    }
    return Column(
      key: const Key('prepared_meal_cover_collage'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSizes.dividerThickness,
      children: [row(urls.sublist(0, 2)), row(urls.sublist(2))],
    );
  }
}

const _maxCollageImages = 4;

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
