import 'dart:async';

import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_lookup_repository_contract.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/data/diary_health_service.dart';
import 'package:yamt/features/health/data/health_connection_service.dart';
import 'package:yamt/features/health/data/health_weight_service.dart';
import 'package:yamt/features/health/data/manual_health_weight_repository.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/domain/manual_health_weight_entry.dart';
import 'package:yamt/features/product_nutrition/data/'
    'nutrition_label_ocr_repository.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';

class FakeCalorieLogRepository implements CalorieLogRepositoryContract {
  FakeCalorieLogRepository({List<CalorieEntry>? initialEntries})
    : _entries = initialEntries ?? <CalorieEntry>[];

  final List<CalorieEntry> _entries;
  final Map<String, StreamController<List<CalorieEntry>>> _controllersByDay =
      <String, StreamController<List<CalorieEntry>>>{};

  Object? watchError;
  bool saveShouldFail = false;
  bool deleteShouldFail = false;
  Duration initialEmissionDelay = Duration.zero;
  Future<List<CalorieEntry>> Function(DateTime day)? onReadEntriesForDay;
  Future<List<CalorieEntry>> Function(
    DateTime startInclusive,
    DateTime endExclusive,
  )?
  onReadEntriesInRange;

  List<CalorieEntry> get entries => List<CalorieEntry>.unmodifiable(_entries);

  @override
  Stream<List<CalorieEntry>> watchEntriesForDay(DateTime day) {
    if (watchError != null) {
      return Stream<List<CalorieEntry>>.error(watchError!);
    }

    final normalizedDay = _normalize(day);
    final key = _dayKey(normalizedDay);

    return Stream<List<CalorieEntry>>.multi((controller) {
      Timer? initialEmissionTimer;
      void emitInitial() {
        if (!controller.isClosed) {
          controller.add(_entriesForDay(normalizedDay));
        }
      }

      if (initialEmissionDelay == Duration.zero) {
        emitInitial();
      } else {
        initialEmissionTimer = Timer(initialEmissionDelay, emitInitial);
      }
      final streamSubscription = _controllerFor(key).stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () {
        initialEmissionTimer?.cancel();
        unawaited(streamSubscription.cancel());
      };
    });
  }

  @override
  Future<List<CalorieEntry>> readEntriesForDay(DateTime day) async {
    final normalizedDay = _normalize(day);
    final customReader = onReadEntriesForDay;
    if (customReader != null) {
      return customReader(normalizedDay);
    }
    return _entriesForDay(normalizedDay);
  }

  @override
  Future<List<CalorieEntry>> readEntriesInRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final start = _normalize(startInclusive);
    final end = _normalize(endExclusive);
    final customReader = onReadEntriesInRange;
    if (customReader != null) {
      return customReader(start, end);
    }
    final entries =
        _entries
            .where((entry) {
              final loggedAt = entry.loggedAt;
              return !loggedAt.isBefore(start) && loggedAt.isBefore(end);
            })
            .toList(growable: false)
          ..sort((left, right) => left.loggedAt.compareTo(right.loggedAt));
    return entries;
  }

  @override
  Future<DateTime?> readFirstEntryDate() async {
    if (_entries.isEmpty) {
      return null;
    }
    final sorted = List<CalorieEntry>.from(_entries)
      ..sort((left, right) => left.loggedAt.compareTo(right.loggedAt));
    return sorted.first.loggedAt;
  }

  @override
  Future<bool> saveEntry(CalorieEntry entry) async {
    if (saveShouldFail) {
      return false;
    }

    final index = _entries.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      _entries[index] = entry;
    } else {
      _entries.add(entry);
    }
    _emitDay(_normalize(entry.loggedAt));
    return true;
  }

  @override
  Future<bool> deleteEntry(String entryId) async {
    if (deleteShouldFail) {
      return false;
    }

    final index = _entries.indexWhere((item) => item.id == entryId);
    if (index < 0) {
      return true;
    }

    final removed = _entries.removeAt(index);
    _emitDay(_normalize(removed.loggedAt));
    return true;
  }

  @override
  Future<CalorieEntry?> getById(String entryId) async {
    final index = _entries.indexWhere((entry) => entry.id == entryId);
    if (index < 0) {
      return null;
    }
    return _entries[index];
  }

  Future<void> dispose() async {
    for (final controller in _controllersByDay.values) {
      await controller.close();
    }
  }

  List<CalorieEntry> _entriesForDay(DateTime day) {
    final entries =
        _entries
            .where((entry) {
              return entry.loggedAt.year == day.year &&
                  entry.loggedAt.month == day.month &&
                  entry.loggedAt.day == day.day;
            })
            .toList(growable: false)
          ..sort((left, right) => left.loggedAt.compareTo(right.loggedAt));
    return entries;
  }

  void _emitDay(DateTime day) {
    final key = _dayKey(day);
    final controller = _controllersByDay[key];
    if (controller == null || controller.isClosed) {
      return;
    }

    controller.add(_entriesForDay(day));
  }

  StreamController<List<CalorieEntry>> _controllerFor(String key) {
    return _controllersByDay.putIfAbsent(
      key,
      StreamController<List<CalorieEntry>>.broadcast,
    );
  }

  DateTime _normalize(DateTime day) {
    return DateTime(day.year, day.month, day.day);
  }

  String _dayKey(DateTime day) {
    return '${day.year}-${day.month}-${day.day}';
  }
}

