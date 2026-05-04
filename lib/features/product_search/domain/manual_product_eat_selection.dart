/// Generic eat selection returned by manual product flows.
class ManualProductEatSelection {
  /// Creates a generic eat selection.
  const ManualProductEatSelection({
    required this.inventoryAmount,
    required this.loggedAt,
    required this.mealType,
  });

  /// Inventory amount selected for the generated item.
  final int inventoryAmount;

  /// Date/time selected for logging.
  final DateTime loggedAt;

  /// Generic meal type id.
  final String mealType;
}
