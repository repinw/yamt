import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_entry_saver.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_edits.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_stock_adjustment.dart';

part 'calorie_entry_amount_edit_flow.g.dart';

const _amountEditFlowLogName = 'CalorieEntryAmountEditFlow';

/// Moves the stock of an inventory item to the amount an entry consumes.
///
/// [reservedAmount] is what the entry takes from the stock today,
/// [consumedAmount] the amount it should consume after the change.
typedef CalorieInventoryStockAdjuster =
    Future<CalorieInventoryStockAdjustment> Function({
      required String itemId,
      required int reservedAmount,
      required double consumedAmount,
    });

/// Provides inventory stock adjustment when inventory is wired.
@riverpod
CalorieInventoryStockAdjuster? calorieInventoryStockAdjuster(Ref ref) {
  ref.keepAlive();
  return null;
}

/// Result of changing the consumed amount of a logged entry.
class CalorieEntryAmountChangeResult {
  /// Creates the change result.
  const new({required this.saved, required this.entry, required this.status});

  /// Whether the changed entry was stored.
  final bool saved;

  /// The stored entry, or the unchanged one when the save failed.
  final CalorieEntry entry;

  /// How far the inventory stock followed the change.
  final CalorieInventoryStockAdjustmentStatus status;
}

/// Provides the amount edit flow of logged entries.
@riverpod
CalorieEntryAmountEditFlow calorieEntryAmountEditFlow(Ref ref) {
  ref.keepAlive();
  return CalorieEntryAmountEditFlow(
    saveEntry: ref.watch(calorieEntrySaverProvider),
    adjustStock: ref.watch(calorieInventoryStockAdjusterProvider),
  );
}

/// Changes the consumed amount of a logged entry.
///
/// An entry logged from the inventory moves the stock with it: a larger
/// amount takes more, a smaller one gives the difference back.
class CalorieEntryAmountEditFlow {
  /// Creates the flow.
  const new({required this._saveEntry, this._adjustStock});

  final CalorieEntrySaver _saveEntry;
  final CalorieInventoryStockAdjuster? _adjustStock;

  /// Stores [entry] with [amount] and keeps its inventory stock in sync.
  Future<CalorieEntryAmountChangeResult> changeAmount({
    required CalorieEntry entry,
    required double amount,
    required DateTime now,
  }) async {
    final adjustStock = _adjustStock;
    final itemId = entry.sourceInventoryItemId?.trim();
    final reservedAmount = entry.sourceInventoryAmountToRestore;
    if (adjustStock == null ||
        !entry.canRestoreToInventory ||
        itemId == null ||
        reservedAmount == null) {
      return await _changeEntryOnly(entry: entry, amount: amount, now: now);
    }
    return await _changeWithStock(
      entry: entry,
      amount: amount,
      now: now,
      adjustStock: adjustStock,
      itemId: itemId,
      reservedAmount: reservedAmount,
    );
  }

  Future<CalorieEntryAmountChangeResult> _changeEntryOnly({
    required CalorieEntry entry,
    required double amount,
    required DateTime now,
  }) async {
    final rescaled = rescaleCalorieEntry(entry, amount: amount, now: now);
    final saved = await _saveEntry(rescaled);
    return CalorieEntryAmountChangeResult(
      saved: saved,
      entry: saved ? rescaled : entry,
      status: CalorieInventoryStockAdjustmentStatus.stockUnchanged,
    );
  }

  Future<CalorieEntryAmountChangeResult> _changeWithStock({
    required CalorieEntry entry,
    required double amount,
    required DateTime now,
    required CalorieInventoryStockAdjuster adjustStock,
    required String itemId,
    required int reservedAmount,
  }) async {
    final adjustment = await adjustStock(
      itemId: itemId,
      reservedAmount: reservedAmount,
      consumedAmount: amount,
    );
    final rescaled = rescaleCalorieEntry(
      entry,
      amount: amount,
      now: now,
    ).copyWith(sourceInventoryAmountToRestore: adjustment.reservedAmount);

    final saved = await _saveEntry(rescaled);
    if (saved) {
      return CalorieEntryAmountChangeResult(
        saved: true,
        entry: rescaled,
        status: adjustment.status,
      );
    }

    log(
      'changeAmount(): save failed, returning the stock to the stored amount '
      '(entryId=${entry.id}, itemId=$itemId, '
      'reservedAmount=${adjustment.reservedAmount}).',
      name: _amountEditFlowLogName,
    );
    await adjustStock(
      itemId: itemId,
      reservedAmount: adjustment.reservedAmount,
      consumedAmount: entry.consumedAmount,
    );
    return CalorieEntryAmountChangeResult(
      saved: false,
      entry: entry,
      status: adjustment.status,
    );
  }
}