class FakeCalorieSettingsRepository implements CalorieSettingsRepository {
  FakeCalorieSettingsRepository({CalorieGoalSettings? initialSettings})
    : _settings = initialSettings ?? const CalorieGoalSettings.empty();

  CalorieGoalSettings _settings;
  final _controller = StreamController<CalorieGoalSettings>.broadcast();
  bool saveShouldFail = false;

  @override
  Stream<CalorieGoalSettings> watchSettings() {
    return Stream<CalorieGoalSettings>.multi((controller) {
      controller.add(_settings);
      final subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () {
        unawaited(subscription.cancel());
      };
    });
  }

  @override
  Future<CalorieGoalSettings> readSettings() async {
    return _settings;
  }

  @override
  Future<bool> saveSettings(CalorieGoalSettings settings) async {
    if (saveShouldFail) {
      return false;
    }

    _settings = settings;
    _controller.add(_settings);
    return true;
  }

  @override
  Future<bool> setDailyGoal(double dailyKcalGoal) {
    return saveSettings(
      CalorieGoalSettings.single(
        dailyKcalGoal: dailyKcalGoal,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 2, 25, 10),
      ),
    );
  }

  @override
  Future<bool> clearDailyGoal() {
    return saveSettings(
      const CalorieGoalSettings.empty().applyGoalChange(
        changedAt: DateTime(2026, 2, 25, 10),
        dailyKcalGoal: null,
        calculatorProfile: null,
      ),
    );
  }

  Future<void> dispose() {
    return _controller.close();
  }
}

class FakeHealthConnectionService implements HealthConnectionService {
  FakeHealthConnectionService(this.status);

  final HealthConnectionStatus status;
  int requestAuthorizationCallCount = 0;
  int requestHistoryAuthorizationCallCount = 0;
  int installHealthConnectCallCount = 0;
  int openAppPermissionSettingsCallCount = 0;
  int openHealthPermissionSettingsCallCount = 0;

  @override
  Future<HealthDisconnectResult> disconnect() async {
    return HealthDisconnectResult.disconnected;
  }

  @override
  Future<void> installHealthConnect() async {
    installHealthConnectCallCount += 1;
  }

  @override
  Future<void> openAppPermissionSettings() async {
    openAppPermissionSettingsCallCount += 1;
  }

  @override
  Future<void> openHealthPermissionSettings() async {
    openHealthPermissionSettingsCallCount += 1;
  }

  @override
  Future<HealthConnectionStatus> loadStatus() async => status;

  @override
  Future<HealthConnectionStatus> requestAuthorization() async {
    requestAuthorizationCallCount += 1;
    return status;
  }

  @override
  Future<HealthConnectionStatus> requestHistoryAuthorization() async {
    requestHistoryAuthorizationCallCount += 1;
    return status;
  }
}

class FakeDiaryHealthService implements DiaryHealthService {
  FakeDiaryHealthService(this.dataByDay);

  final Map<String, DiaryHealthDayData> dataByDay;

