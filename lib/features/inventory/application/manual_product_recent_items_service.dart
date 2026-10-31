import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

part 'manual_product_recent_items_service.g.dart';

const _manualProductRecentItemLimit = 20;

// The same product is often added many times, so read more documents than the
// list shows and keep the newest one of each product.
const _manualProductRecentReadLimit = 80;

/// Application service for recent product candidates.
@riverpod
ManualProductRecentItemsService manualProductRecentItemsService(Ref ref) {
  return ManualProductRecentItemsService(
    ref.read(inventoryItemRepositoryProvider),
  );
}

/// Reads and prepares recent product items.
class ManualProductRecentItemsService {
  /// Creates a recent item service.
  const new(this._repository);

  final InventoryItemRepository _repository;

  /// Reads the products added by hand or eaten from the Vorrat, last
  /// chosen first and deduped.
  ///
  /// The time of the last eat is encrypted, so no query can sort by it:
  /// the eaten items come from the whole Vorrat, which the app usually has
  /// in its cache.
  Future<List<InventoryItem>> readRecentItems() async {
    final repository = _repository;
    if (repository is InventoryItemRecentManualReader) {
      final recentReader = repository as InventoryItemRecentManualReader;
      final (manualItems, eatenItems) = await (
        recentReader.readRecentManualItems(
          limit: _manualProductRecentReadLimit,
        ),
        _readEatenItems(repository),
      ).wait;
      return buildManualProductRecentItems([...manualItems, ...eatenItems]);
    }

    throw StateError(
      'Inventory repository must support limited recent manual reads.',
    );
  }

  /// The items eaten from the Vorrat.
  Future<List<InventoryItem>> _readEatenItems(
    InventoryItemRepository repository,
  ) async {
    final items = await repository.readAllForChange();
    return items
        .where((item) => item.lastConsumedAt != null)
        .toList(growable: false);
  }
}

/// Builds recent products from [items], last chosen first and deduped by
/// stable identity: an item counts from its last eat, or from when it was
/// added by hand.
List<InventoryItem> buildManualProductRecentItems(List<InventoryItem> items) {
  DateTime chosenAt(InventoryItem item) =>
      item.lastConsumedAt ?? item.entryDate;
  final sortedItems =
      items
          .where((item) => item.canBeSavedToInventory)
          .where((item) => item.name.trim().isNotEmpty)
          .where((item) => item.isManuallyAdded || item.lastConsumedAt != null)
          .toList(growable: false)
        ..sort((left, right) => chosenAt(right).compareTo(chosenAt(left)));

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
