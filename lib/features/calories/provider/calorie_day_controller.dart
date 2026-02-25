import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calorie_day_controller.g.dart';

@riverpod
class CalorieDayController extends _$CalorieDayController {
  @override
  DateTime build() {
    return _normalize(DateTime.now());
  }

  void setDay(DateTime value) {
    state = _normalize(value);
  }

  void goToToday() {
    state = _normalize(DateTime.now());
  }

  void nextDay() {
    state = state.add(const Duration(days: 1));
  }

  void previousDay() {
    state = state.subtract(const Duration(days: 1));
  }

  DateTime _normalize(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
