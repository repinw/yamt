import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';

/// User intent chosen when confirming an inventory item eat sheet.
enum InventoryItemEatSheetIntent {
  /// Log the item and finish the current flow.
  logOnly,

  /// Keep the item hub's foods in stock as a prepared meal instead of
  /// logging them.
  storeAsMeal,
}

/// Result returned by inventory item eat sheet.
@immutable
class InventoryItemEatSheetResult {
  /// Creates eat sheet result.
  const new({required this.request, required this.intent});

  /// Eat request.
  final InventoryItemEatRequest request;

  /// User continuation intent.
  final InventoryItemEatSheetIntent intent;
}
