/// Defines the user session contract for calorie product cache operations.
abstract interface class CalorieProductCacheUserSession {
  /// The current user id, or `null` if unauthenticated.
  String? get currentUserId;
}

/// Provides user session state backed by the current authentication user id.
class CurrentCalorieProductCacheUserSession
    implements CalorieProductCacheUserSession {
  /// Creates a session for the provided user id.
  const new({required this.currentUserId});

  @override
  final String? currentUserId;
}
