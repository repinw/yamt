import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

/// What finishing a trip does with the entries of a list. Immutable.
class ShoppingTripSummary {
  /// Sums up [items]: the ones in the cart leave the list, open ones stay,
  /// saved ones in the cart stay saved.
  factory(List<ShoppingListItem> items) {
    final cart = [
      for (final item in items)
        if (item.isInCart) item,
    ];
    return ShoppingTripSummary._(
      cart: List.unmodifiable(cart),
      openCount: items.where((item) => item.isOpen).length,
      savedNames: List.unmodifiable([
        for (final item in cart)
          if (item.isSaved) item.name,
      ]),
    );
  }

  const new _({
    required this.cart,
    required this.openCount,
    required this.savedNames,
  });

  /// The entries in the cart, which leave the list.
  final List<ShoppingListItem> cart;

  /// The entries still to buy, which stay.
  final int openCount;

  /// The names of saved entries in the cart, which stay saved.
  final List<String> savedNames;
}
