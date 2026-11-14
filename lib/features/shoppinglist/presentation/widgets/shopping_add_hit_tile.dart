import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_add_hits.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf_placement.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shelf/shopping_item_disc.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shelf/shopping_shelf_labels.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A known product in the add sheet: its picture, its shelf and why it is
/// offered. A tap puts it on the list.
class ShoppingAddHitTile extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.hit,
    required this.placement,
    required this.quantity,
    required this.onTap,
    super.key,
  });

  /// The offered product.
  final ShoppingAddHit hit;

  /// Shelf and picture of the product.
  final ShoppingShelfPlacement placement;

  /// How many a tap adds.
  final int quantity;

  /// Puts the product on the list.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reason = switch (hit.source) {
      ShoppingAddHitSource.saved => l10n.shoppingAddHitSaved,
      ShoppingAddHitSource.outOfStock => l10n.shoppingListOutOfStock,
      ShoppingAddHitSource.lowStock => l10n.shoppingListLowStock,
      ShoppingAddHitSource.purchased => l10n.shoppingListPurchaseCount(
        hit.purchaseCount,
      ),
      ShoppingAddHitSource.catalog => null,
    };
    final brand = hit.brand?.trim() ?? '';
    final details = [
      if (placement.isAssigned) shoppingShelfLabel(l10n, placement.shelf),
      if (brand.isNotEmpty) brand,
      ?reason,
    ].join(l10n.shoppingDetailSeparator);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      leading: ShoppingItemDisc(
        icon: placement.icon,
        size: AppShopping.itemDisc,
      ),
      title: Text(hit.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: details.isEmpty ? null : Text(details),
      trailing: quantity > 1
          ? Text(l10n.shoppingAddQuantity(quantity))
          : const Icon(Icons.add_rounded),
      onTap: onTap,
    );
  }
}
