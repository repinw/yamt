import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/data/local_image_asset_ref.dart';
import 'package:yamt/core/data/local_image_store_provider.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_image_tile.dart';

/// Tilted, framed picture of a Vorrat entry: its photo, the photos of a
/// meal's ingredients, or the first letter of its name.
class InventoryEntryPicture extends ConsumerWidget {
  /// Creates the picture.
  const new({
    required this.entry,
    required this.size,
    required this.tiltLeft,
    super.key,
  });

  /// The food or meal.
  final InventoryListEntry entry;

  /// Edge length.
  final double size;

  /// Whether the frame tilts to the left.
  final bool tiltLeft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = entry.name.trim();
    final letter = name.isEmpty ? null : name.characters.first.toUpperCase();
    final angle = tiltLeft ? -AppGraphit.pictureTilt : AppGraphit.pictureTilt;
    return switch (entry) {
      InventoryFoodEntry(:final item) => EatImageTile(
        imageUrl: item.imageUrl,
        size: size,
        angle: angle,
        fallbackLetter: letter,
      ),
      InventoryMealEntry(:final meal) => EatImageTile(
        imageUrl: meal.imageUrl,
        imageBytes: switch (maybeLocalImageAssetRef(meal.imageAssetId)) {
          final imageRef? =>
            ref.watch(localImageBytesProvider(imageRef)).asData?.value,
          null => null,
        },
        collageImageUrls: [
          for (final component in meal.components) component.imageUrl,
        ],
        size: size,
        angle: angle,
        fallbackLetter: letter,
      ),
    };
  }
}
