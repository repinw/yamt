import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/domain/inventory_receipt_manual_product_models.dart';

/// A food found by search for a meal: the product with its draft item, and
/// the amount entered on its eat page.
typedef InventoryMealFoodPick = ({
  InventoryReceiptManualProductResult result,
  InventoryItemEatRequest request,
});
