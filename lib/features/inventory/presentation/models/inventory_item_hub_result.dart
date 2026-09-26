import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_entry_bundle_component.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';

/// A food picked to log together with the hub's item.
///
/// A food found by search carries its [InventoryReceiptManualProductResult];
/// its item is a draft that becomes a stock item only when the foods are
/// logged.
typedef InventoryCombinePick = ({
  InventoryItem item,
  InventoryItemEatRequest request,
  CalorieEntryBundleComponent component,
  InventoryReceiptManualProductResult? searchResult,
});

/// What the item hub closed with.
sealed class InventoryItemHubResult {
  const new();
}

/// Log the entered amount of the hub's item.
@immutable
final class InventoryItemHubEat extends InventoryItemHubResult {
  /// Creates the result.
  const new(this.request);

  /// The entered amount and log time.
  final InventoryItemEatRequest request;
}

/// Log the hub's item together with [picks] as one entry.
@immutable
final class InventoryItemHubCombine extends InventoryItemHubResult {
  /// Creates the result.
  const new({required this.request, required this.picks});

  /// The entered amount and log time of the hub's item.
  final InventoryItemEatRequest request;

  /// The other foods.
  final List<InventoryCombinePick> picks;
}

/// Keep the hub's item and [picks] in stock as one prepared meal.
@immutable
final class InventoryItemHubStoreMeal extends InventoryItemHubResult {
  /// Creates the result.
  const new({required this.request, required this.picks});

  /// The entered amount of the hub's item.
  final InventoryItemEatRequest request;

  /// The other foods.
  final List<InventoryCombinePick> picks;
}
