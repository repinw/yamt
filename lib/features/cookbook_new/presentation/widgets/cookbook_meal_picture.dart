import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';

/// Square picture of a meal: its stored photo, its image link, the images of
/// its foods, or its first letter.
class CookbookMealPicture extends ConsumerWidget {
  /// Creates the picture of [meal] with the edge length [size].
  /// Without [showInitial], a missing photo leaves the plain background.
  new({
    required PreparedMeal meal,
    this.size = double.infinity,
    this.background,
    bool showInitial = true,
    super.key,
  }) : label = showInitial ? meal.name : null,
       imageAssetId = meal.imageAssetId,
       imageUrl = meal.imageUrl,
       componentImageUrls = [
         for (final component in meal.components) component.imageUrl,
       ];

  /// Creates the picture of the cook run [run] shown as [name]: the photo of
  /// its recipe, or the first letter of [name].
  new run(
    CookRun run, {
    required String name,
    this.size = double.infinity,
    super.key,
  }) : label = name,
       imageAssetId = run.imageAssetId,
       imageUrl = run.imageUrl,
       componentImageUrls = const [],
       background = null;

  /// The name whose first letter stands in for a missing photo; `null`
  /// for none.
  final String? label;

  /// The stored photo.
  final String? imageAssetId;

  /// The image link.
  final String? imageUrl;

  /// The images of the foods.
  final List<String?> componentImageUrls;

  /// Edge length; [double.infinity] fills the parent.
  final double size;

  /// The plain color under the picture; `null` for the theme's gradient.
  final Color? background;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageRef = maybeLocalImageAssetRef(imageAssetId);
    final imageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    return PreparedMealCover(
      label: label,
      imageBytes: imageBytes,
      imageUrl: imageUrl,
      componentImageUrls: componentImageUrls,
      size: size,
      borderRadius: BorderRadius.zero,
      background: background,
    );
  }
}
