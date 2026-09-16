import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';

/// User intent chosen when confirming an inventory item eat sheet.
enum InventoryItemEatSheetIntent {
  /// Log the item and finish the current flow.
  logOnly,

  /// Log the item and continue adding more foods.
  addMore,
}

/// Result returned by inventory item eat sheet.
@immutable
class InventoryItemEatSheetResult {
  /// Creates eat sheet result.
  const InventoryItemEatSheetResult({
    required this.request,
    required this.intent,
  });

  /// Eat request.
  final InventoryItemEatRequest request;

  /// User continuation intent.
  final InventoryItemEatSheetIntent intent;

  /// Whether user wants to add more foods after logging this one.
  bool get addMoreRequested => intent == InventoryItemEatSheetIntent.addMore;
}
