import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/health/application/health_connection_controller.dart';
import 'package:yamt/features/health/application/health_steps_controller.dart';
import 'package:yamt/features/health/data/health_steps_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

part 'daily_steps_provider.g.dart';

/// How often today's steps are read again while something shows them.
const dailyStepsTodayRefresh = Duration(minutes: 5);

/// The steps of the calendar day [day], a date without time, or null when
/// there is nothing to show: steps are off, Health is not ready, the
/// platform has no steps for the app, or the day lies in the future.
/// Today's steps are read again every [dailyStepsTodayRefresh] and when the
/// app comes back.
@riverpod
Future<int?> dailySteps(Ref ref, DateTime day) async {
  if (!ref.watch(healthStepsControllerProvider)) {
    return null;
  }
  final now = ref.watch(clockProvider)();
  final service = ref.watch(healthStepsServiceProvider);
  final status = await ref.watch(healthConnectionControllerProvider.future);
  if (!ref.mounted || status.accessState != HealthDataAccessState.ready) {
    return null;
  }
  final start = dateOnly(day);
  if (start.isAfter(now)) {
    return null;
  }
  // Counts calendar days, so a day with a clock change keeps its length.
  final end = DateTime(start.year, start.month, start.day + 1);
  if (end.isAfter(now)) {
    final timer = Timer(dailyStepsTodayRefresh, ref.invalidateSelf);
    final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
    ref.onDispose(() {
      timer.cancel();
      lifecycle.dispose();
    });
  }
  return await service.loadSteps(startInclusive: start, endExclusive: end);
}

/// How many days [weekDailySteps] covers.
const weekDailyStepsDays = 7;

/// The steps of the [weekDailyStepsDays] days from [weekStart] on, a date
/// without time. An entry is null when its day has nothing to show, lies
/// ahead, or cannot be read.
@riverpod
Future<List<int?>> weekDailySteps(Ref ref, DateTime weekStart) async {
  final start = dateOnly(weekStart);
  // Counts calendar days, so a clock change never skips or repeats a day.
  return await Future.wait([
    for (var index = 0; index < weekDailyStepsDays; index++)
      _stepsOrNull(
        ref.watch(
          dailyStepsProvider(
            DateTime(start.year, start.month, start.day + index),
          ).future,
        ),
      ),
  ]);
}

Future<int?> _stepsOrNull(Future<int?> steps) async {
  try {
    return await steps;
  } on Object catch (error, stackTrace) {
    // The week keeps its other days; the day's own reader shows the error.
    log(
      'Failed to read the steps of a day of the week.',
      name: 'weekDailySteps',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}
