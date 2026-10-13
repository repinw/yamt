import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_item_matcher.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart';
import 'package:yamt/features/inventory/domain/'
    'receipt_review_item_draft.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_manual_product_search_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_receipt_candidate_picker_sheet.dart';

const _swapGlobalFoodIdPrefix = 'global-food-';

/// Describes the product data that should replace an inventory item.
class InventoryItemCandidateSwapRequest {
  /// The inventory item candidate swap request.
  const new({
    required this.resolvedProduct,
    required this.requiresGlobalPersistence,
    required this.weight,
  });

  /// The resolved product.
  final GlobalFoodItem resolvedProduct;

  /// The requires global persistence.
  final bool requiresGlobalPersistence;

  /// The weight.
  final String? weight;
}

/// Runs the inventory candidate swap picker and returns the chosen product.
Future<InventoryItemCandidateSwapRequest?> showInventoryItemCandidateSwapFlow({
  required BuildContext context,
  required WidgetRef ref,
  required InventoryItem item,
}) async {
  final matcher = ref.read(globalFoodItemMatcherProvider);
  final candidates = await matcher.findCandidates(item);
  if (!context.mounted) {
    return null;
  }

  final draft = ReceiptReviewItemDraft(
    item: item,
    candidates: candidates,
    selectedGlobalFoodItemId: matcher.defaultSelectionFor(candidates),
    selectionNeedsReview: matcher.defaultSelectionNeedsReviewFor(candidates),
    ocrName: item.ocrName,
  );
  final selection = await showModalBottomSheet<ReceiptCandidatePickerSelection>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return InventoryReceiptCandidatePickerSheet(draft: draft);
    },
  );
  if (!context.mounted || selection == null) {
    return null;
  }

  return await switch (selection.kind) {
    ReceiptCandidatePickerSelectionKind.candidate =>
      buildInventoryItemCandidateSwapRequestFromCandidate(
        draft: draft,
        candidateId: selection.candidateId,
        sourceItem: item,
      ),
    ReceiptCandidatePickerSelectionKind.manualEntry => _manualEntryRequest(
      context: context,
      item: item,
      matcher: matcher,
    ),
  };
}

/// Builds a swap request from a selected candidate id.
InventoryItemCandidateSwapRequest?
buildInventoryItemCandidateSwapRequestFromCandidate({
  required ReceiptReviewItemDraft draft,
  required String? candidateId,
  required InventoryItem sourceItem,
}) {
  if (candidateId == null) {
    return null;
  }

  final candidate = _candidateById(draft.candidates, candidateId);
  if (candidate == null) {
    return null;
  }

  return InventoryItemCandidateSwapRequest(
    resolvedProduct: candidate.item,
    requiresGlobalPersistence: candidate.requiresPersistence,
    weight: sourceItem.weight ?? candidate.item.packageWeight,
  );
}

Future<InventoryItemCandidateSwapRequest?> _manualEntryRequest({
  required BuildContext context,
  required InventoryItem item,
  required GlobalFoodItemMatcher matcher,
}) async {
  // The hub reads the request and returns the picked product.
  final result = await context.push<InventoryReceiptManualProductResult>(
    AppRoutes.homeProductSearchHub,
    extra: InventoryManualProductSearchRequest(
      item: item,
      includeStoreInSearch: false,
      includeWeightInSearch: false,
    ),
  );
  if (!context.mounted || result == null) {
    return null;
  }

  return buildInventoryItemCandidateSwapRequestFromManualResult(
    result: result,
    matcher: matcher,
  );
}

/// Builds a swap request from the manual product search result.
InventoryItemCandidateSwapRequest
buildInventoryItemCandidateSwapRequestFromManualResult({
  required InventoryReceiptManualProductResult result,
  required GlobalFoodItemMatcher matcher,
}) {
  final selectedProduct = result.selectedProduct;
  if (selectedProduct != null) {
    final candidate = matcher.candidateFromExternalResult(selectedProduct);
    return InventoryItemCandidateSwapRequest(
      resolvedProduct: _productFromManualItem(
        item: result.item,
        id: candidate.item.id,
        packageWeight: selectedProduct.packageWeight,
        servingSize: selectedProduct.servingSize,
        servingQuantity: selectedProduct.servingQuantity,
        servingQuantityUnit: selectedProduct.servingQuantityUnit,
      ),
      requiresGlobalPersistence: true,
      weight: result.item.weight,
    );
  }

  return InventoryItemCandidateSwapRequest(
    resolvedProduct: _productFromManualItem(
      item: result.item,
      id: _manualResultProductId(result),
      packageWeight: result.item.weight,
      servingSize: result.item.servingSize,
      servingQuantity: result.item.servingQuantity,
      servingQuantityUnit: result.item.servingQuantityUnit,
    ),
    requiresGlobalPersistence: result.requiresGlobalPersistence,
    weight: result.item.weight,
  );
}

/// The catalog id of the picked catalog product, a new id for a product the
/// swap writes to the catalog, or else the pending id: a product that skips
/// the catalog without a catalog pick, like an AI food (#655) or a product
/// whose front photo shows no package (#658), is the user's own.
String _manualResultProductId(InventoryReceiptManualProductResult result) {
  final selectedGlobalFoodItemId = result.selectedGlobalFoodItemId;
  if (selectedGlobalFoodItemId != null) {
    return selectedGlobalFoodItemId;
  }
  if (result.requiresGlobalPersistence) {
    return '$_swapGlobalFoodIdPrefix${const Uuid().v4()}';
  }
  return buildPendingGlobalFoodItemId(result.item.resolvedFoodFingerprint);
}

GlobalFoodMatchCandidate? _candidateById(
  List<GlobalFoodMatchCandidate> candidates,
  String candidateId,
) {
  return candidates.firstWhereOrNull((candidate) {
    return candidate.item.id == candidateId;
  });
}

GlobalFoodItem _productFromManualItem({
  required InventoryItem item,
  required String id,
  required String? packageWeight,
  required String? servingSize,
  required double? servingQuantity,
  required String? servingQuantityUnit,
}) {
  return GlobalFoodItem.create(
    id: id,
    name: item.name,
    now: DateTime.now(),
    brand: item.brand,
    category: item.category,
    barcode: item.barcode,
    imageUrl: item.imageUrl,
    packageWeight: packageWeight,
    servingSize: servingSize,
    servingQuantity: servingQuantity,
    servingQuantityUnit: servingQuantityUnit,
    foodFingerprint: item.resolvedFoodFingerprint,
    nutrition: item.nutrition,
  );
}
