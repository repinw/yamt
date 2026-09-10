import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

/// Presentation-ready partitions and totals of persisted shopping records.
class ShoppingListSections {
  /// Computes visible and saved sections once.
  ShoppingListSections(List<ShoppingListItem> items) {
    for (final item in items) {
      if (item.isSaved) saved.add(item);
      if (item.isArchived) continue;
      if (item.quantity > 0) {
        open.add(item);
      } else {
        done.add(item);
      }
      estimatedTotal += item.estimatedTotal;
      totalQuantity += item.quantity;
    }
  }

  /// Outstanding items.
  final open = <ShoppingListItem>[];

  /// Completed but not cleared items.
  final done = <ShoppingListItem>[];

  /// Favorites and recurring items, independent of their list status.
  final saved = <ShoppingListItem>[];

  /// Estimated price of the outstanding list.
  double estimatedTotal = 0;

  /// Total requested quantity.
  int totalQuantity = 0;

  /// Visible entry count.
  int get entryCount => open.length + done.length;
}
