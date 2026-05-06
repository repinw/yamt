import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/domain/diary_intro_preferences.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_intro_dialog.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';

/// Emits data for the first-week diary intro when it should auto-open.
final Provider<DiaryIntroTrigger?>
diaryIntroTriggerProvider = Provider.autoDispose<DiaryIntroTrigger?>((ref) {
  final weeklyCheckInState = ref.watch(calorieWeeklyCheckInViewModelProvider);
  final weeklyCheckIn = weeklyCheckInState.value;
  final hasAutoOpeningWeeklyCheckIn =
      weeklyCheckIn?.pendingWeeklyCheckIn != null &&
      weeklyCheckIn?.shouldAutoOpen == true;
  if (hasAutoOpeningWeeklyCheckIn) {
    return null;
  }

  final settings = ref.watch(calorieGoalControllerProvider).value;
  final healthConnectionState = ref.watch(healthConnectionControllerProvider);
  if (settings == null || healthConnectionState.isLoading) {
    return null;
  }
  if (settings.hasLearnedTdee || !DiaryIntroData.canBuildFrom(settings)) {
    return null;
  }

  final preferences = ref.watch(appPreferencesProvider);
  if (DiaryIntroPreferences.isSeen(preferences)) {
    return null;
  }

  return DiaryIntroTrigger(
    preferences: preferences,
    introData: DiaryIntroData.fromSettings(settings),
    healthStatus: healthConnectionState.value,
  );
});

/// Data needed by the diary page to present the intro dialog.
@immutable
class DiaryIntroTrigger {
  /// Creates a diary intro trigger.
  const DiaryIntroTrigger({
    required this.preferences,
    required this.introData,
    required this.healthStatus,
  });

  /// Preference storage used to mark the intro as seen.
  final AppPreferences preferences;

  /// Intro copy and goal values derived from current calorie settings.
  final DiaryIntroData introData;

  /// Current Health Connect status used to build the optional action.
  final HealthConnectionStatus? healthStatus;
}
