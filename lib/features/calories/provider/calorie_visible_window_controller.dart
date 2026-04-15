import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calorie_visible_window_controller.g.dart';

@riverpod
class CalorieVisibleWindowController extends _$CalorieVisibleWindowController {
  @override
  DateTime build() {
    return _normalize(DateTime.now());
  }

  void setWindowEnd(DateTime value) {
    state = _clampToToday(_normalize(value));
  }

  DateTime _normalize(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _clampToToday(DateTime value) {
    final today = _normalize(DateTime.now());
    if (value.isAfter(today)) {
      return today;
    }
    return value;
  }
}
