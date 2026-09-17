import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';

/// Reusable thumbnail image or fallback icon for a product candidate.
class ProductCandidateThumbnail extends StatelessWidget {
  /// Creates a [ProductCandidateThumbnail].
  const new({this.imageUrl, this.size = 36, this.borderRadius = 6, super.key});

  /// Image URL of the product.
  final String? imageUrl;

  /// Width and height of the thumbnail square.
  final double size;

  /// Corner radius of the thumbnail.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: AppCachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(Icons.inventory_2_outlined, size: size * 0.5),
    );
  }
}
