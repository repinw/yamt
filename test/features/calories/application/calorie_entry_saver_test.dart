import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_history_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

import '../support/fake_calories_repositories.dart';

const _scanned = CalorieScannedSourceRef(
  barcode: '4006381333931',
  source: CalorieProductSource.offBarcode,
  offProductId: 'off-123',
);

CalorieEntry _yogurt({String? imageUrl}) {
  final loggedAt = DateTime(2026, 2, 25, 10);
  return CalorieEntry.create(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Yogurt',
    imageUrl: imageUrl,
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: 80,
    per100Protein: 5,
    per100Carbs: 7,
    per100Fat: 3,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

/// Saves [entry] from a scanned product and lets the background writes run.
Future<bool> _saveScanned(
  CalorieEntry entry, {
  required FakeCalorieProductCacheRepository cache,
  FakeCalorieLogRepository? log,
}) async {
  final logRepository = log ?? FakeCalorieLogRepository();
  final settings = FakeCalorieSettingsRepository();
  addTearDown(logRepository.dispose);
  addTearDown(settings.dispose);
  final container = ProviderContainer(
    overrides: [
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(settings),
      calorieProductCacheRepositoryProvider.overrideWithValue(cache),
    ],
  );
  addTearDown(container.dispose);
  final subscription = container.listen(calorieEntrySaverProvider, (_, _) {});
  addTearDown(subscription.close);

  final saved = await subscription.read()(entry, scannedSourceRef: _scanned);
  await pumpEventQueue();
  return saved;
}

void main() {
  group('scanned product', () {
    test('a save keeps the edited nutrition as the user override', () async {
      final cache = FakeCalorieProductCacheRepository();

      final saved = await _saveScanned(_yogurt(), cache: cache);

      expect(saved, isTrue);
      expect(cache.saveUserOverrideCallCount, 1);
      expect(cache.savedOverrideReasons, contains('user_edit_after_scan'));
      expect(cache.overrides['4006381333931']?.per100Kcal, 80);
      expect(cache.overrides['4006381333931']?.imageUrl, isNull);
    });

    test('the override keeps the image of the entry', () async {
      final cache = FakeCalorieProductCacheRepository();

      await _saveScanned(
        _yogurt(imageUrl: 'https://images.example.com/yogurt.jpg'),
        cache: cache,
      );

      expect(
        cache.overrides['4006381333931']?.imageUrl,
        'https://images.example.com/yogurt.jpg',
      );
    });

    test('a failed save writes no override', () async {
      final cache = FakeCalorieProductCacheRepository();

      final saved = await _saveScanned(
        _yogurt(),
        cache: cache,
        log: FakeCalorieLogRepository()..saveShouldFail = true,
      );

      expect(saved, isFalse);
      expect(cache.saveUserOverrideCallCount, 0);
    });
  });

  test('an entry on a checked-in day marks that check-in stale', () async {
    final checkedIn = CalorieGoalHistoryEntry(
      dailyKcalGoal: 2000,
      calculatorProfile: null,
      effectiveDate: DateTime.utc(2026, 3, 15),
      changedAt: DateTime.utc(2026, 3, 15),
      source: CalorieGoalSource.weeklyCheckIn,
      weeklyCheckInSnapshot: CalorieGoalWeeklyCheckInSnapshot(
        windowStartDate: DateTime.utc(2026, 3, 8),
        windowEndDate: DateTime.utc(2026, 3, 14),
        trendWeightChangePerDay: 0,
        lowConfidence: false,
      ),
    );
    final settings = FakeCalorieSettingsRepository(
      initialSettings: const CalorieGoalSettings.empty().copyWith(
        goalHistory: [checkedIn],
      ),
    );
    final log = FakeCalorieLogRepository();
    addTearDown(log.dispose);
    addTearDown(settings.dispose);
    final now = DateTime.utc(2026, 3, 16);
    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(log),
        calorieSettingsRepositoryProvider.overrideWithValue(settings),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(calorieEntrySaverProvider, (_, _) {});
    addTearDown(subscription.close);

    final day = DateTime.utc(2026, 3, 10, 12);
    final saved = await subscription.read()(
      CalorieEntry.create(
        id: 'entry-1',
        userId: 'user-1',
        name: 'Milk',
        mealType: MealType.lunch,
        consumedAmount: 200,
        consumedUnit: ConsumedUnit.milliliters,
        per100Kcal: 60,
        per100Protein: 3.2,
        per100Carbs: 4.8,
        per100Fat: 1.5,
        loggedAt: day,
        createdAt: day,
        updatedAt: day,
      ),
      isNewEntry: true,
    );
    await pumpEventQueue();

    expect(saved, isTrue);
    final snapshot = (await settings.readSettings())
        .goalHistory
        .single
        .weeklyCheckInSnapshot;
    expect(snapshot?.isInputDirty, isTrue);
  });
}
