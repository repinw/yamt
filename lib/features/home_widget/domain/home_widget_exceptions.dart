/// Errors of the home-screen widget feature.
sealed class HomeWidgetException implements Exception {
  const new();
}

/// Thrown when the platform could not store the widget snapshot or redraw
/// the widget.
final class HomeWidgetSyncFailedException extends HomeWidgetException {
  /// Creates the sync-failed exception.
  const new(this.cause);

  /// Underlying platform error.
  final Object cause;

  @override
  String toString() => 'HomeWidgetSyncFailedException($cause)';
}
