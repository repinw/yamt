import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';

const _debugWeightLookbackYears = 10;
const _debugActivityFallbackDays = 30;

/// Result for debug calorie dump.
class CalorieDebugDumpResult {
  /// Creates result.
  const CalorieDebugDumpResult({
    required this.table,
    required this.rowCount,
    required this.startInclusive,
    required this.endExclusive,
  });

  /// Markdown table printed to debug console.
  final String table;

  /// Number of data rows in the table.
  final int rowCount;

  /// Export start.
  final DateTime startInclusive;

  /// Export end.
  final DateTime endExclusive;
}

/// Builds one debug table with food, activity, and weight data.
Future<CalorieDebugDumpResult> buildCalorieDebugDump({
  required CalorieLogRepositoryContract calorieLogRepository,
  required DiaryHealthService diaryHealthService,
  required HealthWeightService healthWeightService,
  required ManualHealthWeightRepository manualWeightRepository,
  required Future<HealthConnectionStatus> healthStatusFuture,
  required Future<CalorieGoalSettings> settingsFuture,
  required DateTime now,
}) async {
  final today = normalizeDiaryDay(now.toLocal());
  final endExclusive = nextDiaryDay(today);
  final firstEntryDate = await calorieLogRepository.readFirstEntryDate();
  final manualWeightEntries = await manualWeightRepository.readEntries();
  final activityStartInclusive = _resolveActivityStart(
    today: today,
    firstEntryDate: firstEntryDate,
  );
  final weightStartInclusive = DateTime(
    today.year - _debugWeightLookbackYears,
    today.month,
    today.day,
  );
  final startInclusive = _earliestDate([
    activityStartInclusive,
    weightStartInclusive,
    for (final entry in manualWeightEntries) normalizeDiaryDay(entry.day),
  ]);
  final calorieEntries = await calorieLogRepository.readEntriesInRange(
    startInclusive: activityStartInclusive,
    endExclusive: endExclusive,
  );
  final settings = await settingsFuture;
  final healthStatus = await healthStatusFuture;
  final rows = <_DebugDumpRow>[
    _summaryRow(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      healthStatus: healthStatus,
    ),
    ..._dailyEatenRows(
      entries: calorieEntries,
      startInclusive: activityStartInclusive,
      endExclusive: endExclusive,
    ),
    ...manualWeightEntries.map(_manualWeightRow),
  ];

  if (healthStatus.accessState == HealthDataAccessState.ready) {
    rows.addAll(
      await _loadHealthRows(
        activityStartInclusive: activityStartInclusive,
        weightStartInclusive: weightStartInclusive,
        endExclusive: endExclusive,
        diaryHealthService: diaryHealthService,
        healthWeightService: healthWeightService,
        userHeightCm: settings.calculatorProfile?.heightCm,
      ),
    );
  } else {
    rows.add(
      _DebugDumpRow(
        sortAt: activityStartInclusive,
        typeOrder: 0,
        cells: [
          _formatDay(activityStartInclusive),
          '',
          'health_access',
          'not_ready',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          healthStatus.platform.name,
          'access_state=${healthStatus.accessState.name}',
        ],
      ),
    );
  }

  rows.sort(_compareRows);
  final table = _buildMarkdownTable(rows);
  return CalorieDebugDumpResult(
    table: table,
    rowCount: rows.length,
    startInclusive: startInclusive,
    endExclusive: endExclusive,
  );
}

DateTime _resolveActivityStart({
  required DateTime today,
  required DateTime? firstEntryDate,
}) {
  if (firstEntryDate != null) {
    return normalizeDiaryDay(firstEntryDate.toLocal());
  }
  return today.subtract(const Duration(days: _debugActivityFallbackDays - 1));
}

Future<List<_DebugDumpRow>> _loadHealthRows({
  required DateTime activityStartInclusive,
  required DateTime weightStartInclusive,
  required DateTime endExclusive,
  required DiaryHealthService diaryHealthService,
  required HealthWeightService healthWeightService,
  required double? userHeightCm,
}) async {
  final rows = <_DebugDumpRow>[];
  final weightSamples = await healthWeightService.loadWeightSamples(
    startInclusive: weightStartInclusive,
    endExclusive: endExclusive,
  );
  rows.addAll(weightSamples.map(_healthWeightRow));

  for (
    var day = normalizeDiaryDay(activityStartInclusive);
    day.isBefore(endExclusive);
    day = nextDiaryDay(day)
  ) {
    final data = await diaryHealthService.loadDayData(
      day: day,
      userHeightCm: userHeightCm,
    );
    rows.addAll(_activityRows(day: day, data: data));
  }
  return rows;
}

