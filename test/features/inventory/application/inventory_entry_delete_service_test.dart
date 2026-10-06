import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/calories/domain/combined_calorie_entry.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import '../support/inventory_entry_world.dart';

CalorieEntryBundleComponent _food(String itemId, int amount) {
  return CalorieEntryBundleComponent(
    name: itemId,
    amountLabel: '$amount ml',
    totalKcal: 100,
    totalProtein: 1,
    totalCarbs: 1,
    totalFat: 1,
    sourceInventoryItemId: itemId,
    sourceInventoryAmountToRestore: amount,
  );
}

CalorieEntry _combinedEntry() {
  return buildCombinedCalorieEntry(
    id: 'entry-1',
    userId: 'user-1',
    mealType: MealType.breakfast,
    loggedAt: entryLoggedAt,
    now: entryLoggedAt,
    components: [_food('milk', 200), _food('oat-milk', 100)],
  );
}

PreparedMeal _chili({num remainingPortions = 2}) {
  return PreparedMeal(
    id: 'chili',
    name: 'Chili',
    totalPortions: 4,
    remainingPortions: remainingPortions,
    totalKcal: 2000,
    totalProtein: 100,
    totalCarbs: 200,
    totalFat: 80,
    createdAt: DateTime(2026, 3, 26),
    updatedAt: DateTime(2026, 3, 26),
    components: const <PreparedMealComponent>[],
  );
}

CalorieEntry _chiliEntry() {
  return CalorieEntry.bundle(
    id: 'entry-1',
    userId: 'user-1',
    name: 'Chili',
    mealType: MealType.lunch,
    totalKcal: 500,
    totalProtein: 25,
    totalCarbs: 50,
    totalFat: 20,
    bundleSourcePreparedMealId: 'chili',
    bundleConsumedPortions: 1,
    bundleTotalPortions: 4,
    bundleComponents: const <CalorieEntryBundleComponent>[],
    loggedAt: entryLoggedAt,
    createdAt: entryLoggedAt,
    updatedAt: entryLoggedAt,
  );
}

