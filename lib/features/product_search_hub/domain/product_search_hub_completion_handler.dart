import 'package:flutter/widgets.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_completion_result.dart';

/// Contract for completing a product picked in the product search hub.
abstract interface class ProductSearchHubCompletionHandler {
  /// Handles completion and persistence of an edited product result.
  Future<ProductSearchHubCompletionResult> completeResult({
    required BuildContext context,
    required String sourceKey,
    required InventoryReceiptManualProductResult result,
    MealType? preselectedMealType,
    DateTime? preselectedLoggedAt,
  });
}
