import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_shares_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_times_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_marker_controller.dart';

part 'diary_pace_provider.g.dart';

/// The share of the day's kcal due by now on [day], from the user's parts
/// of the day and meal times; null while the marker is off and on any day
/// but today. It moves on with every minute.
@riverpod
double? diaryPaceShare(Ref ref, DateTime day) {
  if (!ref.watch(diaryPaceMarkerControllerProvider) ||
      day != ref.watch(diaryTodayProvider)) {
    return null;
  }
  final now = ref.watch(clockProvider)();
  final tick = Timer(Duration(seconds: 60 - now.second), ref.invalidateSelf);
  ref.onDispose(tick.cancel);
  return ref
      .watch(diaryMealTimesControllerProvider)
      .dueAt(
        now.hour * 60 + now.minute,
        ref.watch(diaryMealSharesControllerProvider),
      );
}