void main() {
  setUpAll(setUpInventoryEntryKeys);

  group('delete', () {
    test('gives the stock back and deletes the entry in one write', () async {
      final world = InventoryEntryWorld();
      await world.putItem(milkItem());
      await world.diary.saveEntry(milkEntry());

      final result = await world.service.delete(
        milkEntry(),
        restoreToInventory: true,
      );
      await pumpEventQueue();

      expect(result.isSuccess, isTrue);
      expect(result.restoredToInventory, isTrue);
      expect(await world.hasEntry('entry-1'), isFalse);
      expect((await world.item('milk')).currentAmount, 1000);
      expect(world.reportedStock.single.currentAmount, 1000);
      expect(world.changedDays, [entryLoggedAt]);
    });

    test('a missing item keeps the entry', () async {
      final world = InventoryEntryWorld();
      await world.diary.saveEntry(milkEntry());

      final result = await world.service.delete(
        milkEntry(),
        restoreToInventory: true,
      );
      await pumpEventQueue();

      expect(
        result.failureReason,
        CalorieEntryDeleteFailureReason.sourceMissing,
      );
      expect(await world.hasEntry('entry-1'), isTrue);
      expect(world.changedDays, isEmpty);
    });

    test('without restore the stock stays', () async {
      final world = InventoryEntryWorld();
      await world.putItem(milkItem());
      await world.diary.saveEntry(milkEntry());

      final result = await world.service.delete(
        milkEntry(),
        restoreToInventory: false,
      );
      await pumpEventQueue();

      expect(result.isSuccess, isTrue);
      expect(result.restoredToInventory, isFalse);
      expect(await world.hasEntry('entry-1'), isFalse);
      expect((await world.item('milk')).currentAmount, 750);
      expect(world.changedDays, [entryLoggedAt]);
    });

    test('a combined entry gives stock to the foods that exist', () async {
      final world = InventoryEntryWorld();
      await world.putItem(milkItem());
      await world.diary.saveEntry(_combinedEntry());

      final result = await world.service.delete(
        _combinedEntry(),
        restoreToInventory: true,
      );
      await pumpEventQueue();

      expect(result.restoredToInventory, isTrue);
      expect(await world.hasEntry('entry-1'), isFalse);
      expect((await world.item('milk')).currentAmount, 950);
    });

    test('a cooked meal gets its portions back', () async {
      final world = InventoryEntryWorld();
      await world.putMeal(_chili());
      await world.diary.saveEntry(_chiliEntry());

      final result = await world.service.delete(
        _chiliEntry(),
        restoreToInventory: true,
      );
      await pumpEventQueue();

      expect(result.restoredToInventory, isTrue);
      expect(await world.hasEntry('entry-1'), isFalse);
      expect((await world.meal('chili')).remainingPortions, 3);
    });

    test('a cooked meal with all portions left takes none back', () async {
      final world = InventoryEntryWorld();
      await world.putMeal(_chili(remainingPortions: 4));
      await world.diary.saveEntry(_chiliEntry());

      final result = await world.service.delete(
        _chiliEntry(),
        restoreToInventory: true,
      );
      await pumpEventQueue();

      expect(
        result.failureReason,
        CalorieEntryDeleteFailureReason.restoreFailed,
      );
      expect(await world.hasEntry('entry-1'), isTrue);
    });
  });

  group('undoDelete', () {
    test('saves the entry and takes the given-back stock again', () async {
      final world = InventoryEntryWorld();
      await world.putItem(milkItem());
      await world.diary.saveEntry(milkEntry());
      await world.service.delete(milkEntry(), restoreToInventory: true);
      await pumpEventQueue();

      final undone = await world.service.undoDelete(
        milkEntry(),
        restoredToInventory: true,
      );
      await pumpEventQueue();

      expect(undone, isTrue);
      expect(await world.hasEntry('entry-1'), isTrue);
      expect((await world.item('milk')).currentAmount, 750);
      expect(world.reportedStock.last.currentAmount, 750);
    });

    test('takes the portions of a cooked meal again', () async {
      final world = InventoryEntryWorld();
      await world.putMeal(_chili());
      await world.diary.saveEntry(_chiliEntry());
      await world.service.delete(_chiliEntry(), restoreToInventory: true);
      await pumpEventQueue();

      final undone = await world.service.undoDelete(
        _chiliEntry(),
        restoredToInventory: true,
      );
      await pumpEventQueue();

      expect(undone, isTrue);
      expect(await world.hasEntry('entry-1'), isTrue);
      expect((await world.meal('chili')).remainingPortions, 2);
    });

    test('a single entry whose item is gone stays deleted', () async {
      final world = InventoryEntryWorld();
      await world.diary.saveEntry(milkEntry());

      final undone = await world.service.undoDelete(
        milkEntry(),
        restoredToInventory: true,
      );
      await pumpEventQueue();

      expect(undone, isFalse);
    });

    test('takes at most the stock that the item holds now', () async {
      final world = InventoryEntryWorld();
      await world.putItem(milkItem(currentAmount: 100));

      final undone = await world.service.undoDelete(
        milkEntry(),
        restoredToInventory: true,
      );
      await pumpEventQueue();

      expect(undone, isTrue);
      expect(await world.hasEntry('entry-1'), isTrue);
      expect((await world.item('milk')).currentAmount, 0);
    });

    test('a failed item read reports the undo as failed', () async {
      final world = InventoryEntryWorld();
      world.items.readError = StateError('read failed');

      final undone = await world.service.undoDelete(
        milkEntry(),
        restoredToInventory: true,
      );

      expect(undone, isFalse);
      expect(await world.hasEntry('entry-1'), isFalse);
    });
  });

  test('canRestoreSource checks that the stock source still exists', () async {
    final world = InventoryEntryWorld();
    expect(await world.service.canRestoreSource(milkEntry()), isFalse);
    expect(await world.service.canRestoreSource(_chiliEntry()), isFalse);

    await world.putItem(milkItem());
    await world.putMeal(_chili());

    expect(await world.service.canRestoreSource(milkEntry()), isTrue);
    expect(await world.service.canRestoreSource(_combinedEntry()), isTrue);
    expect(await world.service.canRestoreSource(_chiliEntry()), isTrue);
  });
}
