import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/onboarding/domain/'
    'calorie_goal_onboarding_preferences.dart';

part 'calorie_goal_onboarding_completed_provider.g.dart';

/// Calorie goal onboarding completed.
///
/// The user id comes from the data key session, not from the auth state. The
/// settings repository depends on the same session, so after an account
/// switch the provider rebuilds once and never reads the settings of the new
/// user with the data key of the previous one.
@Riverpod(keepAlive: true)
FutureOr<bool> calorieGoalOnboardingCompleted(Ref ref) async {
  final preferences = ref.watch(appPreferencesProvider);
  final dataKeySession = ref.watch(userDataKeySessionProvider);
  final settingsRepository = ref.watch(calorieSettingsRepositoryProvider);
  if (dataKeySession.isLoading) {
    return await Completer<bool>().future;
  }
  final userId = switch (dataKeySession.requireValue) {
    UserDataKeyReady(:final uid) ||
    UserDataKeyRecoveryRequired(:final uid) => uid,
    UserDataKeySignedOut() => null,
  };
  if (userId == null) {
    return false;
  }

  if (_hasCompletionMarker(preferences, userId)) {
    return true;
  }

  final settings = await settingsRepository.readSettings();
  if (!ref.mounted) {
    return false;
  }
  if (!settings.hasGoal) {
    return false;
  }

  await _writeCompletionMarker(preferences, userId);
  return true;
}

/// Marks calorie goal onboarding of [userId] as completed.
Future<void> markCalorieGoalOnboardingCompleted(
  Ref ref, {
  required String userId,
}) async {
  final preferences = ref.read(appPreferencesProvider);
  await _writeCompletionMarker(preferences, userId);
  if (ref.mounted) {
    ref.invalidate(calorieGoalOnboardingCompletedProvider);
  }
}

bool _hasCompletionMarker(AppPreferences preferences, String userId) {
  return preferences.getStringSync(calorieGoalOnboardingKeyForUser(userId)) ==
      calorieGoalOnboardingCompletedValue;
}

Future<void> _writeCompletionMarker(AppPreferences preferences, String userId) {
  return preferences.setString(
    calorieGoalOnboardingKeyForUser(userId),
    calorieGoalOnboardingCompletedValue,
  );
}
