import 'package:yamt/features/calories/application/'
    'calorie_weekly_checkin_build_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';

/// One row of the calorie debug table with its 13 cells.
class CalorieDebugDumpRow {
  /// Creates a row sorted by [sortAt], then by [typeOrder].
  const new({
    required this.sortAt,
    required this.typeOrder,
    required this.cells,
  }) : assert(cells.length == 13, 'Debug dump rows must have 13 cells.');

  /// When the row happens; rows are sorted by it.
  final DateTime sortAt;

  /// Order of rows at the same time.
  final int typeOrder;

  /// The 13 table cells.
  final List<String> cells;
}

/// Builds the Markdown table of [rows]. A blank line goes before the first
/// row of each day in [separatorDays].
String buildCalorieDebugMarkdownTable(
  List<CalorieDebugDumpRow> rows, {
  Set<String> separatorDays = const <String>{},
}) {
  const headers = [
    'date',
    'time',
    'type',
    'name',
    'kcal',
    'protein_g',
    'carbs_g',
    'fat_g',
    'amount',
    'steps',
    'weight_kg',
    'source',
    'extra',
  ];
  final buffer = StringBuffer()
    ..writeln(_tableLine(headers))
    ..writeln(_tableLine(List<String>.filled(headers.length, '---')));
  final separatedDays = <String>{};
  for (final row in rows) {
    final dayKey = diaryDayKey(row.sortAt);
    if (separatorDays.contains(dayKey) && separatedDays.add(dayKey)) {
      buffer.writeln();
    }
    buffer.writeln(_tableLine(row.cells));
  }
  return buffer.toString();
}

/// Formats [value] with at most two decimals, or an empty cell.
String formatCalorieDebugNumber(num? value) {
  if (value == null) {
    return '';
  }
  final asDouble = value.toDouble();
  if (!asDouble.isFinite) {
    return '';
  }
  if (asDouble == asDouble.roundToDouble()) {
    return asDouble.round().toString();
  }
  final rounded = (asDouble * 100).roundToDouble() / 100;
  if (rounded == rounded.roundToDouble()) {
    return rounded.round().toString();
  }
  return rounded.toStringAsFixed(2);
}

/// Formats the local day of [dateTime] as `yyyy-MM-dd`.
String formatCalorieDebugDay(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

/// Formats the local time of [dateTime], or an empty cell at midnight.
String formatCalorieDebugTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  if (local.hour == 0 &&
      local.minute == 0 &&
      local.second == 0 &&
      local.millisecond == 0 &&
      local.microsecond == 0) {
    return '';
  }
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}:'
      '${local.second.toString().padLeft(2, '0')}';
}

/// Orders rows by time, then by their type order.
int compareCalorieDebugRows(
  CalorieDebugDumpRow left,
  CalorieDebugDumpRow right,
) {
  final timeCompare = left.sortAt.compareTo(right.sortAt);
  if (timeCompare != 0) {
    return timeCompare;
  }
  return left.typeOrder.compareTo(right.typeOrder);
}

/// Joins the diary day keys of [days] with commas.
String formatCalorieDebugDayKeys(List<DateTime> days) {
  return days.map(diaryDayKey).join(',');
}

/// Formats `name=value` for the extra cell.
String calorieDebugNamedNumber(String name, double value) {
  return '$name=${formatCalorieDebugNumber(value)}';
}

/// Joins [values] with two decimals each.
String formatCalorieDebugDoubleList(List<double> values) {
  return values.map((value) => value.toStringAsFixed(2)).join(',');
}

/// Formats weight points as `dayIndex:weight`.
String formatCalorieDebugWeightPoints(
  List<CalorieWeeklyCheckInWeightPoint> points,
) {
  return points
      .map((point) {
        return '${point.dayIndex}:${point.weightKg.toStringAsFixed(2)}';
      })
      .join(',');
}

/// Formats the intake and weight of each window day.
String formatCalorieDebugWindowDays(List<CalorieWeeklyCheckInWindowDay> days) {
  return days
      .map((day) {
        return '${diaryDayKey(day.day)}'
            ':logged=${day.loggedIntakeKcal.toStringAsFixed(2)}'
            ',resolved=${day.resolvedIntakeKcal?.toStringAsFixed(2) ?? 'null'}'
            ',weight=${day.weightKg?.toStringAsFixed(2) ?? 'null'}'
            ',skipped=${day.isSkippedIntakeDay}';
      })
      .join(' | ');
}

/// Describes the check-in window, learning window, and due day.
String calorieDebugWindowExtra(
  PendingCalorieGoalWeeklyCheckIn window,
  CalorieWeeklyCheckInWindowDates dates,
) {
  return 'window=${diaryDayKey(window.windowStartDate)}'
      '..${diaryDayKey(window.windowEndDate)}; '
      'learning_window=${diaryDayKey(dates.learningStartDate)}'
      '..${diaryDayKey(window.windowEndDate)}; '
      'due=${diaryDayKey(window.dueDate)}';
}

/// The first and last weight of [weightPoints].
CalorieDebugWeightTrend calorieDebugWeightTrend({
  required List<CalorieWeeklyCheckInWeightPoint> weightPoints,
}) {
  final firstPoint = weightPoints.first;
  final lastPoint = weightPoints.last;
  return CalorieDebugWeightTrend(
    startWeightKg: firstPoint.weightKg,
    endWeightKg: lastPoint.weightKg,
    weightChangeKg: lastPoint.weightKg - firstPoint.weightKg,
  );
}

/// Start, end, and change of the weight in one check-in window.
class CalorieDebugWeightTrend {
  /// Creates a weight trend.
  const new({
    required this.startWeightKg,
    required this.endWeightKg,
    required this.weightChangeKg,
  });

  /// First weight of the window.
  final double startWeightKg;

  /// Last weight of the window.
  final double endWeightKg;

  /// Last weight minus first weight.
  final double weightChangeKg;
}

String _tableLine(List<String> cells) {
  return '| ${cells.map(_escapeCell).join(' | ')} |';
}

String _escapeCell(String value) {
  return value
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ')
      .replaceAll('|', r'\|');
}