List<_DebugDumpRow> _activityRows({
  required DateTime day,
  required DiaryHealthDayData data,
}) {
  if (data.totalSteps <= 0 && data.workouts.isEmpty) {
    return const <_DebugDumpRow>[];
  }

  final rows = <_DebugDumpRow>[
    _DebugDumpRow(
      sortAt: day,
      typeOrder: 2,
      cells: [
        _formatDay(day),
        '',
        'activity_day',
        'steps_total',
        '',
        '',
        '',
        '',
        '',
        data.totalSteps.toString(),
        '',
        'health',
        'workouts=${data.workouts.length}',
      ],
    ),
  ];
  for (final workout in data.workouts) {
    rows.add(
      _DebugDumpRow(
        sortAt: workout.start,
        typeOrder: 3,
        cells: [
          _formatDay(workout.start),
          _formatTime(workout.start),
          'workout',
          workout.activityLabel ?? '',
          _formatNumber(workout.totalCalories),
          '',
          '',
          '',
          '${_formatNumber(workout.durationMinutes)} min',
          workout.totalSteps?.toString() ?? '',
          '',
          workout.sourceName ?? 'health',
          'id=${workout.id}; end=${workout.endExclusive.toIso8601String()}',
        ],
      ),
    );
  }
  return rows;
}

_DebugDumpRow _summaryRow({
  required DateTime startInclusive,
  required DateTime endExclusive,
  required HealthConnectionStatus healthStatus,
}) {
  return _DebugDumpRow(
    sortAt: startInclusive,
    typeOrder: -1,
    cells: [
      _formatDay(startInclusive),
      '',
      'summary',
      'calorie_debug_dump',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'app',
      'end=${_formatDay(endExclusive)}; health=${healthStatus.accessState.name}',
    ],
  );
}

List<_DebugDumpRow> _dailyEatenRows({
  required List<CalorieEntry> entries,
  required DateTime startInclusive,
  required DateTime endExclusive,
}) {
  final kcalByDay = <DateTime, double>{};
  final entryCountByDay = <DateTime, int>{};
  for (final entry in entries) {
    final day = normalizeDiaryDay(entry.loggedAt.toLocal());
    kcalByDay[day] = (kcalByDay[day] ?? 0) + entry.totalKcal;
    entryCountByDay[day] = (entryCountByDay[day] ?? 0) + 1;
  }

  final rows = <_DebugDumpRow>[];
  for (
    var day = normalizeDiaryDay(startInclusive);
    day.isBefore(endExclusive);
    day = nextDiaryDay(day)
  ) {
    final entryCount = entryCountByDay[day] ?? 0;
    rows.add(
      _DebugDumpRow(
        sortAt: day,
        typeOrder: 1,
        cells: [
          _formatDay(day),
          '',
          'eaten_day',
          'eaten_total',
          _formatNumber(kcalByDay[day] ?? 0),
          '',
          '',
          '',
          '',
          '',
          '',
          'app',
          'entries=$entryCount',
        ],
      ),
    );
  }
  return rows;
}

_DebugDumpRow _healthWeightRow(HealthWeightSample sample) {
  return _weightRow(
    sortAt: sample.recordedAt,
    source: 'health',
    weightKg: sample.weightKg,
  );
}

_DebugDumpRow _manualWeightRow(ManualHealthWeightEntry entry) {
  return _weightRow(
    sortAt: entry.day,
    source: 'manual_fallback',
    weightKg: entry.weightKg,
  );
}

_DebugDumpRow _weightRow({
  required DateTime sortAt,
  required String source,
  required double weightKg,
}) {
  return _DebugDumpRow(
    sortAt: sortAt,
    typeOrder: 4,
    cells: [
      _formatDay(sortAt),
      _formatTime(sortAt),
      'weight',
      'body_weight',
      '',
      '',
      '',
      '',
      '',
      '',
      _formatNumber(weightKg),
      source,
      '',
    ],
  );
}

String _buildMarkdownTable(List<_DebugDumpRow> rows) {
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
  for (final row in rows) {
    buffer.writeln(_tableLine(row.cells));
  }
  return buffer.toString();
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

String _formatNumber(num? value) {
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

String _formatDay(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime dateTime) {
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

int _compareRows(_DebugDumpRow left, _DebugDumpRow right) {
  final timeCompare = left.sortAt.compareTo(right.sortAt);
  if (timeCompare != 0) {
    return timeCompare;
  }
  return left.typeOrder.compareTo(right.typeOrder);
}

DateTime _earliestDate(List<DateTime> dates) {
  return dates.reduce((left, right) => left.isBefore(right) ? left : right);
}

class _DebugDumpRow {
  const _DebugDumpRow({
    required this.sortAt,
    required this.typeOrder,
    required this.cells,
  }) : assert(cells.length == 13);

  final DateTime sortAt;
  final int typeOrder;
  final List<String> cells;
}
