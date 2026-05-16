import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

part 'manual_product_recent_items_service.g.dart';

const _manualProductRecentItemLimit = 6;

/// Application service for recent manual product candidates.
@Riverpod(dependencies: [inventoryItemRepository])
ManualProductRecentItemsService manualProductRecentItemsService(Ref ref) {
  return ManualProductRecentItemsService(
    ref.read(inventoryItemRepositoryProvider),
  );
}

/// Reads and prepares recent manual product items.
class ManualProductRecentItemsService {
  /// Creates a recent item service.
  const ManualProductRecentItemsService(this._repository);

  final InventoryItemRepository _repository;

  /// Reads recent manual products, newest first and deduped.
  Future<List<InventoryItem>> readRecentItems() async {
    final repository = _repository;
    if (repository is InventoryItemRecentManualReader) {
      final recentReader = repository as InventoryItemRecentManualReader;
      final items = await recentReader.readRecentManualItems(
        limit: _manualProductRecentItemLimit,
      );
      return buildManualProductRecentItems(items);
    }

    throw StateError(
      'Inventory repository must support limited recent manual reads.',
    );
  }
}

/// Builds recent manual products, newest first and deduped by stable identity.
List<InventoryItem> buildManualProductRecentItems(List<InventoryItem> items) {
  final sortedItems =
      items
          .where((item) => item.canBeSavedToInventory)
          .where((item) => item.name.trim().isNotEmpty)
          .where((item) => item.isManuallyAdded)
          .toList(growable: false)
        ..sort((left, right) => right.entryDate.compareTo(left.entryDate));

  final recentItems = <InventoryItem>[];
  final seenKeys = <String>{};
  for (final item in sortedItems) {
    final key = _recentItemKey(item);
    if (!seenKeys.add(key)) {
      continue;
    }
    recentItems.add(item);
    if (recentItems.length >= _manualProductRecentItemLimit) {
      break;
    }
  }
  return recentItems;
}

/// Returns the existing global id unless the item is still pending persistence.
String? manualProductRecentItemGlobalFoodItemId(InventoryItem item) {
  final globalFoodItemId = item.globalFoodItemId.trim();
  if (globalFoodItemId.isEmpty || isPendingGlobalFoodItemId(globalFoodItemId)) {
    return null;
  }
  return globalFoodItemId;
}

/// Creates an inventory item from a barcode lookup global food candidate.
InventoryItem inventoryItemFromBarcodeCandidate({
  required InventoryItem baseItem,
  required GlobalFoodItem globalFoodItem,
  required String barcode,
}) {
  final normalizedBarcode = normalizeBarcode(barcode);
  final weight = globalFoodItem.packageWeight ?? baseItem.weight;
  return baseItem
      .copyWith(
        globalFoodItemId: globalFoodItem.id,
        name: globalFoodItem.name,
        brand: globalFoodItem.brand,
        category: globalFoodItem.category,
        barcode: normalizedBarcode.isEmpty ? barcode : normalizedBarcode,
        imageUrl: globalFoodItem.imageUrl,
        weight: weight,
        foodFingerprint: globalFoodItem.resolvedFoodFingerprint,
        servingSize: globalFoodItem.servingSize,
        servingQuantity: globalFoodItem.servingQuantity,
        servingQuantityUnit: globalFoodItem.servingQuantityUnit,
        nutrition: globalFoodItem.nutrition,
      )
      .withDerivedAmount(
        weight: weight,
        quantity: baseItem.quantity,
        fallbackUnit: baseItem.amountUnit,
      );
}

String _recentItemKey(InventoryItem item) {
  final globalFoodItemId = item.globalFoodItemId.trim();
  if (globalFoodItemId.isNotEmpty &&
      !isPendingGlobalFoodItemId(globalFoodItemId)) {
    return 'global:$globalFoodItemId';
  }

  final barcode = item.normalizedBarcode;
  if (barcode != null && barcode.isNotEmpty) {
    return 'barcode:$barcode';
  }

  final normalizedName = item.name.trim().toLowerCase();
  final normalizedBrand = (item.brand ?? '').trim().toLowerCase();
  final normalizedWeight = (item.weight ?? '').trim().toLowerCase();
  return 'name:$normalizedName'
      '|brand:$normalizedBrand'
      '|weight:$normalizedWeight';
}
