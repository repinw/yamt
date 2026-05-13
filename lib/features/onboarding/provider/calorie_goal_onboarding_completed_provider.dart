import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/onboarding/domain/'
    'calorie_goal_onboarding_preferences.dart';

part 'calorie_goal_onboarding_completed_provider.g.dart';

/// Calorie goal onboarding completed.
@Riverpod(keepAlive: true)
FutureOr<bool> calorieGoalOnboardingCompleted(Ref ref) async {
  if (!ref.mounted) {
    return false;
  }
  final userId = _userIdFromAuthState(ref.watch(authStateChangesProvider));
  if (userId == null) {
    return false;
  }

  final preferences = ref.watch(appPreferencesProvider);
  if (_hasCompletionMarker(preferences, userId)) {
    return true;
  }

  final settingsRepository = ref.watch(calorieSettingsRepositoryProvider);
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

/// Mark calorie goal onboarding completed.
Future<void> markCalorieGoalOnboardingCompleted(
  Ref ref, {
  String? userId,
  bool invalidate = true,
}) async {
  final resolvedUserId = userId ?? _currentUserId(ref);
  if (resolvedUserId == null || resolvedUserId.isEmpty) {
    return;
  }

  final preferences = ref.read(appPreferencesProvider);
  await _writeCompletionMarker(preferences, resolvedUserId);
  if (invalidate && ref.mounted) {
    ref.invalidate(calorieGoalOnboardingCompletedProvider);
  }
}

/// Mark calorie goal onboarding completed from a provider container.
Future<void> markCalorieGoalOnboardingCompletedFromContainer(
  ProviderContainer container, {
  String? userId,
  bool invalidate = true,
}) async {
  final resolvedUserId = userId ?? _currentUserIdFromContainer(container);
  if (resolvedUserId == null || resolvedUserId.isEmpty) {
    return;
  }

  final preferences = container.read(appPreferencesProvider);
  await _writeCompletionMarker(preferences, resolvedUserId);
  if (invalidate) {
    container.invalidate(calorieGoalOnboardingCompletedProvider);
  }
}

bool _hasCompletionMarker(AppPreferences preferences, String userId) {
  return preferences.getStringSync(calorieGoalOnboardingKeyForUser(userId)) ==
      calorieGoalOnboardingCompletedValue;
}

Future<void> _writeCompletionMarker(
  AppPreferences preferences,
  String userId,
) {
  return preferences.setString(
    calorieGoalOnboardingKeyForUser(userId),
    calorieGoalOnboardingCompletedValue,
  );
}

String? _currentUserId(Ref ref) {
  if (!ref.mounted) {
    return null;
  }
  return _userIdFromAuthState(ref.read(authStateChangesProvider));
}

String? _currentUserIdFromContainer(ProviderContainer container) {
  return _userIdFromAuthState(container.read(authStateChangesProvider));
}

String? _userIdFromAuthState(AsyncValue<User?> authState) {
  final userId = authState.asData?.value?.uid;
  if (userId == null || userId.isEmpty) {
    return null;
  }
  return userId;
}
