import 'package:yamt/features/calories/application/calorie_debug_daily_rows.dart';
import 'package:yamt/features/calories/application/calorie_debug_dump_formatting.dart';
import 'package:yamt/features/calories/application/calorie_debug_goal_week_rows.dart';
import 'package:yamt/features/calories/application/calorie_debug_weekly_checkin_rows.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

const _debugDumpFallbackDays = 30;

/// Result for debug calorie dump.
class CalorieDebugDumpResult {
  /// Creates result.
  const new({
    required this.table,
    required this.rowCount,
    required this.startInclusive,
    required this.endExclusive,
  });

  /// Markdown table exported as debug text.
  final String table;

  /// Number of data rows in the table.
  final int rowCount;

  /// Export start.
  final DateTime startInclusive;

  /// Export end.
  final DateTime endExclusive;
}

/// Builds one debug table with food and weight data.
Future<CalorieDebugDumpResult> buildCalorieDebugDump({
  required CalorieLogRepositoryContract calorieLogRepository,
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
  final settings = await settingsFuture;
  final fallbackStartInclusive = _resolveFallbackDumpStart(
    today: today,
    firstEntryDate: firstEntryDate,
  );
  final startInclusive = _resolveDebugDumpStart(
    settings: settings,
    fallbackStartInclusive: fallbackStartInclusive,
    today: today,
  );
  final calorieEntries = await calorieLogRepository.readEntriesInRange(
    startInclusive: startInclusive,
    endExclusive: endExclusive,
  );
  final healthStatus = await healthStatusFuture;
  final rows = <CalorieDebugDumpRow>[
    _summaryRow(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
      healthStatus: healthStatus,
    ),
    ...calorieDebugDailyEatenRows(
      entries: calorieEntries,
      settings: settings,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    ),
  ];

  if (healthStatus.accessState == HealthDataAccessState.ready) {
    final weightSamples = await healthWeightService.loadWeightSamples(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
    rows.addAll(
      calorieDebugDailyWeightRows(
        healthWeightSamples: weightSamples,
        manualWeightEntries: manualWeightEntries,
        settings: settings,
        startInclusive: startInclusive,
        endExclusive: endExclusive,
      ),
    );
  } else {
    rows
      ..addAll(
        calorieDebugDailyWeightRows(
          healthWeightSamples: const <HealthWeightSample>[],
          manualWeightEntries: manualWeightEntries,
          settings: settings,
          startInclusive: startInclusive,
          endExclusive: endExclusive,
        ),
      )
      ..add(
        CalorieDebugDumpRow(
          sortAt: startInclusive,
          typeOrder: 0,
          cells: [
            formatCalorieDebugDay(startInclusive),
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
  final weeklyCheckInResult = await buildCalorieDebugWeeklyCheckInRows(
    settings: settings,
    calorieEntries: calorieEntries,
    manualWeightEntries: manualWeightEntries,
    healthStatus: healthStatus,
    healthWeightService: healthWeightService,
    today: today,
  );
  rows
    ..addAll(
      calorieDebugGoalWeekRows(
        settings: settings,
        rows: rows,
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        learnedTdeeByWeekStart: weeklyCheckInResult.learnedTdeeByWeekStart,
      ),
    )
    ..addAll(weeklyCheckInResult.rows);

  final sortedRows = List<CalorieDebugDumpRow>.of(rows)
    ..sort(compareCalorieDebugRows);
  final table = buildCalorieDebugMarkdownTable(
    sortedRows,
    separatorDays: calorieDebugGoalWeekSeparatorDays(
      settings: settings,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    ),
  );
  return CalorieDebugDumpResult(
    table: table,
    rowCount: sortedRows.length,
    startInclusive: startInclusive,
    endExclusive: endExclusive,
  );
}

DateTime _resolveFallbackDumpStart({
  required DateTime today,
  required DateTime? firstEntryDate,
}) {
  if (firstEntryDate != null) {
    return normalizeDiaryDay(firstEntryDate.toLocal());
  }
  return today.subtract(const Duration(days: _debugDumpFallbackDays - 1));
}

DateTime _resolveDebugDumpStart({
  required CalorieGoalSettings settings,
  required DateTime fallbackStartInclusive,
  required DateTime today,
}) {
  final goalStart = settings.firstGoalStartDay;
  if (goalStart == null) {
    return fallbackStartInclusive;
  }
  if (goalStart.isAfter(today)) {
    return today;
  }
  return goalStart;
}

CalorieDebugDumpRow _summaryRow({
  required DateTime startInclusive,
  required DateTime endExclusive,
  required HealthConnectionStatus healthStatus,
}) {
  final endDay = formatCalorieDebugDay(endExclusive);
  final healthState = healthStatus.accessState.name;

  return CalorieDebugDumpRow(
    sortAt: startInclusive,
    typeOrder: -1,
    cells: [
      formatCalorieDebugDay(startInclusive),
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
      'end=$endDay; health=$healthState',
    ],
  );
}
