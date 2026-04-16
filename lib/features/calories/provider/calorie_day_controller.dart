import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'calorie_day_controller.g.dart';

/// Defines calorie day controller.
@riverpod
class CalorieDayController extends _$CalorieDayController {
  @override
  DateTime build() {
    return normalizeDiaryDay(DateTime.now());
  }

  /// Set day.
  void setDay(DateTime value) {
    state = normalizeDiaryDay(value);
  }

  /// Go to today.
  void goToToday() {
    state = normalizeDiaryDay(DateTime.now());
  }

  /// Next day.
  void nextDay() {
    state = nextDiaryDay(state);
  }

  /// Previous day.
  void previousDay() {
    state = previousDiaryDay(state);
  }
}
