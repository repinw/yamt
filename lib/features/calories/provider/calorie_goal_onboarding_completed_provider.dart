import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_goal_onboarding_preferences.dart';

part 'calorie_goal_onboarding_completed_provider.g.dart';

@riverpod
FutureOr<bool> calorieGoalOnboardingCompleted(Ref ref) async {
  String? userId;
  try {
    userId = _userIdFromAuthState(ref.watch(authStateChangesProvider));
  } catch (_) {
    return false;
  }
  if (userId == null) {
    return false;
  }

  final preferences = ref.watch(appPreferencesProvider);
  if (_hasCompletionMarker(preferences, userId)) {
    return true;
  }

  final settings = await ref
      .watch(calorieSettingsRepositoryProvider)
      .readSettings();
  if (!settings.hasGoal) {
    return false;
  }

  await markCalorieGoalOnboardingCompleted(
    ref,
    userId: userId,
    invalidate: false,
  );
  return true;
}

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
  await preferences.setString(
    calorieGoalOnboardingKeyForUser(resolvedUserId),
    calorieGoalOnboardingCompletedValue,
  );
  if (invalidate && ref.mounted) {
    ref.invalidate(calorieGoalOnboardingCompletedProvider);
  }
}

bool _hasCompletionMarker(AppPreferences preferences, String userId) {
  return preferences.getStringSync(calorieGoalOnboardingKeyForUser(userId)) ==
      calorieGoalOnboardingCompletedValue;
}

String? _currentUserId(Ref ref) {
  try {
    return _userIdFromAuthState(ref.read(authStateChangesProvider));
  } catch (_) {
    return null;
  }
}

String? _userIdFromAuthState(AsyncValue<User?> authState) {
  final userId = authState.asData?.value?.uid;
  if (userId == null || userId.isEmpty) {
    return null;
  }
  return userId;
}
