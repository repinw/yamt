/// Defines shopping list user session.
abstract interface class ShoppingListUserSession {
  /// The id of the household whose data the repository reads.
  String? get householdId;
}
