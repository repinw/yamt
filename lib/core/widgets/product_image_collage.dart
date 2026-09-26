import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';

/// The product images shown in a collage: normalized, without nulls, at
/// most [AppSizes.collageImages]. Empty when no food has an image.
List<String> productCollageImageUrls(Iterable<String?> imageUrls) {
  return imageUrls
      .map(normalizeProductImageUrl)
      .nonNulls
      .take(AppSizes.collageImages)
      .toList(growable: false);
}

/// Product images of several foods as one picture: two side by side,
/// three or four in a grid. Fills the space it is given.
class ProductImageCollage extends StatelessWidget {
  /// Creates the collage from [imageUrls], see [productCollageImageUrls].
  const new({required this.imageUrls, super.key});

  /// Normalized image addresses, one to four.
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSizes.dividerThickness,
      children: [
        if (imageUrls.length < 3)
          row(imageUrls)
        else ...[
          row(imageUrls.sublist(0, 2)),
          row(imageUrls.sublist(2)),
        ],
      ],
    );
  }
}
