import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Defines inventory item consumption extension extension.
extension InventoryItemConsumptionExtension on InventoryItem {
  /// Returns the newer timestamp while keeping `lastConsumedAt` monotonic.
  DateTime latestConsumedAtOr(DateTime candidate) {
    final current = lastConsumedAt;
    if (current == null || candidate.isAfter(current)) {
      return candidate;
    }
    return current;
  }

  /// The stock that can be taken, in the stored amount unit, never below 0.
  ///
  /// Items tracked by amount count their current amount. Other items count
  /// their quantity.
  int get availableAmount {
    final amount = usesAmountProgress ? currentAmount : quantity;
    return amount > 0 ? amount : 0;
  }

  /// The package quantity that [amount] of stock still fills, rounded up and
  /// kept between 0 and the initial quantity.
  ///
  /// Returns the stored quantity when the item has no initial amount or
  /// quantity to scale from.
  int quantityForAmount(int amount) {
    if (initialAmount < 1 || initialQuantity < 1) {
      return quantity;
    }

    final ratio = amount / initialAmount;
    final projectedQuantity = (initialQuantity * ratio).ceil();
    if (projectedQuantity < 0) {
      return 0;
    }
    if (projectedQuantity > initialQuantity) {
      return initialQuantity;
    }
    return projectedQuantity;
  }

  /// This item after [amount] of its stock was taken.
  ///
  /// Returns null when [amount] is below 1 or above [availableAmount]; a
  /// caller that wants to take what is left clamps the amount first. With
  /// [consumedAt], `lastConsumedAt` moves forward to it; without, it stays.
  InventoryItem? reducedBy(int amount, {DateTime? consumedAt}) {
    if (amount < 1 || amount > availableAmount) {
      return null;
    }

    final nextLastConsumedAt = consumedAt == null
        ? lastConsumedAt
        : latestConsumedAtOr(consumedAt);
    if (usesAmountProgress) {
      final nextCurrentAmount = currentAmount - amount;
      return copyWith(
        currentAmount: nextCurrentAmount,
        quantity: quantityForAmount(nextCurrentAmount),
        lastConsumedAt: nextLastConsumedAt,
      );
    }
    return copyWith(
      quantity: quantity - amount,
      lastConsumedAt: nextLastConsumedAt,
    );
  }

  /// This item after [amount] of stock came back, capped at its initial
  /// stock. A fully stocked item forgets when it was last eaten.
  ///
  /// Returns null when [amount] is below 1.
  InventoryItem? restoredBy(int amount) {
    if (amount < 1) {
      return null;
    }
    final InventoryItem restored;
    if (usesAmountProgress) {
      final nextAmount = currentAmount + amount;
      final maxAmount = initialAmount > 0 ? initialAmount : nextAmount;
      final safeAmount = nextAmount > maxAmount ? maxAmount : nextAmount;
      restored = copyWith(
        currentAmount: safeAmount,
        quantity: quantityForAmount(safeAmount),
      );
    } else {
      final nextQuantity = quantity + amount;
      final maxQuantity = initialQuantity > 0 ? initialQuantity : nextQuantity;
      restored = copyWith(
        quantity: nextQuantity > maxQuantity ? maxQuantity : nextQuantity,
      );
    }
    return restored.isFullyAvailable
        ? restored.copyWith(lastConsumedAt: null)
        : restored;
  }
}

/// Defines pending inventory consumption.
class PendingInventoryConsumption {
  /// The pending inventory consumption.
  const new({required this.id, required this.itemId, required this.amount});

  /// The id.
  final String id;

  /// The item id.
  final String itemId;

  /// The amount.
  final int amount;
}

/// The stock of [item] that can be eaten, in its stored amount unit.
///
/// Items tracked by amount count their current amount. Other items count
/// their quantity. Returns null when nothing can be eaten.
int? consumableInventoryAmount(InventoryItem item) {
  final amount = item.availableAmount;
  return amount < 1 ? null : amount;
}
