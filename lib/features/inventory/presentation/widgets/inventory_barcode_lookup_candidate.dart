import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';

const _barcodeAmountParser = InventoryAmountParser();
const _defaultInventoryBarcodeCandidateLimit = 5;

/// Defines inventory barcode lookup candidate source.
enum InventoryBarcodeLookupCandidateSource {
  /// Learned.
  learned,

  /// Off.
  off,
}

/// Defines inventory barcode lookup candidate.
class InventoryBarcodeLookupCandidate {
  const InventoryBarcodeLookupCandidate._({
    required this.source,
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.packageWeight,
    this.servingSize,
    this.servingQuantity,
    this.servingQuantityUnit,
    this.nutrition,
    this.globalFoodItemId,
    this.globalFoodItem,
    this.externalProduct,
    this.selectionCount = 0,
    this.uniqueUserCount = 0,
  });

  /// Creates a [InventoryBarcodeLookupCandidate] for from learned.
  factory InventoryBarcodeLookupCandidate.fromLearned(
    GlobalBarcodeCandidate candidate,
  ) {
    final item = candidate.globalFoodItem;
    return InventoryBarcodeLookupCandidate._(
      source: InventoryBarcodeLookupCandidateSource.learned,
      barcode: candidate.barcode,
      name: item.name,
      brand: item.brand,
      imageUrl: item.imageUrl,
      packageWeight: item.packageWeight,
      servingSize: item.servingSize,
      servingQuantity: item.servingQuantity,
      servingQuantityUnit: item.servingQuantityUnit,
      nutrition: item.nutrition,
      globalFoodItemId: candidate.globalFoodItemId,
      globalFoodItem: item,
      selectionCount: candidate.selectionCount,
      uniqueUserCount: candidate.uniqueUserCount,
    );
  }

  /// Creates a [InventoryBarcodeLookupCandidate] for from off product.
  factory InventoryBarcodeLookupCandidate.fromOffProduct(
    OffProductSearchResult product,
  ) {
    return InventoryBarcodeLookupCandidate._(
      source: InventoryBarcodeLookupCandidateSource.off,
      barcode: normalizeBarcode(product.code),
      name: product.name,
      brand: product.brand,
      imageUrl: product.imageUrl,
      packageWeight: product.packageWeight,
      servingSize: product.servingSize,
      servingQuantity: product.servingQuantity,
      servingQuantityUnit: product.servingQuantityUnit,
      nutrition: product.nutrition,
      externalProduct: product,
    );
  }

  /// The source.
  final InventoryBarcodeLookupCandidateSource source;

  /// The barcode.
  final String barcode;

  /// The name.
  final String name;

  /// The brand.
  final String? brand;

  /// The image url.
  final String? imageUrl;

  /// The package weight.
  final String? packageWeight;

  /// The serving size.
  final String? servingSize;

  /// The serving quantity.
  final double? servingQuantity;

  /// The serving quantity unit.
  final String? servingQuantityUnit;

  /// The nutrition.
  final GlobalFoodNutrition? nutrition;

  /// The global food item id.
  final String? globalFoodItemId;

  /// The global food item.
  final GlobalFoodItem? globalFoodItem;

  /// The external product.
  final OffProductSearchResult? externalProduct;

  /// The selection count.
  final int selectionCount;

  /// The unique user count.
  final int uniqueUserCount;
}

/// Action chosen for a barcode candidate.
enum InventoryBarcodeCandidateAction {
  /// Save to inventory.
  addToInventory,

  /// Continue into eat flow.
  eatNow,
}

/// Defines inventory barcode product selection callback typedef.
typedef InventoryBarcodeProductSelectionCallback =
    Future<bool> Function(
      InventoryBarcodeLookupCandidate candidate,
      String scannedBarcode,
      InventoryBarcodeCandidateAction action,
    );

/// Defines inventory barcode not found callback typedef.
typedef InventoryBarcodeNotFoundCallback =
    Future<bool> Function(String scannedBarcode);

/// Defines inventory barcode manual product callback typedef.
typedef InventoryBarcodeManualProductCallback =
    Future<bool> Function(String scannedBarcode);

/// Merge inventory barcode candidates.
List<InventoryBarcodeLookupCandidate> mergeInventoryBarcodeCandidates({
  required List<GlobalBarcodeCandidate> learnedCandidates,
  required List<OffProductSearchResult> offCandidates,
  int limit = _defaultInventoryBarcodeCandidateLimit,
}) {
  final merged = <InventoryBarcodeLookupCandidate>[];
  final seenOffKeys = <String>{};

  for (final candidate in learnedCandidates) {
    final resolved = InventoryBarcodeLookupCandidate.fromLearned(candidate);
    merged.add(resolved);
    if (merged.length == limit) {
      return merged;
    }
  }
  for (final candidate in offCandidates) {
    final resolved = InventoryBarcodeLookupCandidate.fromOffProduct(candidate);
    final key = inventoryBarcodeCandidateDedupeKey(resolved);
    if (!seenOffKeys.add(key)) {
      continue;
    }
    merged.add(resolved);
    if (merged.length == limit) {
      break;
    }
  }
  return merged;
}

/// Inventory barcode candidate dedupe key.
String inventoryBarcodeCandidateDedupeKey(
  InventoryBarcodeLookupCandidate candidate,
) {
  final normalizedName = candidate.name.trim().toLowerCase();
  final normalizedBrand = (candidate.brand ?? '').trim().toLowerCase();
  final normalizedWeight = _normalizedBarcodeCandidateWeight(
    candidate.packageWeight,
  );
  return '${candidate.barcode}|$normalizedName|$normalizedBrand|'
      '$normalizedWeight';
}

/// Source-aware key suffix for barcode candidate widgets.
String inventoryBarcodeCandidateWidgetKeySuffix(
  InventoryBarcodeLookupCandidate candidate,
) {
  return '${candidate.source.name}|'
      '${inventoryBarcodeCandidateDedupeKey(candidate)}';
}

String _normalizedBarcodeCandidateWeight(String? rawWeight) {
  final parsed = _barcodeAmountParser.tryParse(
    rawWeight: rawWeight,
    quantity: 1,
  );
  if (parsed != null) {
    return '${parsed.amount}${parsed.unit.code}';
  }
  return rawWeight?.trim().toLowerCase() ?? '';
}
