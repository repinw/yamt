import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/scanner/data/adapters/'
    'yamt_nutrition_converter.dart';
import 'package:yamt/features/scanner/domain/contracts/'
    'receipt_manual_product_picker.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';

/// Concrete adapter implementing [ReceiptManualProductPicker] by navigating
/// to Yamt's app-wide ProductSearchHub.
class YamtReceiptManualProductPicker implements ReceiptManualProductPicker {
  /// Creates a [YamtReceiptManualProductPicker].
  const YamtReceiptManualProductPicker();

  @override
  Future<ProductCandidate?> pickOrEditProduct(
    BuildContext context, {
    required String initialQuery,
    String? barcode,
    String? rawName,
    String? storeName,
    String? brand,
    String? weight,
  }) async {
    final now = DateTime.now();
    final tempItem = InventoryItem.create(
      id: 'picker_${now.microsecondsSinceEpoch}',
      name: rawName ?? initialQuery,
      entryDate: now,
      storeName: storeName ?? '',
      quantity: 1,
      barcode: barcode,
      brand: brand,
      weight: weight,
    );

    final result = await context.push<InventoryReceiptManualProductResult>(
      AppRoutes.homeProductSearchHub,
      extra: ProductSearchHubRouteArgs.selection(
        item: tempItem,
        initialQuery: initialQuery,
        initialIntent: ProductSearchHubInitialIntent.search,
        autofocusSearchField: barcode == null,
      ),
    );

    if (result == null) return null;
    return mapResultToCandidate(result);
  }

  @override
  Future<ProductCandidate?> createCustomProduct(
    BuildContext context, {
    String? barcode,
    String? initialName,
  }) {
    return pickOrEditProduct(
      context,
      initialQuery: initialName ?? '',
      barcode: barcode,
    );
  }

  /// Converts an [InventoryReceiptManualProductResult] into a
  /// [ProductCandidate].
  static ProductCandidate mapResultToCandidate(
    InventoryReceiptManualProductResult result,
  ) {
    final item = result.item;
    return ProductCandidate(
      id: result.selectedGlobalFoodItemId ?? item.id,
      name: item.name,
      brand: item.brand,
      barcode: item.barcode,
      imageUrl: item.imageUrl,
      packageSize: item.weight,
      source: CandidateSource.manualSearch,
      nutritionPer100g: YamtNutritionConverter.toNutritionMap(item.nutrition),
    );
  }
}
