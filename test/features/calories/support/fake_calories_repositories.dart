import 'dart:async';

import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

class FakeCalorieLogRepository implements CalorieLogRepositoryContract {
  FakeCalorieLogRepository({List<CalorieEntry>? initialEntries})
    : _entries = initialEntries ?? <CalorieEntry>[];

  final List<CalorieEntry> _entries;
  final Map<String, StreamController<List<CalorieEntry>>> _controllersByDay =
      <String, StreamController<List<CalorieEntry>>>{};

  bool saveShouldFail = false;
  bool deleteShouldFail = false;

  List<CalorieEntry> get entries => List<CalorieEntry>.unmodifiable(_entries);

  @override
  Stream<List<CalorieEntry>> watchEntriesForDay(DateTime day) {
    final normalizedDay = _normalize(day);
    final key = _dayKey(normalizedDay);

    return Stream<List<CalorieEntry>>.multi((controller) {
      controller.add(_entriesForDay(normalizedDay));
      final streamSubscription = _controllerFor(key).stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = () {
        unawaited(streamSubscription.cancel());
      };
    });
  }

  @override
  Future<List<CalorieEntry>> readEntriesForDay(DateTime day) async {
    return _entriesForDay(_normalize(day));
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
    final entries = _entries
        .where((entry) {
          return entry.loggedAt.year == day.year &&
              entry.loggedAt.month == day.month &&
              entry.loggedAt.day == day.day;
        })
        .toList(growable: false);

    entries.sort((left, right) => left.loggedAt.compareTo(right.loggedAt));
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
      () => StreamController<List<CalorieEntry>>.broadcast(),
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
      CalorieGoalSettings(
        dailyKcalGoal: dailyKcalGoal,
        updatedAt: DateTime(2026, 2, 25, 10),
      ),
    );
  }

  @override
  Future<bool> clearDailyGoal() {
    return saveSettings(const CalorieGoalSettings.empty());
  }

  Future<void> dispose() {
    return _controller.close();
  }
}
