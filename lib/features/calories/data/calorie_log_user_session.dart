/// Defines the user session contract for calorie log operations.
abstract interface class CalorieLogUserSession {
  /// The current user id, or `null` if unauthenticated.
  String? get currentUserId;
}

/// Provides user session state backed by the current authentication user id.
class CurrentCalorieLogUserSession implements CalorieLogUserSession {
  /// Creates a session for the provided user id.
  const new({required this.currentUserId});

  @override
  final String? currentUserId;
}
