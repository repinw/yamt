import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';

part 'diary_day_type_provider.g.dart';

/// Day type of [day], or `null` while no calorie goal exists.
@riverpod
DiaryDayTypeStatus? diaryDayTypeStatus(Ref ref, DateTime day) {
  final settings = ref.watch(diaryCalorieGoalSettingsProvider).value;
  if (settings == null || !settings.hasGoal) {
    return null;
  }
  return DiaryDayTypeStatus.fromSettings(settings, day);
}

/// Adapts calorie goal mutations for changing a diary day type.
///
/// Kept alive because updates keep running after the picker sheet closes.
@Riverpod(keepAlive: true)
DiaryDayTypeUpdater diaryDayTypeUpdater(Ref ref) {
  return DiaryDayTypeUpdater(ref);
}

/// Changes the day type of a diary day through the calorie goal controller.
class DiaryDayTypeUpdater {
  /// Creates a day type updater.
  const new(this._ref);

  final Ref _ref;

  /// Marks [day] as [type].
  Future<void> select(DateTime day, DiaryDayType type) async {
    final settings = _ref.read(diaryCalorieGoalSettingsProvider).value;
    if (settings == null) {
      return;
    }
    final controller = _ref.read(calorieGoalControllerProvider.notifier);
    final isPause = settings.isPauseDay(day);

    if (type == DiaryDayType.pause) {
      await controller.setPauseDay(day: day, isPause: !isPause);
      return;
    }
    if (isPause) {
      await controller.setPauseDay(day: day, isPause: false);
    }
    final wantsTraining = type == DiaryDayType.training;
    if (settings.isTrainingDay(day) != wantsTraining) {
      await controller.toggleTrainingDay(day);
    }
  }
}
