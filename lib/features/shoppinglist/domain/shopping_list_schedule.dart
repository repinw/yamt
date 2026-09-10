import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

/// Local date without a time of day.
DateTime shoppingDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Applies each overdue schedule once, skipping missed intervals.
/// Schedule advancement and list reactivation are persisted together.
List<ShoppingListItem>? renewDueShoppingItems(
  List<ShoppingListItem> items,
  DateTime now,
) {
  final today = shoppingDate(now);
  var changed = false;
  final next = items
      .map((item) {
        final due = item.nextDueDate;
        if (item.repeatEveryDays <= 0 ||
            due == null ||
            shoppingDate(due).isAfter(today)) {
          return item;
        }
        changed = true;
        return item.copyWith(
          isArchived: false,
          quantity: !item.isArchived && item.quantity > 0
              ? item.quantity
              : item.repeatQuantity.clamp(1, 999),
          nextDueDate: _nextDate(due, today, item.repeatEveryDays),
        );
      })
      .toList(growable: false);
  return changed ? next : null;
}

DateTime _nextDate(DateTime due, DateTime today, int interval) {
  final elapsed = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(due.year, due.month, due.day)).inDays;
  final periods = elapsed ~/ interval + 1;
  return DateTime(due.year, due.month, due.day + periods * interval);
}

/// Hides saved products but removes ordinary list entries.
List<ShoppingListItem> removeShoppingItems(
  List<ShoppingListItem> items,
  bool Function(ShoppingListItem) shouldRemove,
) => [
  for (final item in items)
    if (!shouldRemove(item))
      item
    else if (item.isSaved)
      item.copyWith(quantity: 0, isArchived: true),
];

/// Configures and immediately applies a due schedule in one item update.
ShoppingListItem configureShoppingSchedule(
  ShoppingListItem item, {
  required int days,
  required int quantity,
  required DateTime now,
  DateTime? firstDue,
}) {
  final configured = item.copyWith(
    repeatEveryDays: days,
    repeatQuantity: quantity,
    nextDueDate: shoppingDate(
      firstDue ?? DateTime(now.year, now.month, now.day + days),
    ),
    clearNextDueDate: days == 0,
  );
  return renewDueShoppingItems([configured], now)?.single ?? configured;
}
