import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_inventory_food_picker/diary_inventory_food_image.dart';

/// A selectable inventory food row.
class DiaryInventoryFoodTile extends StatelessWidget {
  /// Creates an inventory food row.
  const new({
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imageUrl,
    this.imageBytes,
    super.key,
  });

  /// Icon shown when no image is available.
  final IconData fallbackIcon;

  /// Food name.
  final String title;

  /// Optional food subtitle.
  final String? subtitle;

  /// Selection callback.
  final VoidCallback onTap;

  /// Optional remote image URL.
  final String? imageUrl;

  /// Optional local image bytes.
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        leading: DiaryInventoryFoodImage(
          fallbackIcon: fallbackIcon,
          imageUrl: imageUrl,
          imageBytes: imageBytes,
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null || subtitle!.trim().isEmpty
            ? null
            : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
