/// Reads the user's steps from Health Connect or Apple Health. Steps have
/// their own read permission, apart from the weight access of the Health
/// connection, so declining them never breaks the weights.
abstract interface class HealthStepsService {
  /// Asks the platform for read access to steps. Returns false when the
  /// user declined. Apple Health never says whether reading was allowed, so
  /// there it returns true once the dialog closed.
  Future<bool> requestAccess();

  /// Total steps from [startInclusive] to [endExclusive], each step counted
  /// once across the apps and devices that recorded it, or null when Health
  /// Connect has no steps permission. Apple Health hides a missing
  /// permission and answers 0.
  Future<int?> loadSteps({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });
}
