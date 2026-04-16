/// Defines auth profile setup preferences.
abstract final class AuthProfileSetupPreferences {
  static const String _keyPrefix = 'auth_profile_setup_completed';

  /// The completed value.
  static const String completedValue = '1';

  /// Key for user.
  static String keyForUser(String userId) {
    return '$_keyPrefix:$userId';
  }
}
