import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/calorie_entry_combined_stock_restore.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/calories/domain/calorie_entry_delete_result.dart';
import 'package:yamt/features/calories/domain/combined_calorie_entry.dart';

final DateTime _loggedAt = DateTime.parse('2026-09-26T12:00:00Z');

CalorieEntry _entry() {
  CalorieEntryBundleComponent component(String id, int amount) {
    return CalorieEntryBundleComponent(
      name: id,
      amountLabel: '$amount g',
      totalKcal: 100,
      totalProtein: 1,
      totalCarbs: 1,
      totalFat: 1,
      sourceInventoryItemId: id,
      sourceInventoryAmountToRestore: amount,
    );
  }

  return buildCombinedCalorieEntry(
    id: 'entry-1',
    userId: 'user-1',
    mealType: MealType.lunch,
    loggedAt: _loggedAt,
    now: _loggedAt,
    components: [
      component('bread', 80),
      component('gouda', 60),
      const CalorieEntryBundleComponent(
        name: 'Apple',
        amountLabel: '1 piece',
        totalKcal: 50,
        totalProtein: 0,
        totalCarbs: 12,
        totalFat: 0,
      ),
    ],
  );
}

class _Stock {
  new({this.existing = const {'bread', 'gouda'}, this.failRestoreOf});

  final Set<String> existing;
  final String? failRestoreOf;
  final restored = <(String, int)>[];
  final takenBack = <(String, int, DateTime?)>[];

  CalorieEntryCombinedStockRestore get restore {
    return CalorieEntryCombinedStockRestore(
      restoreConsumedItem: (itemId, amount) async {
        if (itemId == failRestoreOf) {
          return false;
        }
        restored.add((itemId, amount));
        return true;
      },
      rollbackRestoredItem: (itemId, amount, {consumedAt}) async {
        takenBack.add((itemId, amount, consumedAt));
        return true;
      },
      sourceInventoryItemExists: (itemId) async => existing.contains(itemId),
    );
  }
}

void main() {
  test('returns the stock of every food, then deletes the entry', () async {
    final stock = _Stock();
    var deleted = false;

    final result = await stock.restore.restoreAndCompensate(
      entry: _entry(),
      onDiaryDelete: () async => deleted = true,
    );

    expect(result.isSuccess, isTrue);
    expect(result.restoredToInventory, isTrue);
    expect(stock.restored, [('bread', 80), ('gouda', 60)]);
    expect(deleted, isTrue);
  });

  test('skips foods whose stock item is gone', () async {
    final stock = _Stock(existing: {'gouda'});

    final result = await stock.restore.restoreAndCompensate(
      entry: _entry(),
      onDiaryDelete: () async => true,
    );

    expect(result.isSuccess, isTrue);
    expect(stock.restored, [('gouda', 60)]);
  });

  test('reports a missing source when no stock item exists', () async {
    final stock = _Stock(existing: const {});
    var deleted = false;

    final result = await stock.restore.restoreAndCompensate(
      entry: _entry(),
      onDiaryDelete: () async => deleted = true,
    );

    expect(result.failureReason, CalorieEntryDeleteFailureReason.sourceMissing);
    expect(deleted, isFalse);
    expect(await stock.restore.canRestoreSource(_entry()), isFalse);
  });

  test('takes back earlier returns when one return fails', () async {
    final stock = _Stock(failRestoreOf: 'gouda');
    var deleted = false;

    final result = await stock.restore.restoreAndCompensate(
      entry: _entry(),
      onDiaryDelete: () async => deleted = true,
    );

    expect(result.failureReason, CalorieEntryDeleteFailureReason.restoreFailed);
    expect(deleted, isFalse);
    expect(stock.takenBack, [('bread', 80, _loggedAt)]);
  });

  test('takes back all returns when the diary delete fails', () async {
    final stock = _Stock();

    final result = await stock.restore.restoreAndCompensate(
      entry: _entry(),
      onDiaryDelete: () async => false,
    );

    expect(result.failureReason, CalorieEntryDeleteFailureReason.deleteFailed);
    expect(stock.takenBack.map((call) => call.$1), ['bread', 'gouda']);
  });

  test('takes the stock back after an undo', () async {
    final stock = _Stock();

    final takenBack = await stock.restore.takeBackRestored(_entry());

    expect(takenBack, isTrue);
    expect(stock.takenBack.map((call) => call.$1), ['bread', 'gouda']);
  });
}
