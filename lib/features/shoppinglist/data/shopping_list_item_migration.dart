/// Temporary migration, added in 3.11.0: removed in 3.14.0. Rewrites a stored
/// shopping list item from before `is_done` into the shape with it.
///
/// Up to 3.10.0 a ticked-off entry was an entry with quantity zero that was
/// not archived, so the asked quantity is lost. Such an entry becomes done
/// with the quantity of its schedule, or one without a schedule. Every other
/// entry is not done. A document that has `is_done` is returned as it is.
Map<String, dynamic> migrateStoredShoppingListItem(Map<String, dynamic> json) {
  if (json.containsKey('is_done')) {
    return json;
  }
  final tickedOff = json['quantity'] == 0 && json['is_archived'] != true;
  if (!tickedOff) {
    return {...json, 'is_done': false};
  }
  final repeatEveryDays = json['repeat_every_days'];
  final repeatQuantity = json['repeat_quantity'];
  final scheduled = repeatEveryDays is num && repeatEveryDays > 0;
  return {
    ...json,
    'is_done': true,
    'quantity': scheduled && repeatQuantity is num && repeatQuantity >= 1
        ? repeatQuantity.toInt()
        : 1,
  };
}
