import 'dart:developer' show log;
import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

part 'calorie_week_overview_provider.g.dart';

const _weekOverviewLogName = 'CalorieWeekOverviewProvider';

class CalorieWeekConsumptionDaySnapshot {
  const CalorieWeekConsumptionDaySnapshot({
    required this.date,
    required this.totalKcal,
    required this.entryCount,
  });

  final DateTime date;
  final double totalKcal;
  final int entryCount;
}

class CalorieWeekConsumptionSnapshot {
  const CalorieWeekConsumptionSnapshot({
    required this.days,
    required this.totalConsumedKcal,
  });

  final List<CalorieWeekConsumptionDaySnapshot> days;
  final double totalConsumedKcal;
}

/// Aggregate data for one visible day in the diary week strip.
class CalorieWeekDayOverview {
  const CalorieWeekDayOverview({
    required this.date,
    required this.totalKcal,
    required this.goalKcal,
    required this.entryCount,
  });

  final DateTime date;
  final double totalKcal;
  final double goalKcal;
  final int entryCount;

  bool get hasEntries => entryCount > 0;

  bool get isWithinGoal => hasEntries && totalKcal <= goalKcal;

  bool get isOverGoal => hasEntries && totalKcal > goalKcal;
}

/// Overview for the rolling 7-day diary strip ending today.
class CalorieWeekOverview {
  const CalorieWeekOverview({
    required this.days,
    required this.totalConsumedKcal,
    required this.totalGoalKcal,
    required this.remainingKcal,
    required this.balanceStartDate,
    required this.carryoverBeforeTodayKcal,
    required this.todayFlexibleGoalKcal,
    required this.goalStartsInFuture,
    required this.nextGoalStartDate,
  });

  final List<CalorieWeekDayOverview> days;
  final double totalConsumedKcal;
  final double totalGoalKcal;
  final double remainingKcal;
  final DateTime balanceStartDate;
  final double carryoverBeforeTodayKcal;
  final double todayFlexibleGoalKcal;
  final bool goalStartsInFuture;
  final DateTime? nextGoalStartDate;
}

@riverpod
Future<CalorieWeekConsumptionSnapshot> calorieWeekConsumptionSnapshot(
  Ref ref,
) async {
  final repository = ref.watch(calorieLogRepositoryProvider);
  final days = buildDiaryVisibleDays();

  final entriesByDay = await Future.wait(
    days.map((day) => _readEntriesForDaySafely(repository, day)),
  );

  final snapshots = <CalorieWeekConsumptionDaySnapshot>[];
  var totalConsumedKcal = 0.0;
  for (var index = 0; index < days.length; index += 1) {
    final entries = entriesByDay[index];
    final totalKcal = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalKcal,
    );
    totalConsumedKcal += totalKcal;
    snapshots.add(
      CalorieWeekConsumptionDaySnapshot(
        date: days[index],
        totalKcal: totalKcal,
        entryCount: entries.length,
      ),
    );
  }

  return CalorieWeekConsumptionSnapshot(
    days: List<CalorieWeekConsumptionDaySnapshot>.unmodifiable(snapshots),
    totalConsumedKcal: totalConsumedKcal,
  );
}

@riverpod
Future<CalorieWeekOverview> calorieWeekOverview(Ref ref) async {
  final snapshot = await ref.watch(
    calorieWeekConsumptionSnapshotProvider.future,
  );
  final goalState = ref.watch(calorieGoalControllerProvider);
  final settings = goalState.asData?.value ?? const CalorieGoalSettings.empty();
  final overviews = snapshot.days
      .map(
        (day) => CalorieWeekDayOverview(
          date: day.date,
          totalKcal: day.totalKcal,
          goalKcal: settings.goalKcalForDay(day.date),
          entryCount: day.entryCount,
        ),
      )
      .toList(growable: false);
  final balanceStartDate = settings.balanceStartForWindow(
    snapshot.days.map((day) => day.date),
  );
  final bufferDays = overviews.where(
    (day) => !_isBeforeDay(day.date, balanceStartDate),
  );
  final totalConsumedKcal = bufferDays.fold<double>(
    0,
    (sum, day) => sum + day.totalKcal,
  );
  final totalGoalKcal = bufferDays.fold<double>(
    0,
    (sum, day) => sum + day.goalKcal,
  );
  final today = snapshot.days.last.date;
  final hasActiveGoalToday = settings.goalEntryForDay(today)?.hasGoal == true;
  final nextGoalStartDate = settings.nextGoalStartAfterDay(today);
  final goalStartsInFuture = !hasActiveGoalToday && nextGoalStartDate != null;
  final carryoverBeforeTodayKcal = bufferDays.fold<double>(0, (sum, day) {
    if (!_isBeforeDay(day.date, today)) {
      return sum;
    }
    return sum + (day.goalKcal - day.totalKcal);
  });
  final todayOverview = overviews.last;
  final todayFlexibleGoalKcal = math.max(
    0.0,
    todayOverview.goalKcal + carryoverBeforeTodayKcal,
  );
  return CalorieWeekOverview(
    days: List<CalorieWeekDayOverview>.unmodifiable(overviews),
    totalConsumedKcal: totalConsumedKcal,
    totalGoalKcal: totalGoalKcal,
    remainingKcal: totalGoalKcal - totalConsumedKcal,
    balanceStartDate: balanceStartDate,
    carryoverBeforeTodayKcal: carryoverBeforeTodayKcal,
    todayFlexibleGoalKcal: todayFlexibleGoalKcal,
    goalStartsInFuture: goalStartsInFuture,
    nextGoalStartDate: nextGoalStartDate,
  );
}

Future<List<CalorieEntry>> _readEntriesForDaySafely(
  CalorieLogRepositoryContract repository,
  DateTime day,
) async {
  try {
    return await repository.readEntriesForDay(day);
  } catch (error, stackTrace) {
    log(
      'Failed to load calorie entries for week overview on $day.',
      name: _weekOverviewLogName,
      error: error,
      stackTrace: stackTrace,
    );
    return const <CalorieEntry>[];
  }
}

bool _isBeforeDay(DateTime left, DateTime right) {
  return DateTime(
    left.year,
    left.month,
    left.day,
  ).isBefore(DateTime(right.year, right.month, right.day));
}
