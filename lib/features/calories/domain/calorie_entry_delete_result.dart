/// Defines calorie entry delete failure reason.
enum CalorieEntryDeleteFailureReason {
  /// Delete failed.
  deleteFailed,

  /// Restore failed.
  restoreFailed,

  /// Restore source was already removed from inventory.
  sourceMissing,
}

/// Defines calorie entry delete result.
class CalorieEntryDeleteResult {
  const new _({
    required this.isSuccess,
    required this.restoredToInventory,
    this.failureReason,
  });

  /// Creates a [CalorieEntryDeleteResult] for success.
  const new success({required bool restoredToInventory})
    : this._(isSuccess: true, restoredToInventory: restoredToInventory);

  /// Creates a [CalorieEntryDeleteResult] for failure.
  const new failure(CalorieEntryDeleteFailureReason reason)
    : this._(
        isSuccess: false,
        restoredToInventory: false,
        failureReason: reason,
      );

  /// Whether success.
  final bool isSuccess;

  /// The restored to inventory.
  final bool restoredToInventory;

  /// The failure reason.
  final CalorieEntryDeleteFailureReason? failureReason;
}
