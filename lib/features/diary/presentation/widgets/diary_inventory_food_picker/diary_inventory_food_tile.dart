import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
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
    this.isMuted = false,
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

  /// Greys the row out for a food that cannot be eaten yet; it stays
  /// tappable to finish the food.
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final muted = isMuted
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : null;
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        textColor: muted,
        iconColor: muted,
        leading: Opacity(
          opacity: isMuted ? AppGraphit.pendingRowOpacity : 1,
          child: DiaryInventoryFoodImage(
            fallbackIcon: fallbackIcon,
            imageUrl: imageUrl,
            imageBytes: imageBytes,
          ),
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
