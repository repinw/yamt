import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

part 'calorie_week_overview_provider.g.dart';

const _fallbackDailyGoalKcal = 2500.0;
const _daysPerWeek = 7;

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
  });

  final List<CalorieWeekDayOverview> days;
  final double totalConsumedKcal;
  final double totalGoalKcal;
  final double remainingKcal;
}

@riverpod
Future<CalorieWeekOverview> calorieWeekOverview(Ref ref) async {
  final goalState = ref.watch(calorieGoalControllerProvider);
  final repository = ref.watch(calorieLogRepositoryProvider);
  final goalKcal =
      goalState.asData?.value.dailyKcalGoal ?? _fallbackDailyGoalKcal;
  final today = _normalizeDay(DateTime.now());
  final startOfWindow = today.subtract(const Duration(days: _daysPerWeek - 1));
  final days = <DateTime>[
    for (var index = 0; index < _daysPerWeek; index += 1)
      startOfWindow.add(Duration(days: index)),
  ];

  final entriesByDay = await Future.wait(
    days.map(repository.readEntriesForDay),
  );

  final overviews = <CalorieWeekDayOverview>[];
  var totalConsumedKcal = 0.0;
  for (var index = 0; index < days.length; index += 1) {
    final entries = entriesByDay[index];
    final totalKcal = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalKcal,
    );
    totalConsumedKcal += totalKcal;
    overviews.add(
      CalorieWeekDayOverview(
        date: days[index],
        totalKcal: totalKcal,
        goalKcal: goalKcal,
        entryCount: entries.length,
      ),
    );
  }

  final totalGoalKcal = goalKcal * overviews.length;
  return CalorieWeekOverview(
    days: List<CalorieWeekDayOverview>.unmodifiable(overviews),
    totalConsumedKcal: totalConsumedKcal,
    totalGoalKcal: totalGoalKcal,
    remainingKcal: totalGoalKcal - totalConsumedKcal,
  );
}

DateTime _normalizeDay(DateTime day) {
  final normalizedDay = DateTime(day.year, day.month, day.day);
  return normalizedDay;
}
