import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';

/// Square picture of a meal: its stored photo, its image link, the images of
/// its foods, or its first letter.
class CookbookMealPicture extends ConsumerWidget {
  /// Creates the picture of [meal] with the edge length [size].
  const new({required this.meal, this.size = double.infinity, super.key});

  /// The meal or template.
  final PreparedMeal meal;

  /// Edge length; [double.infinity] fills the parent.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageRef = maybeLocalImageAssetRef(meal.imageAssetId);
    final imageBytes = imageRef == null
        ? null
        : ref.watch(localImageBytesProvider(imageRef)).asData?.value;
    return PreparedMealCover(
      label: meal.name,
      imageBytes: imageBytes,
      imageUrl: meal.imageUrl,
      componentImageUrls: [
        for (final component in meal.components) component.imageUrl,
      ],
      size: size,
      borderRadius: BorderRadius.zero,
    );
  }
}
