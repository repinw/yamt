import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';

part 'diary_meal_times_controller.g.dart';

const _mealTimesKey = 'diary_meal_times_v1';

/// When the user's day starts and by when they eat each meal, saved on the
/// device.
@riverpod
class DiaryMealTimesController extends _$DiaryMealTimesController {
  @override
  DiaryMealTimes build() {
    final stored = ref
        .watch(appPreferencesProvider)
        .getStringSync(_mealTimesKey);
    return (stored == null ? null : DiaryMealTimes.decode(stored)) ??
        DiaryMealTimes.standard;
  }

  /// Switches to [times] and saves them.
  Future<void> select(DiaryMealTimes times) async {
    state = times;
    await ref
        .read(appPreferencesProvider)
        .setString(_mealTimesKey, times.encode());
  }

  /// Goes back to [DiaryMealTimes.standard].
  Future<void> reset() async {
    state = DiaryMealTimes.standard;
    await ref.read(appPreferencesProvider).remove(_mealTimesKey);
  }
}
