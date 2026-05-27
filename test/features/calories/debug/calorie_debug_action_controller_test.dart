import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/debug/calorie_debug_action_controller.dart';
import 'package:yamt/features/calories/debug/calorie_debug_file_exporter.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/health/data/diary_health_service_provider.dart';
import 'package:yamt/features/health/data/health_connection_service_provider.dart';
import 'package:yamt/features/health/data/health_weight_service_provider.dart';
import 'package:yamt/features/health/data/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';

import '../support/fake_calories_repositories.dart';

void main() {
  test('printDebugDump exports txt and returns success result', () async {
    final exporter = _FakeCalorieDebugFileExporter();
    final harness = _createHarness(fileExporter: exporter);
    addTearDown(harness.dispose);

    final result = await harness.controller.printDebugDump(
      now: DateTime(2026, 2, 25, 12),
      saveDialogTitle: 'Save calorie debug TXT',
    );

    expect(
      result,
      isA<CalorieDebugDumpPrintSuccess>().having(
        (result) => result.rowCount,
        'rowCount',
        greaterThan(0),
      ),
    );
    expect(exporter.fileName, 'yamt_diary_debug_20260225_120000.txt');
    expect(exporter.text, contains('YAMT diary debug dump'));
    expect(exporter.text, contains('| date | time | type | name | kcal |'));
  });

  test(
    'printDebugDump returns canceled result when export is canceled',
    () async {
      final harness = _createHarness(
        fileExporter: _FakeCalorieDebugFileExporter(
          result: const CalorieDebugFileExportCanceled(),
        ),
      );
      addTearDown(harness.dispose);

      final result = await harness.controller.printDebugDump(
        now: DateTime(2026, 2, 25, 12),
        saveDialogTitle: 'Save calorie debug TXT',
      );

      expect(result, isA<CalorieDebugDumpPrintCanceled>());
    },
  );

  test('printDebugDump returns failure result after exception', () async {
    final harness = _createHarness(
      logRepository: FakeCalorieLogRepository()
        ..onReadEntriesInRange = (_, _) async {
          throw StateError('debug dump failed');
        },
    );
    addTearDown(harness.dispose);

    final result = await harness.controller.printDebugDump(
      now: DateTime(2026, 2, 25, 12),
      saveDialogTitle: 'Save calorie debug TXT',
    );

    expect(result, isA<CalorieDebugDumpPrintFailure>());
  });

  test('printDebugDump returns failure result when export fails', () async {
    final harness = _createHarness(
      fileExporter: _FakeCalorieDebugFileExporter(
        exception: Exception('file export failed'),
      ),
    );
    addTearDown(harness.dispose);

    final result = await harness.controller.printDebugDump(
      now: DateTime(2026, 2, 25, 12),
      saveDialogTitle: 'Save calorie debug TXT',
    );

    expect(result, isA<CalorieDebugDumpPrintFailure>());
  });

  test('printSettingsDebugDump returns success result', () async {
    final settingsRepository = FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 2, 25),
      ),
    );
    final harness = _createHarness(settingsRepository: settingsRepository);
    addTearDown(harness.dispose);

    final result = await harness.controller.printSettingsDebugDump();

    expect(
      result,
      isA<CalorieSettingsDebugDumpPrintSuccess>().having(
        (result) => result.entryCount,
        'entryCount',
        1,
      ),
    );
  });

  test('printWeeklyCheckInDebugDump returns success result', () async {
    final harness = _createHarness(
      overrides: [
        calorieWeeklyCheckInDataProvider.overrideWith(
          (ref) => _weeklyCheckInData(),
        ),
      ],
    );
    addTearDown(harness.dispose);

    final result = await harness.controller.printWeeklyCheckInDebugDump();

    expect(result, isA<CalorieWeeklyCheckInDebugDumpPrintSuccess>());
  });

  test('printWeeklyCheckInDebugDump returns failure result', () async {
    final harness = _createHarness(
      overrides: [
        calorieWeeklyCheckInDataProvider.overrideWith((ref) {
          throw StateError('weekly check-in dump failed');
        }),
      ],
    );
    addTearDown(harness.dispose);

    final result = await harness.controller.printWeeklyCheckInDebugDump();

    expect(result, isA<CalorieWeeklyCheckInDebugDumpPrintFailure>());
  });
}

