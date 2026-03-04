import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository_contract.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';

class _FakeCalorieLogRepository implements CalorieLogRepositoryContract {
  _FakeCalorieLogRepository({List<CalorieEntry>? initialEntries})
    : _entries = initialEntries ?? <CalorieEntry>[];

  final List<CalorieEntry> _entries;
  final Map<String, StreamController<List<CalorieEntry>>> _controllersByDay =
      <String, StreamController<List<CalorieEntry>>>{};

  DateTime? lastWatchedDay;
  bool saveShouldFail = false;
  bool deleteShouldFail = false;
  Object? watchError;
  Object? saveError;
  Completer<void>? saveBlocker;
  var saveStarted = false;
  Duration initialEmissionDelay = Duration.zero;

  List<CalorieEntry> get entries => List<CalorieEntry>.unmodifiable(_entries);

  @override
  Stream<List<CalorieEntry>> watchEntriesForDay(DateTime day) {
    if (watchError != null) {
      return Stream<List<CalorieEntry>>.error(watchError!);
    }

    final normalizedDay = _normalize(day);
    lastWatchedDay = normalizedDay;
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
  Future<List<CalorieEntry>> readEntriesForDay(DateTime day) {
    return Future<List<CalorieEntry>>.value(_entriesForDay(_normalize(day)));
  }

  @override
  Future<bool> saveEntry(CalorieEntry entry) async {
    saveStarted = true;
    if (saveBlocker != null) {
      await saveBlocker!.future;
    }
    if (saveError != null) {
      throw saveError!;
    }
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

class _FakeCalorieSettingsRepository implements CalorieSettingsRepository {
  _FakeCalorieSettingsRepository({CalorieGoalSettings? initialSettings})
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
  Future<bool> setDailyGoal(double dailyKcalGoal) async {
    return saveSettings(
      CalorieGoalSettings(
        dailyKcalGoal: dailyKcalGoal,
        updatedAt: DateTime(2026, 2, 25, 10),
      ),
    );
  }

  @override
  Future<bool> clearDailyGoal() async {
    return saveSettings(const CalorieGoalSettings.empty());
  }

  Future<void> dispose() {
    return _controller.close();
  }
}

CalorieEntry _entry(
  String id, {
  required DateTime loggedAt,
  required MealType mealType,
  double consumedAmount = 100,
  double per100Kcal = 100,
  double per100Protein = 10,
  double per100Carbs = 5,
  double per100Fat = 1,
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Item $id',
    mealType: mealType,
    consumedAmount: consumedAmount,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: per100Kcal,
    per100Protein: per100Protein,
    per100Carbs: per100Carbs,
    per100Fat: per100Fat,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

ProviderSubscription<AsyncValue<List<CalorieEntry>>> _keepEntriesAlive(
  ProviderContainer container,
) {
  return container.listen(calorieEntriesControllerProvider, (_, _) {});
}

ProviderSubscription<AsyncValue<CalorieGoalSettings>> _keepGoalAlive(
  ProviderContainer container,
) {
  return container.listen(calorieGoalControllerProvider, (_, _) {});
}

Future<void> _waitForCondition({
  required bool Function() condition,
  Duration timeout = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition not met within ${timeout.inMilliseconds}ms.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  test('day controller normalizes and navigates date state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dayController = container.read(calorieDayControllerProvider.notifier);
    dayController.setDay(DateTime(2026, 2, 25, 19, 30));

    expect(container.read(calorieDayControllerProvider), DateTime(2026, 2, 25));

    dayController.nextDay();
    expect(container.read(calorieDayControllerProvider), DateTime(2026, 2, 26));

    dayController.previousDay();
    expect(container.read(calorieDayControllerProvider), DateTime(2026, 2, 25));
  });

  test('entries controller watches current selected day', () async {
    final repository = _FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'day-1',
          loggedAt: DateTime(2026, 2, 25, 8),
          mealType: MealType.breakfast,
        ),
        _entry(
          'day-2',
          loggedAt: DateTime(2026, 2, 26, 8),
          mealType: MealType.breakfast,
        ),
      ],
    );
    final settingsRepository = _FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(repository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);
    final entriesSubscription = _keepEntriesAlive(container);
    final goalSubscription = _keepGoalAlive(container);
    addTearDown(entriesSubscription.close);
    addTearDown(goalSubscription.close);

    container
        .read(calorieDayControllerProvider.notifier)
        .setDay(DateTime(2026, 2, 25));
    final dayOneEntries = await container.read(
      calorieEntriesControllerProvider.future,
    );

    expect(repository.lastWatchedDay, DateTime(2026, 2, 25));
    expect(dayOneEntries, hasLength(1));
    expect(dayOneEntries.single.id, 'day-1');

    container
        .read(calorieDayControllerProvider.notifier)
        .setDay(DateTime(2026, 2, 26));
    final dayTwoEntries = await container.read(
      calorieEntriesControllerProvider.future,
    );

    expect(repository.lastWatchedDay, DateTime(2026, 2, 26));
    expect(dayTwoEntries, hasLength(1));
    expect(dayTwoEntries.single.id, 'day-2');
  });

  test('calorieDayViewData aggregates summary and sections', () async {
    final repository = _FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'b1',
          loggedAt: DateTime(2026, 2, 25, 8),
          mealType: MealType.breakfast,
          consumedAmount: 100,
          per100Kcal: 100,
          per100Protein: 10,
          per100Carbs: 5,
          per100Fat: 1,
        ),
        _entry(
          'l1',
          loggedAt: DateTime(2026, 2, 25, 12),
          mealType: MealType.lunch,
          consumedAmount: 200,
          per100Kcal: 150,
          per100Protein: 8,
          per100Carbs: 12,
          per100Fat: 6,
        ),
      ],
    );
    final settingsRepository = _FakeCalorieSettingsRepository(
      initialSettings: CalorieGoalSettings(
        dailyKcalGoal: 2200,
        updatedAt: DateTime(2026, 2, 25, 10),
      ),
    );
    addTearDown(repository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(repository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);
    final entriesSubscription = _keepEntriesAlive(container);
    final goalSubscription = _keepGoalAlive(container);
    addTearDown(entriesSubscription.close);
    addTearDown(goalSubscription.close);

    container
        .read(calorieDayControllerProvider.notifier)
        .setDay(DateTime(2026, 2, 25));
    await container.read(calorieEntriesControllerProvider.future);
    await container.read(calorieGoalControllerProvider.future);

    final viewData = container.read(calorieDayViewDataProvider).asData?.value;

    expect(viewData, isNotNull);
    expect(viewData?.summary.entryCount, 2);
    expect(viewData?.summary.totalKcal, closeTo(400, 0.001));
    expect(viewData?.goalKcal, 2200);
    expect(viewData?.remainingKcal, closeTo(1800, 0.001));

    final breakfastSection = viewData?.sections.firstWhere(
      (section) => section.mealType == MealType.breakfast,
    );
    final lunchSection = viewData?.sections.firstWhere(
      (section) => section.mealType == MealType.lunch,
    );

    expect(breakfastSection?.entries, hasLength(1));
    expect(breakfastSection?.totalKcal, closeTo(100, 0.001));
    expect(lunchSection?.entries, hasLength(1));
    expect(lunchSection?.totalKcal, closeTo(300, 0.001));
  });

