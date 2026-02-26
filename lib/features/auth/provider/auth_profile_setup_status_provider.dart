import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/domain/'
    'auth_profile_setup_preferences.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

part 'auth_profile_setup_status_provider.g.dart';

@riverpod
bool authProfileSetupCompleted(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  final userId = authState.asData?.value?.uid;
  if (userId == null) {
    return false;
  }

  final preferences = ref.watch(appPreferencesProvider);
  final key = AuthProfileSetupPreferences.keyForUser(userId);
  return preferences.getStringSync(key) ==
      AuthProfileSetupPreferences.completedValue;
}
