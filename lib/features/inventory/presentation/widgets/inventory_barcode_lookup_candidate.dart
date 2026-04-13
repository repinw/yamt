import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';

const _barcodeAmountParser = InventoryAmountParser();
const _defaultInventoryBarcodeCandidateLimit = 5;

enum InventoryBarcodeLookupCandidateSource { learned, off }

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

  final InventoryBarcodeLookupCandidateSource source;
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? packageWeight;
  final String? servingSize;
  final double? servingQuantity;
  final String? servingQuantityUnit;
  final GlobalFoodNutrition? nutrition;
  final String? globalFoodItemId;
  final GlobalFoodItem? globalFoodItem;
  final OffProductSearchResult? externalProduct;
  final int selectionCount;
  final int uniqueUserCount;
}

typedef InventoryBarcodeProductSelectionCallback =
    Future<bool> Function(
      InventoryBarcodeLookupCandidate candidate,
      String scannedBarcode,
    );

typedef InventoryBarcodeNotFoundCallback =
    Future<bool> Function(String scannedBarcode);

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
