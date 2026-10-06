import 'package:uuid/uuid.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Builds inventory mutations and activity events for calorie entry commits.
class InventoryCalorieEntryCommitMutationBuilder {
  /// The constructor.
  const new();

  /// Builds the Firestore document update map for the committed inventory item.
  Map<String, dynamic> buildInventoryUpdate(InventoryItem item) {
    return <String, dynamic>{
      'quantity': item.quantity,
      'current_amount': item.currentAmount,
      'last_consumed_at': item.lastConsumedAt?.toIso8601String(),
    };
  }

  /// Builds the activity event record for a stock change of [type].
  InventoryActivityEvent? buildActivityEvent({
    required InventoryActivityEventType type,
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
      type: type,
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

  String _newActivityEventId() {
    return const Uuid().v4();
  }
}
