import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';

import '../support/fake_calories_repositories.dart';

CalorieEntry _entry({required String id, required DateTime loggedAt}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Yogurt',
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

void main() {
  test('saveEntry with scanned source writes user override', () async {
    final logRepository = FakeCalorieLogRepository();
    final settingsRepository = FakeCalorieSettingsRepository();
    final cacheRepository = FakeCalorieProductCacheRepository();
    addTearDown(logRepository.dispose);
    addTearDown(settingsRepository.dispose);

    final container = ProviderContainer(
      overrides: [
        calorieLogRepositoryProvider.overrideWithValue(logRepository),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        calorieProductCacheRepositoryProvider.overrideWithValue(
          cacheRepository,
        ),
      ],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(calorieEntriesControllerProvider.notifier)
        .saveEntry(
          _entry(id: 'entry-1', loggedAt: DateTime(2026, 2, 25, 10)),
          scannedSourceRef: const CalorieScannedSourceRef(
            barcode: '4006381333931',
            source: CalorieProductSource.offBarcode,
            offProductId: 'off-123',
          ),
        );

    expect(saved, isTrue);
    expect(cacheRepository.overrides.containsKey('4006381333931'), isTrue);
    expect(
      cacheRepository.savedOverrideReasons,
      contains('user_edit_after_scan'),
    );
    expect(cacheRepository.saveUserOverrideCallCount, 1);
  });

  test(
    'saveEntry does not call override callback when persist fails',
    () async {
      final logRepository = FakeCalorieLogRepository();
      logRepository.saveShouldFail = true;
      final settingsRepository = FakeCalorieSettingsRepository();
      final cacheRepository = FakeCalorieProductCacheRepository();
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieProductCacheRepositoryProvider.overrideWithValue(
            cacheRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final saved = await container
          .read(calorieEntriesControllerProvider.notifier)
          .saveEntry(
            _entry(id: 'entry-1', loggedAt: DateTime(2026, 2, 25, 10)),
            scannedSourceRef: const CalorieScannedSourceRef(
              barcode: '4006381333931',
              source: CalorieProductSource.offBarcode,
              offProductId: 'off-123',
            ),
          );

      expect(saved, isFalse);
      expect(cacheRepository.saveUserOverrideCallCount, 0);
      expect(cacheRepository.overrides, isEmpty);
    },
  );

  test(
    'saveEntry keeps optimistic state when override callback throws',
    () async {
      final logRepository = FakeCalorieLogRepository(
        initialEntries: <CalorieEntry>[
          _entry(id: 'entry-old', loggedAt: DateTime(2026, 2, 25, 8)),
        ],
      );
      final settingsRepository = FakeCalorieSettingsRepository();
      final cacheRepository = FakeCalorieProductCacheRepository()
        ..saveUserOverrideShouldThrow = true;
      addTearDown(logRepository.dispose);
      addTearDown(settingsRepository.dispose);

      final container = ProviderContainer(
        overrides: [
          calorieLogRepositoryProvider.overrideWithValue(logRepository),
          calorieSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          calorieProductCacheRepositoryProvider.overrideWithValue(
            cacheRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(calorieDayControllerProvider.notifier)
          .setDay(DateTime(2026, 2, 25));
      await container.read(calorieEntriesControllerProvider.future);

      final saved = await container
          .read(calorieEntriesControllerProvider.notifier)
          .saveEntry(
            _entry(id: 'entry-new', loggedAt: DateTime(2026, 2, 25, 10)),
            scannedSourceRef: const CalorieScannedSourceRef(
              barcode: '4006381333931',
              source: CalorieProductSource.offBarcode,
              offProductId: 'off-123',
            ),
          );

      final stateEntries = container
          .read(calorieEntriesControllerProvider)
          .asData
          ?.value;
      final ids = stateEntries
          ?.map((entry) => entry.id)
          .toList(growable: false);

      expect(saved, isTrue);
      expect(cacheRepository.saveUserOverrideCallCount, 1);
      expect(ids, containsAll(<String>['entry-old', 'entry-new']));
    },
  );
}
