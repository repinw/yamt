import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';

part 'calorie_visible_window_controller.g.dart';

/// Defines calorie visible window controller.
@riverpod
class CalorieVisibleWindowController extends _$CalorieVisibleWindowController {
  @override
  DateTime build() {
    return _normalize(ref.watch(clockProvider)());
  }

  /// Set window end.
  void setWindowEnd(DateTime value) {
    state = _clampToToday(_normalize(value));
  }

  DateTime _normalize(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _clampToToday(DateTime value) {
    final today = _normalize(ref.read(clockProvider)());
    if (value.isAfter(today)) {
      return today;
    }
    return value;
  }
}