  @override
  Future<DiaryHealthDayData> loadDayData({
    required DateTime day,
    double? userHeightCm,
  }) async {
    return dataByDay[diaryDayKey(day)] ??
        const DiaryHealthDayData(totalSteps: 0, workouts: []);
  }
}

class FakeHealthWeightService implements HealthWeightService {
  FakeHealthWeightService(this.samples);

  final List<HealthWeightSample> samples;
  final List<HealthWeightSample> deletedSamples = <HealthWeightSample>[];

  int get deleteWeightSampleCallCount => deletedSamples.length;

  @override
  Future<List<HealthWeightSample>> loadWeightSamples({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    return samples
        .where(
          (sample) =>
              !sample.recordedAt.isBefore(startInclusive) &&
              sample.recordedAt.isBefore(endExclusive),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> deleteWeightSample(HealthWeightSample sample) async {
    deletedSamples.add(sample);
    return true;
  }

  @override
  Future<bool> saveWeightSample({
    required DateTime recordedAt,
    required double weightKg,
  }) async {
    return true;
  }
}

class FakeManualHealthWeightRepository implements ManualHealthWeightRepository {
  FakeManualHealthWeightRepository(this.entries);

  final List<ManualHealthWeightEntry> entries;
  final List<DateTime> deletedDays = <DateTime>[];

  int get deleteEntryForDayCallCount => deletedDays.length;

  @override
  Future<bool> deleteEntryForDay(DateTime day) async {
    deletedDays.add(day);
    entries.removeWhere((entry) => isSameDiaryDay(entry.day, day));
    return true;
  }

  @override
  Future<List<ManualHealthWeightEntry>> readEntries() async => entries;

  @override
  Future<bool> saveEntry(ManualHealthWeightEntry entry) async {
    entries
      ..removeWhere((existing) => isSameDiaryDay(existing.day, entry.day))
      ..add(entry)
      ..sort((left, right) => left.day.compareTo(right.day));
    return true;
  }
}

class FakeCalorieProductCacheRepository
    implements CalorieProductCacheRepositoryContract {
  final Map<String, CalorieProductProfile> global =
      <String, CalorieProductProfile>{};
  final Map<String, CalorieProductProfile> overrides =
      <String, CalorieProductProfile>{};
  final List<String> savedOverrideReasons = <String>[];
  int saveUserOverrideCallCount = 0;
  bool saveUserOverrideShouldFail = false;
  bool saveUserOverrideShouldThrow = false;

  @override
  Future<CalorieProductProfile?> readGlobalProduct(String barcode) async {
    return global[barcode];
  }

  @override
  Future<CalorieProductProfile?> readUserOverride(String barcode) async {
    return overrides[barcode];
  }

  @override
  Future<bool> saveGlobalProduct(CalorieProductProfile profile) async {
    global[profile.barcode] = profile;
    return true;
  }

  @override
  Future<bool> saveUserOverride({
    required CalorieProductProfile profile,
    required String reason,
  }) async {
    saveUserOverrideCallCount += 1;
    if (saveUserOverrideShouldThrow) {
      throw StateError('save override failed');
    }
    if (saveUserOverrideShouldFail) {
      return false;
    }
    overrides[profile.barcode] = profile;
    savedOverrideReasons.add(reason);
    return true;
  }
}

class FakeCalorieProductLookupRepository
    implements CalorieProductLookupRepositoryContract {
  FakeCalorieProductLookupRepository({required this.onLookupByBarcode});

  final Future<CalorieLookupOutcome> Function(String barcode) onLookupByBarcode;
  final List<CalorieProductProfile> persistedProfiles =
      <CalorieProductProfile>[];

  @override
  Future<CalorieLookupOutcome> lookupByBarcode(String rawBarcode) {
    return onLookupByBarcode(rawBarcode);
  }

  @override
  Future<bool> persistGlobalProduct(CalorieProductProfile profile) async {
    persistedProfiles.add(profile);
    return true;
  }
}

class FakeNutritionLabelOcrRepository implements NutritionLabelOcrRepository {
  FakeNutritionLabelOcrRepository({required this.onScanNutritionLabel});

  final Future<NutritionLabelOcrResult> Function(String barcode)
  onScanNutritionLabel;

  @override
  Future<NutritionLabelOcrResult> scanNutritionLabel({
    required String barcode,
  }) {
    return onScanNutritionLabel(barcode);
  }
}
