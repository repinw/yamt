/// Defines inventory user session.
abstract interface class InventoryUserSession {
  /// The id of the household whose data the repository reads.
  String? get householdId;
}
