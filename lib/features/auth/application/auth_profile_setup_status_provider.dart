import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/domain/'
    'auth_profile_setup_preferences.dart';

part 'auth_profile_setup_status_provider.g.dart';

/// Whether the signed-in user has a name, so the router skips the name setup.
///
/// The name lives on the account, so signing in to an existing account on a
/// new device counts as set up. The stored mark covers a linked guest whose
/// account has no name yet.
@Riverpod(keepAlive: true)
bool authProfileSetupCompleted(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.asData?.value;
  if (user == null) {
    return false;
  }
  if (user.displayName?.trim().isNotEmpty ?? false) {
    return true;
  }
  final userId = user.uid;

  final preferences = ref.watch(appPreferencesProvider);
  final key = AuthProfileSetupPreferences.keyForUser(userId);
  return preferences.getStringSync(key) ==
      AuthProfileSetupPreferences.completedValue;
}

/// Marks the profile of [userId] as set up, so the router skips the name
/// setup for it.
Future<void> markAuthProfileSetupCompleted(
  AppPreferences preferences,
  String userId,
) {
  return preferences.setString(
    AuthProfileSetupPreferences.keyForUser(userId),
    AuthProfileSetupPreferences.completedValue,
  );
}
