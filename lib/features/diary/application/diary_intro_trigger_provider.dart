import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/domain/diary_intro_data.dart';
import 'package:yamt/features/diary/domain/diary_intro_preferences.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';

part 'diary_intro_trigger_provider.g.dart';

/// Emits data for the first-week diary intro when it should auto-open.
@riverpod
DiaryIntroTrigger? diaryIntroTrigger(Ref ref) {
  final weeklyCheckInState = ref.watch(diaryWeeklyCheckInDataProvider);
  final weeklyCheckIn = weeklyCheckInState.value;
  final hasPendingWeeklyCheckInDialog =
      weeklyCheckIn?.pendingWeeklyCheckIn != null &&
      weeklyCheckIn?.shouldAutoOpen == true;
  if (hasPendingWeeklyCheckInDialog) {
    return null;
  }

  final settings = ref.watch(diaryCalorieGoalSettingsProvider).value;
  if (settings == null) {
    return null;
  }
  if (settings.hasLearnedTdee || !DiaryIntroData.canBuildFrom(settings)) {
    return null;
  }

  final preferences = ref.watch(appPreferencesProvider);
  if (DiaryIntroPreferences.isSeen(preferences)) {
    return null;
  }

  final healthConnectionState = ref.watch(healthConnectionControllerProvider);
  if (healthConnectionState.isLoading) {
    return null;
  }

  return DiaryIntroTrigger(
    preferences: preferences,
    introData: DiaryIntroData.fromSettings(settings),
    healthStatus: healthConnectionState.value,
  );
}

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
