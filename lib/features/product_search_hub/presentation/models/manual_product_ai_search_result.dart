import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';

/// Result returned from the AI food creation page.
class ManualProductAiSearchResult {
  /// Creates a result.
  const new({
    required this.item,
    required this.action,
    required this.globalPackageWeight,
    this.eatSelection,
  });

  /// Built inventory item.
  final InventoryItem item;

  /// Requested follow-up action.
  final InventoryReceiptManualProductAction action;

  /// Package weight to persist globally.
  final String globalPackageWeight;

  /// Generic eat selection for callers that continue into an eat flow.
  final EatSelection? eatSelection;
}