  test(
    'entries controller returns AsyncError when initial watch fails',
    () async {
      final repository = _FakeCalorieLogRepository();
      repository.watchError = StateError('permission denied');
      final settingsRepository = _FakeCalorieSettingsRepository();
      addTearDown(repository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(repository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final entriesSubscription = _keepEntriesAlive(container);
      addTearDown(entriesSubscription.close);

      await expectLater(
        container.read(calorieEntriesControllerProvider.future),
        throwsA(isA<StateError>()),
      );

      final state = container.read(calorieEntriesControllerProvider);
      expect(state.hasError, isTrue);
    },
  );

  test(
    'saveEntry updates state optimistically before persist completes',
    () async {
      final repository = _FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'b1',
            loggedAt: DateTime(2026, 2, 25, 8),
            mealType: MealType.breakfast,
          ),
        ],
      );
      repository.saveBlocker = Completer<void>();
      final settingsRepository = _FakeCalorieSettingsRepository();
      addTearDown(repository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(repository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final entriesSubscription = _keepEntriesAlive(container);
      addTearDown(entriesSubscription.close);

      container
          .read(calorieDayControllerProvider.notifier)
          .setDay(DateTime(2026, 2, 25));
      await container.read(calorieEntriesControllerProvider.future);

      final newEntry = _entry(
        'new',
        loggedAt: DateTime(2026, 2, 25, 10),
        mealType: MealType.lunch,
      );

      var mutationCompleted = false;
      final saveFuture =
          container
              .read(calorieEntriesControllerProvider.notifier)
              .saveEntry(newEntry)
            ..then((_) => mutationCompleted = true);

      await _waitForCondition(condition: () => repository.saveStarted);

      final optimisticEntries = container
          .read(calorieEntriesControllerProvider)
          .asData
          ?.value;
      expect(optimisticEntries, hasLength(2));
      expect(
        optimisticEntries?.map((entry) => entry.id),
        containsAll(<String>['b1', 'new']),
      );
      expect(mutationCompleted, isFalse);

      repository.saveBlocker?.complete();
      final saved = await saveFuture;

      expect(saved, isTrue);
      expect(mutationCompleted, isTrue);
    },
  );

  test(
    'saveEntry completes without listener before initial stream emission',
    () async {
      final repository = _FakeCalorieLogRepository();
      repository.initialEmissionDelay = const Duration(seconds: 2);
      final settingsRepository = _FakeCalorieSettingsRepository();
      addTearDown(repository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(repository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final saved = await container
          .read(calorieEntriesControllerProvider.notifier)
          .saveEntry(
            _entry(
              'new',
              loggedAt: DateTime(2026, 2, 25, 10),
              mealType: MealType.lunch,
            ),
          )
          .timeout(
            const Duration(milliseconds: 300),
            onTimeout: () {
              fail('saveEntry timed out without active listeners.');
            },
          );

      expect(saved, isTrue);
      expect(repository.entries, hasLength(1));
      expect(repository.entries.single.id, 'new');
    },
  );

  test(
    'saveEntry rolls back optimistic update on repository failure',
    () async {
      final repository = _FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(
            'b1',
            loggedAt: DateTime(2026, 2, 25, 8),
            mealType: MealType.breakfast,
          ),
        ],
      );
      repository.saveShouldFail = true;
      final settingsRepository = _FakeCalorieSettingsRepository();
      addTearDown(repository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(repository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final entriesSubscription = _keepEntriesAlive(container);
      addTearDown(entriesSubscription.close);

      container
          .read(calorieDayControllerProvider.notifier)
          .setDay(DateTime(2026, 2, 25));
      await container.read(calorieEntriesControllerProvider.future);

      final newEntry = _entry(
        'new',
        loggedAt: DateTime(2026, 2, 25, 10),
        mealType: MealType.lunch,
      );

      final saved = await container
          .read(calorieEntriesControllerProvider.notifier)
          .saveEntry(newEntry);

      expect(saved, isFalse);
      final entries = container
          .read(calorieEntriesControllerProvider)
          .asData
          ?.value;
      expect(entries, hasLength(1));
      expect(entries?.single.id, 'b1');
    },
  );

  test('saveEntry rolls back optimistic update when persist throws', () async {
    final repository = _FakeCalorieLogRepository(
      initialEntries: <CalorieEntry>[
        _entry(
          'b1',
          loggedAt: DateTime(2026, 2, 25, 8),
          mealType: MealType.breakfast,
        ),
      ],
    );
    repository.saveError = StateError('write failed');
    final settingsRepository = _FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(repository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);
    final entriesSubscription = _keepEntriesAlive(container);
    addTearDown(entriesSubscription.close);

    container
        .read(calorieDayControllerProvider.notifier)
        .setDay(DateTime(2026, 2, 25));
    await container.read(calorieEntriesControllerProvider.future);

    final newEntry = _entry(
      'new',
      loggedAt: DateTime(2026, 2, 25, 10),
      mealType: MealType.lunch,
    );

    final saved = await container
        .read(calorieEntriesControllerProvider.notifier)
        .saveEntry(newEntry);

    expect(saved, isFalse);
    final entries = container
        .read(calorieEntriesControllerProvider)
        .asData
        ?.value;
    expect(entries, hasLength(1));
    expect(entries?.single.id, 'b1');
  });

  test('goal controller setGoal and clearGoal update state', () async {
    final repository = _FakeCalorieLogRepository();
    final settingsRepository = _FakeCalorieSettingsRepository();
    addTearDown(repository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(repository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
    );
    addTearDown(container.dispose);
    final goalSubscription = _keepGoalAlive(container);
    addTearDown(goalSubscription.close);

    await container.read(calorieGoalControllerProvider.future);

    final setGoalResult = await container
        .read(calorieGoalControllerProvider.notifier)
        .setGoal(2300);
    final afterSet = container
        .read(calorieGoalControllerProvider)
        .asData
        ?.value;

    final clearGoalResult = await container
        .read(calorieGoalControllerProvider.notifier)
        .clearGoal();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    final afterClear = container
        .read(calorieGoalControllerProvider)
        .asData
        ?.value;

    expect(setGoalResult, isTrue);
    expect(afterSet?.dailyKcalGoal, 2300);
    expect(clearGoalResult, isTrue);
    expect(afterClear?.dailyKcalGoal, isNull);
  });
}
