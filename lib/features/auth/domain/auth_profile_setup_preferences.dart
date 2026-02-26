abstract final class AuthProfileSetupPreferences {
  static const String _keyPrefix = 'auth_profile_setup_completed';
  static const String completedValue = '1';

  static String keyForUser(String userId) {
    return '$_keyPrefix:$userId';
  }
}
