import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'calorie_health_trends_window_controller.g.dart';

@Riverpod(keepAlive: true)
class CalorieHealthTrendsWindowController
    extends _$CalorieHealthTrendsWindowController {
  @override
  DateTime? build() {
    return null;
  }

  void setWindowEnd(DateTime? value) {
    state = value == null ? null : normalizeDiaryDay(value);
  }
}
