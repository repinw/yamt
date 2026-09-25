import 'dart:math' as math;

import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_calculator.dart';

/// Stock the eat page assumes for a newly picked product. The saved stock is
/// set to the eaten amount afterwards, so any amount may be eaten.
const _openStockLimit = 1000000;

/// Ruler range for grams and milliliters without a package size.
const _weightRulerRange = 1000;

/// Ruler range for pieces without a package size.
const _pieceRulerRange = 10;

/// Amount the eat page starts with for grams and milliliters without a
/// package size.
const _weightDefaultAmount = 100;

/// Calculator for eating a newly picked [item] without a stock limit.
///
/// A gram or milliliter unit is kept even when the product has no package
/// size, so the amount is entered in that unit instead of in pieces.
InventoryItemEatCalculator openStockEatCalculator(InventoryItem item) {
  final stock = consumableInventoryAmount(item) ?? 0;
  final unit = item.amountUnit;
  if (unit == InventoryAmountUnit.gram ||
      unit == InventoryAmountUnit.milliliter) {
    final scale = item.usesAmountProgress ? item.amountScale : 1;
    return InventoryItemEatCalculator(
      item: item.copyWith(
        initialAmount: _openStockLimit,
        currentAmount: _openStockLimit,
        amountScale: scale,
      ),
      maxAmount: _openStockLimit,
      rulerMaxAmount: math.max(stock, _weightRulerRange * scale),
    );
  }
  if (item.usesAmountProgress) {
    return InventoryItemEatCalculator(
      item: item.copyWith(
        initialAmount: _openStockLimit,
        currentAmount: _openStockLimit,
      ),
      maxAmount: _openStockLimit,
      rulerMaxAmount: math.max(stock, _pieceRulerRange * item.amountScale),
    );
  }
  return InventoryItemEatCalculator(
    item: item.copyWith(quantity: _openStockLimit),
    maxAmount: _openStockLimit,
    rulerMaxAmount: math.max(stock, _pieceRulerRange),
  );
}

/// Amount to start with when [calculator] has an open gram or milliliter
/// stock and the product has no package size to start from.
int? openStockDefaultAmount(InventoryItemEatCalculator calculator) {
  if (calculator.fixedCalorieUnit == null) {
    return null;
  }
  return _weightDefaultAmount * calculator.inventoryAmountScale;
}
