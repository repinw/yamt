import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_controller.dart';

part 'calorie_page_action_controller.g.dart';

/// Handles calorie page actions that need providers.
@riverpod
class CaloriePageActionController extends _$CaloriePageActionController {
  @override
  FutureOr<void> build() {
    ref.keepAlive();
    return null;
  }

  /// Toggles skipped-intake state for a calorie day.
  Future<bool> setSkippedIntakeDay({
    required DateTime selectedDay,
    required bool isSkipped,
  }) {
    final controller = ref.read(
      calorieWeeklyCheckInControllerProvider.notifier,
    );
    return controller.setSkippedIntakeDay(
      day: selectedDay,
      isSkipped: isSkipped,
    );
  }
}
