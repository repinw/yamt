/// Why an Inventory workflow failed in a way the UI tells apart: so far,
/// why a plan could not be eaten or its eat could not be undone.
sealed class InventoryException implements Exception {
  const new(this.message);

  /// What failed.
  final String message;

  @override
  String toString() => 'InventoryException: $message';
}

/// Eating the plan or undoing its eat failed.
final class PlanAcceptFailedException extends InventoryException {
  /// Creates the exception for [message].
  const new(super.message);
}

/// The planned meal is still in the pot, so it can be eaten once "Gekocht"
/// has given it its portions.
final class PlanMealInPotException extends InventoryException {
  /// Creates the exception for [message].
  const new(super.message);
}

/// The planned meal or recipe still has open rows, so the plan is a reminder
/// that can be eaten once every row is filled.
final class PlanNutritionPendingException extends InventoryException {
  /// Creates the exception for [message].
  const new(super.message);
}

/// The planned meal or recipe of a reminder is gone, so the plan can only be
/// removed.
final class PlanSourceGoneException extends InventoryException {
  /// Creates the exception for [message].
  const new(super.message);
}
