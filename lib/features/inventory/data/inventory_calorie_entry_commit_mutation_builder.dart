import 'package:uuid/uuid.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';

/// Builds inventory mutations and activity events for calorie entry commits.
class InventoryCalorieEntryCommitMutationBuilder {
  /// The constructor.
  const new();

  /// Builds the committed inventory item after consumption.
  InventoryItem? buildCommittedItem({
    required InventoryItem item,
    required int amount,
    required DateTime consumedAt,
  }) {
    if (amount < 1) {
      return null;
    }

    final nextLastConsumedAt = item.latestConsumedAtOr(consumedAt);

    if (item.usesAmountProgress) {
      if (item.currentAmount < amount) {
        return null;
      }

      final nextCurrentAmount = item.currentAmount - amount;
      return item.copyWith(
        currentAmount: nextCurrentAmount,
        quantity: _quantityForCurrentAmount(
          item: item,
          currentAmount: nextCurrentAmount,
        ),
        lastConsumedAt: nextLastConsumedAt,
      );
    }

    if (item.quantity < amount) {
      return null;
    }
    return item.copyWith(
      quantity: item.quantity - amount,
      lastConsumedAt: nextLastConsumedAt,
    );
  }

  /// Builds the Firestore document update map for the committed inventory item.
  Map<String, dynamic> buildInventoryUpdate(InventoryItem item) {
    return <String, dynamic>{
      'quantity': item.quantity,
      'current_amount': item.currentAmount,
      'last_consumed_at': item.lastConsumedAt?.toIso8601String(),
    };
  }

  /// Builds the activity event record for the consumption stock change.
  InventoryActivityEvent? buildActivityEvent({
    required InventoryActivityActor? actor,
    required InventoryItem beforeItem,
    required InventoryItem afterItem,
    required int amount,
    required DateTime happenedAt,
  }) {
    if (actor == null) {
      return null;
    }

    return InventoryActivityEvent.fromStockChange(
      id: _newActivityEventId(),
      type: InventoryActivityEventType.itemConsumed,
      actor: actor,
      item: beforeItem,
      amount: amount,
      beforeQuantity: beforeItem.quantity,
      afterQuantity: afterItem.quantity,
      beforeCurrentAmount: beforeItem.currentAmount,
      afterCurrentAmount: afterItem.currentAmount,
      happenedAt: happenedAt,
    );
  }

  int _quantityForCurrentAmount({
    required InventoryItem item,
    required int currentAmount,
  }) {
    final initialAmount = item.initialAmount;
    final initialQuantity = item.initialQuantity;
    if (initialAmount < 1 || initialQuantity < 1) {
      return item.quantity;
    }

    final ratio = currentAmount / initialAmount;
    final projectedQuantity = (initialQuantity * ratio).ceil();
    if (projectedQuantity < 0) {
      return 0;
    }
    if (projectedQuantity > initialQuantity) {
      return initialQuantity;
    }
    return projectedQuantity;
  }

  String _newActivityEventId() {
    return const Uuid().v4();
  }
}