_CaloriePageActionHarness _createHarness({
  FakeCalorieLogRepository? logRepository,
  FakeCalorieSettingsRepository? settingsRepository,
  CalorieDebugFileExporter? fileExporter,
  List<Override> overrides = const <Override>[],
}) {
  final resolvedLogRepository = logRepository ?? FakeCalorieLogRepository();
  final resolvedSettingsRepository =
      settingsRepository ?? FakeCalorieSettingsRepository();
  final container = ProviderContainer(
    overrides: [
      calorieLogRepositoryProvider.overrideWithValue(resolvedLogRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(
        resolvedSettingsRepository,
      ),
      diaryHealthServiceProvider.overrideWithValue(FakeDiaryHealthService({})),
      healthConnectionServiceProvider.overrideWithValue(
        FakeHealthConnectionService(
          const HealthConnectionStatus.unsupported(),
        ),
      ),
      healthWeightServiceProvider.overrideWithValue(
        FakeHealthWeightService([]),
      ),
      calorieDebugFileExporterProvider.overrideWithValue(
        fileExporter ?? _FakeCalorieDebugFileExporter(),
      ),
      manualHealthWeightRepositoryProvider.overrideWithValue(
        FakeManualHealthWeightRepository([]),
      ),
      ...overrides,
    ],
  );
  return _CaloriePageActionHarness(
    container: container,
    logRepository: resolvedLogRepository,
    settingsRepository: resolvedSettingsRepository,
  );
}

class _CaloriePageActionHarness {
  _CaloriePageActionHarness({
    required this.container,
    required this.logRepository,
    required this.settingsRepository,
  });

  final ProviderContainer container;
  final FakeCalorieLogRepository logRepository;
  final FakeCalorieSettingsRepository settingsRepository;

  CalorieDebugActionController get controller {
    return container.read(calorieDebugActionControllerProvider.notifier);
  }

  Future<void> dispose() async {
    await logRepository.dispose();
    await settingsRepository.dispose();
    container.dispose();
  }
}

class _FakeCalorieDebugFileExporter implements CalorieDebugFileExporter {
  _FakeCalorieDebugFileExporter({
    this.result = const CalorieDebugFileExportSaved(
      path: '/tmp/yamt_diary_debug.txt',
    ),
    this.exception,
  });

  final CalorieDebugFileExportResult result;
  final Exception? exception;
  String? fileName;
  String? text;

  @override
  Future<CalorieDebugFileExportResult> saveText({
    required String dialogTitle,
    required String fileName,
    required String text,
  }) async {
    this.fileName = fileName;
    this.text = text;
    final exception = this.exception;
    if (exception != null) {
      throw exception;
    }
    return result;
  }
}

CalorieWeeklyCheckInData _weeklyCheckInData() {
  final windowStartDate = DateTime(2026, 2, 18);
  final windowEndDate = DateTime(2026, 2, 24);
  final dueDate = DateTime(2026, 2, 25);
  final pendingWeeklyCheckIn = PendingCalorieGoalWeeklyCheckIn(
    windowStartDate: windowStartDate,
    windowEndDate: windowEndDate,
    dueDate: dueDate,
  );

  return CalorieWeeklyCheckInData(
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    cacheWeeklyCheckIn: pendingWeeklyCheckIn.copyWith(
      dismissedAt: DateTime(2026, 2, 25, 8),
    ),
    shouldAutoOpen: true,
    days: [
      CalorieWeeklyCheckInWindowDay(
        day: windowStartDate,
        hasEntries: true,
        loggedIntakeKcal: 2100,
        resolvedIntakeKcal: 2100,
        isSkippedIntakeDay: false,
        isHeartDay: false,
        activeKcal: 320,
        weightKg: 80.2,
      ),
      CalorieWeeklyCheckInWindowDay(
        day: windowStartDate.add(const Duration(days: 1)),
        hasEntries: false,
        loggedIntakeKcal: 0,
        resolvedIntakeKcal: null,
        isSkippedIntakeDay: true,
        isHeartDay: true,
        activeKcal: 180,
        weightKg: null,
      ),
    ],
    calculation: const CalorieWeeklyCheckInCalculation(
      trendWeightChangePerDay: -0.05,
      averageIntakeKcal: 2150,
      measuredTotalTdeeKcal: 2500,
      measuredBaseTdeeKcal: 2200,
      calculatedBaseTdeeKcal: 2450,
      newBaseGoalKcal: 2200,
      averageCreditedActivityKcal: 300,
      todayActiveKcal: 350,
      activityDeltaKcal: 25,
      dynamicGoalTodayKcal: 2225,
    ),
    blockedReason: CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight,
    missingIntakeDays: [windowStartDate.add(const Duration(days: 1))],
    missingWeightDays: [windowEndDate],
    freshness: CalorieLearnedTdeeFreshness.urgent,
    latestLearnedTdeeAt: DateTime(2026, 2, 1, 9),
    lowConfidence: true,
    inputHash: 'weekly-input-hash',
  );
}
