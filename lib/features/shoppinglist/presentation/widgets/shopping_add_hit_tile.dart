import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_add_hits.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A known product in the add sheet; a tap puts it on the list.
class ShoppingAddHitTile extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.hit,
    required this.quantity,
    required this.onTap,
    super.key,
  });

  /// The offered product.
  final ShoppingAddHit hit;

  /// How many a tap adds.
  final int quantity;

  /// Puts the product on the list.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final source = switch (hit.source) {
      ShoppingAddHitSource.saved => l10n.shoppingAddHitSaved,
      ShoppingAddHitSource.outOfStock => l10n.shoppingListOutOfStock,
      ShoppingAddHitSource.lowStock => l10n.shoppingListLowStock,
      ShoppingAddHitSource.purchased => l10n.shoppingListPurchaseCount(
        hit.purchaseCount,
      ),
    };
    final brand = hit.brand?.trim() ?? '';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      leading: Icon(
        hit.source == ShoppingAddHitSource.saved
            ? Icons.star_rounded
            : Icons.kitchen_outlined,
      ),
      title: Text(hit.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        brand.isEmpty
            ? source
            : l10n.shoppingListSuggestionBrandReason(brand, source),
      ),
      trailing: quantity > 1
          ? Text(l10n.shoppingAddQuantity(quantity))
          : const Icon(Icons.add_rounded),
      onTap: onTap,
    );
  }
}
