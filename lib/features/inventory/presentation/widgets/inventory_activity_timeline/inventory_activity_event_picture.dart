import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_image_tile.dart';

/// Leading picture of a Vorrat history row: the food's picture with the
/// action as a small round badge at its lower right, or only the action icon
/// when the event has no picture.
///
/// The picture is the one the food had when the event happened, so rows of
/// foods that are gone keep it. The row's text names the action, so the
/// picture adds nothing to the semantics.
class InventoryActivityEventPicture extends StatelessWidget {
  /// Creates the picture of [event].
  const new({required this.event, required this.tiltLeft, super.key});

  /// Key of the food picture of the event with [eventId].
  static Key pictureKey(String eventId) {
    return ValueKey<String>('inventory_activity_picture_$eventId');
  }

  /// Key of the action badge on the food picture of the event with
  /// [eventId].
  static Key badgeKey(String eventId) {
    return ValueKey<String>('inventory_activity_badge_$eventId');
  }

  /// Key of the action icon shown instead of a picture for the event with
  /// [eventId].
  static Key iconKey(String eventId) {
    return ValueKey<String>('inventory_activity_icon_$eventId');
  }

  /// The history event.
  final InventoryActivityEvent event;

  /// Whether the picture tilts to the left; rows alternate.
  final bool tiltLeft;

  @override
  Widget build(BuildContext context) {
    final icon = _actionIcon(event.type);
    final imageUrl = normalizeProductImageUrl(event.itemImageUrl);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppGraphit.stockRowPicture,
        child: imageUrl == null
            ? Center(child: Icon(icon, key: iconKey(event.id)))
            : Stack(
                key: pictureKey(event.id),
                clipBehavior: Clip.none,
                children: [
                  EatImageTile(
                    imageUrl: imageUrl,
                    size: AppGraphit.stockRowPicture,
                    angle: tiltLeft
                        ? -AppGraphit.pictureTilt
                        : AppGraphit.pictureTilt,
                    fallbackLetter: inventoryPictureLetter(event.itemName),
                  ),
                  Positioned(
                    right: -AppSpacing.xxs,
                    bottom: -AppSpacing.xxs,
                    child: _ActionBadge(key: badgeKey(event.id), icon: icon),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Small round badge with the action icon, framed in the row color so it
/// stands apart from the picture below it.
class _ActionBadge extends StatelessWidget {
  const new({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.surface,
          width: AppSizes.badgeBorderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: Icon(
          icon,
          size: AppGraphit.pictureBadgeIcon,
          color: colors.onPrimary,
        ),
      ),
    );
  }
}

IconData _actionIcon(InventoryActivityEventType type) {
  return switch (type) {
    InventoryActivityEventType.itemAdded => Icons.add,
    InventoryActivityEventType.itemConsumed => Icons.restaurant,
    InventoryActivityEventType.itemDiscarded => Icons.delete_outline,
    InventoryActivityEventType.itemDeleted => Icons.remove_circle_outline,
    InventoryActivityEventType.itemRestored => Icons.restore,
    InventoryActivityEventType.itemUsedInPreparedMeal => Icons.soup_kitchen,
    InventoryActivityEventType.itemReturnedFromPreparedMeal => Icons.undo,
  };
}
