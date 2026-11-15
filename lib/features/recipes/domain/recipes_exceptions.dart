/// A recipes failure that the UI tells apart.
sealed class RecipesException implements Exception {
  /// Creates the exception.
  const new();
}

/// The cook run [runId] is gone: finished or discarded, maybe on another
/// device. A change to it is not written.
final class CookRunGoneException extends RecipesException {
  /// Creates the exception for the run [runId].
  const new(this.runId);

  /// The run that is gone.
  final String runId;

  @override
  String toString() => 'CookRunGoneException: $runId';
}
