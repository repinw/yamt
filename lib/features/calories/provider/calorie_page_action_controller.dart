import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_controller.dart';

/// Handles calorie page actions that need providers.
class CaloriePageActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
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

/// Controller for calorie page actions.
final caloriePageActionControllerProvider =
    AsyncNotifierProvider<CaloriePageActionController, void>(
      CaloriePageActionController.new,
    );
