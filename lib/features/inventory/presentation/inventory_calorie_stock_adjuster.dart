import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/'
    'calorie_entry_amount_edit_flow.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_inventory_stock_adjustment.dart';
import 'package:yamt/features/inventory/application/'
    'inventory_item_eat_policy.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_controller_access.dart';

part 'inventory_calorie_stock_adjuster.g.dart';

const _stockAdjusterLogName = 'InventoryCalorieStockAdjuster';

/// Inventory-enabled stock adjustment for changed calorie entry amounts.
///
/// Items measured in grams or milliliters consume and return the difference.
/// Items counted in pieces keep their stock: a piece is used up no matter how
/// the estimated amount behind it changes.
@riverpod
CalorieInventoryStockAdjuster inventoryCalorieStockAdjuster(Ref ref) {
  ref.keepAlive();
  final repository = ref.read(inventoryItemRepositoryProvider);

  return ({
    required String itemId,
    required int reservedAmount,
    required double consumedAmount,
  }) async {
    final item = await findInventoryItem(
      repository: repository,
      itemId: itemId,
    );
    if (item == null) {
      log(
        'Inventory source of the changed entry is gone (itemId=$itemId).',
        name: _stockAdjusterLogName,
      );
      return CalorieInventoryStockAdjustment(
        status: CalorieInventoryStockAdjustmentStatus.sourceMissing,
        reservedAmount: reservedAmount,
      );
    }

    if (!inventoryItemUsesFixedCalorieUnit(item)) {
      return CalorieInventoryStockAdjustment(
        status: CalorieInventoryStockAdjustmentStatus.stockUnchanged,
        reservedAmount: reservedAmount,
      );
    }

    final targetAmount = consumedAmount.round();
    final delta = targetAmount - reservedAmount;
    if (delta == 0) {
      return CalorieInventoryStockAdjustment(
        status: CalorieInventoryStockAdjustmentStatus.applied,
        reservedAmount: reservedAmount,
      );
    }
    if (delta > 0) {
      return await _consumeMore(
        ref: ref,
        itemId: itemId,
        reservedAmount: reservedAmount,
        additionalAmount: delta,
      );
    }
    return await _returnDifference(
      ref: ref,
      itemId: itemId,
      reservedAmount: reservedAmount,
      targetAmount: targetAmount,
    );
  };
}

/// Takes [additionalAmount] more from the stock, as far as it reaches.
Future<CalorieInventoryStockAdjustment> _consumeMore({
  required Ref ref,
  required String itemId,
  required int reservedAmount,
  required int additionalAmount,
}) async {
  final result = await withInventoryController<InventoryItemReductionResult?>(
    ref: ref,
    operationName: 'consume more of inventory item $itemId',
    fallbackValue: null,
    operation: (controller) =>
        controller.eatItemDetailed(itemId, additionalAmount),
  );
  final removedAmount = result?.removedAmount ?? 0;
  if (removedAmount < additionalAmount) {
    log(
      'Inventory stock did not cover the larger amount '
      '(itemId=$itemId, requested=$additionalAmount, removed=$removedAmount).',
      name: _stockAdjusterLogName,
    );
    return CalorieInventoryStockAdjustment(
      status: CalorieInventoryStockAdjustmentStatus.stockExhausted,
      reservedAmount: reservedAmount + removedAmount,
    );
  }
  return CalorieInventoryStockAdjustment(
    status: CalorieInventoryStockAdjustmentStatus.applied,
    reservedAmount: reservedAmount + removedAmount,
  );
}

/// Gives the amount above [targetAmount] back to the stock.
Future<CalorieInventoryStockAdjustment> _returnDifference({
  required Ref ref,
  required String itemId,
  required int reservedAmount,
  required int targetAmount,
}) async {
  final restored = await withInventoryController<bool>(
    ref: ref,
    operationName: 'return part of inventory item $itemId',
    fallbackValue: false,
    operation: (controller) =>
        controller.restoreConsumedItem(itemId, reservedAmount - targetAmount),
  );
  if (!restored) {
    return CalorieInventoryStockAdjustment(
      status: CalorieInventoryStockAdjustmentStatus.stockUnchanged,
      reservedAmount: reservedAmount,
    );
  }
  return CalorieInventoryStockAdjustment(
    status: CalorieInventoryStockAdjustmentStatus.applied,
    reservedAmount: targetAmount,
  );
}
