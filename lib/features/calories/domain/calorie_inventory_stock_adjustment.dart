/// How far the inventory stock followed a changed consumed amount.
enum CalorieInventoryStockAdjustmentStatus {
  /// The stock now matches the new amount.
  applied,

  /// The stock ran out before it could follow the increase.
  stockExhausted,

  /// The source item is no longer in the inventory.
  sourceMissing,

  /// The amount does not map to the stock, so the stock stayed as it was.
  stockUnchanged,
}

/// Result of adjusting the inventory stock behind a logged entry.
class CalorieInventoryStockAdjustment {
  /// Creates the adjustment result.
  const new({required this.status, required this.reservedAmount});

  /// Creates a result for a stock that now matches the new amount.
  const new applied(int reservedAmount)
    : this(
        status: CalorieInventoryStockAdjustmentStatus.applied,
        reservedAmount: reservedAmount,
      );

  /// Creates a result for a stock that ran out during the increase.
  const new stockExhausted(int reservedAmount)
    : this(
        status: CalorieInventoryStockAdjustmentStatus.stockExhausted,
        reservedAmount: reservedAmount,
      );

  /// Creates a result for a source item that is gone.
  const new sourceMissing(int reservedAmount)
    : this(
        status: CalorieInventoryStockAdjustmentStatus.sourceMissing,
        reservedAmount: reservedAmount,
      );

  /// Creates a result for a stock that stayed as it was.
  const new stockUnchanged(int reservedAmount)
    : this(
        status: CalorieInventoryStockAdjustmentStatus.stockUnchanged,
        reservedAmount: reservedAmount,
      );

  /// How far the stock followed the new amount.
  final CalorieInventoryStockAdjustmentStatus status;

  /// Inventory amount the entry holds after the adjustment.
  ///
  /// It becomes the entry's `sourceInventoryAmountToRestore`, so deleting the
  /// entry later returns exactly what it still takes from the stock.
  final int reservedAmount;
}
