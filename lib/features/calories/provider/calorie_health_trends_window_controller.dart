import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'calorie_health_trends_window_controller.g.dart';

/// Defines calorie health trends window controller.
@Riverpod(keepAlive: true)
class CalorieHealthTrendsWindowController
    extends _$CalorieHealthTrendsWindowController {
  @override
  DateTime? build() {
    return null;
  }

  /// Set window end.
  void setWindowEnd(DateTime? value) {
    state = value == null ? null : normalizeDiaryDay(value);
  }
}
