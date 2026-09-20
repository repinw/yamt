import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/application/'
    'calorie_entry_amount_edit_flow.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_stock_adjustment.dart';

class _RecordedAdjustment {
  const new({required this.reservedAmount, required this.consumedAmount});

  final int reservedAmount;
  final double consumedAmount;
}

void main() {
  final loggedAt = DateTime(2026, 4, 2, 8);
  final now = DateTime(2026, 4, 2, 12);

  CalorieEntry entry({String? sourceInventoryItemId}) {
    return CalorieEntry.create(
      id: 'entry-1',
      userId: 'user-1',
      name: 'Skyr',
      mealType: MealType.breakfast,
      consumedAmount: 200,
      consumedUnit: ConsumedUnit.grams,
      per100Kcal: 100,
      per100Protein: 10,
      per100Carbs: 5,
      per100Fat: 1,
      sourceInventoryItemId: sourceInventoryItemId,
      sourceInventoryAmountToRestore: sourceInventoryItemId == null
          ? null
          : 200,
      loggedAt: loggedAt,
      createdAt: loggedAt,
      updatedAt: loggedAt,
    );
  }

  test(
    'a plain entry is rescaled and saved without touching the stock',
    () async {
      final saved = <CalorieEntry>[];
      final flow = CalorieEntryAmountEditFlow(
        saveEntry:
            (
              entry, {
              isNewEntry = false,
              inventoryContext,
              scannedSourceRef,
              persistEntry,
            }) async {
              saved.add(entry);
              return true;
            },
      );

      final result = await flow.changeAmount(
        entry: entry(),
        amount: 50,
        now: now,
      );

      expect(result.saved, isTrue);
      expect(
        result.status,
        CalorieInventoryStockAdjustmentStatus.stockUnchanged,
      );
      expect(saved.single.consumedAmount, 50);
      expect(saved.single.totalKcal, 50);
      expect(saved.single.updatedAt, now);
    },
  );

  test('an inventory entry stores the amount the stock could follow', () async {
    final adjustments = <_RecordedAdjustment>[];
    final saved = <CalorieEntry>[];
    final flow = CalorieEntryAmountEditFlow(
      saveEntry:
          (
            entry, {
            isNewEntry = false,
            inventoryContext,
            scannedSourceRef,
            persistEntry,
          }) async {
            saved.add(entry);
            return true;
          },
      adjustStock:
          ({
            required itemId,
            required reservedAmount,
            required consumedAmount,
          }) async {
            adjustments.add(
              _RecordedAdjustment(
                reservedAmount: reservedAmount,
                consumedAmount: consumedAmount,
              ),
            );
            return const CalorieInventoryStockAdjustment(
              status: CalorieInventoryStockAdjustmentStatus.stockExhausted,
              reservedAmount: 250,
            );
          },
    );

    final result = await flow.changeAmount(
      entry: entry(sourceInventoryItemId: 'inventory-1'),
      amount: 300,
      now: now,
    );

    expect(adjustments, hasLength(1));
    expect(adjustments.single.reservedAmount, 200);
    expect(adjustments.single.consumedAmount, 300);
    expect(result.saved, isTrue);
    expect(result.status, CalorieInventoryStockAdjustmentStatus.stockExhausted);
    expect(saved.single.consumedAmount, 300);
    expect(saved.single.sourceInventoryAmountToRestore, 250);
  });

  test('a failed save returns the stock to the stored amount', () async {
    final adjustments = <_RecordedAdjustment>[];
    final flow = CalorieEntryAmountEditFlow(
      saveEntry: (
        entry, {
        isNewEntry = false,
        inventoryContext,
        scannedSourceRef,
        persistEntry,
      }) async => false,
      adjustStock:
          ({
            required itemId,
            required reservedAmount,
            required consumedAmount,
          }) async {
            adjustments.add(
              _RecordedAdjustment(
                reservedAmount: reservedAmount,
                consumedAmount: consumedAmount,
              ),
            );
            return CalorieInventoryStockAdjustment(
              status: CalorieInventoryStockAdjustmentStatus.applied,
              reservedAmount: consumedAmount.round(),
            );
          },
    );
    final stored = entry(sourceInventoryItemId: 'inventory-1');

    final result = await flow.changeAmount(
      entry: stored,
      amount: 300,
      now: now,
    );

    expect(result.saved, isFalse);
    expect(result.entry.consumedAmount, 200);
    expect(adjustments, hasLength(2));
    expect(adjustments.last.reservedAmount, 300);
    expect(adjustments.last.consumedAmount, 200);
  });
}
