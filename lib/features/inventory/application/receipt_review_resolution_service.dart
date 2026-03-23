import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/data/receipt_to_review_item_draft_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

part 'receipt_review_resolution_service.g.dart';

const Uuid _globalFoodItemUuid = Uuid();
const _resolutionLogName = 'ReceiptReviewResolutionService';

class ReceiptReviewPersistResult {
  const ReceiptReviewPersistResult({
    required this.saved,
    required this.inventoryItems,
    this.itemsNeedingEnrichment = const <InventoryItem>[],
  });

  final bool saved;
  final List<InventoryItem> inventoryItems;
  final List<InventoryItem> itemsNeedingEnrichment;
}

@Riverpod(keepAlive: true)
ReceiptReviewResolutionService receiptReviewResolutionService(Ref ref) {
  return ReceiptReviewResolutionService(
    mapper: ref.watch(receiptToReviewItemDraftMapperProvider),
    matcher: ref.watch(globalFoodItemMatcherProvider),
    globalFoodItemRepository: ref.watch(globalFoodItemRepositoryProvider),
    inventoryItemRepository: ref.watch(inventoryItemRepositoryProvider),
  );
}

class ReceiptReviewResolutionService {
  ReceiptReviewResolutionService({
    required ReceiptToReviewItemDraftMapper mapper,
    required GlobalFoodItemMatcher matcher,
    required GlobalFoodItemRepository globalFoodItemRepository,
    required InventoryItemRepository inventoryItemRepository,
    String Function()? globalFoodItemIdGenerator,
  }) : _mapper = mapper,
       _matcher = matcher,
       _globalFoodItemRepository = globalFoodItemRepository,
       _inventoryItemRepository = inventoryItemRepository,
       _globalFoodItemIdGenerator =
           globalFoodItemIdGenerator ?? _defaultGlobalFoodItemId;

  final ReceiptToReviewItemDraftMapper _mapper;
  final GlobalFoodItemMatcher _matcher;
  final GlobalFoodItemRepository _globalFoodItemRepository;
  final InventoryItemRepository _inventoryItemRepository;
  final String Function() _globalFoodItemIdGenerator;

  Future<List<ReceiptReviewItemDraft>> prepareDrafts(
    ReceiptAnalysisExtraction extraction,
  ) async {
    final baseDrafts = _mapper.map(extraction);
    final resolvedDrafts = <ReceiptReviewItemDraft>[];

    for (final draft in baseDrafts) {
      if (!draft.canBeSavedToInventory) {
        resolvedDrafts.add(draft);
        continue;
      }

      final candidates = await _matcher.findCandidates(draft.item);
      final selectedId = _matcher.defaultSelectionFor(candidates);
      final selectionNeedsReview = _matcher.defaultSelectionNeedsReviewFor(
        candidates,
      );
      resolvedDrafts.add(
        draft.copyWith(
          candidates: candidates,
          selectedGlobalFoodItemId: selectedId,
          selectionNeedsReview: selectionNeedsReview,
        ),
      );
    }

    return resolvedDrafts;
  }

  Future<ReceiptReviewPersistResult> persistReviewedItems(
    List<ReceiptReviewItemDraft> reviewedItems,
  ) async {
    final now = DateTime.now();
    final resolvedItems = <_ResolvedReviewItem>[];
    final globalItemsToSave = <GlobalFoodItem>[];

    for (final draft in reviewedItems) {
      if (!draft.canBeSavedToInventory) {
        continue;
      }

      final selectedCandidate = draft.selectedCandidate;
      final shouldReuseSelected =
          selectedCandidate != null && !draft.differsFromSelectedCandidate;
      final shouldPersistSelectedCandidate =
          shouldReuseSelected && selectedCandidate.requiresPersistence;

      final resolvedProduct = shouldReuseSelected
          ? selectedCandidate.item
          : _buildProductFromDraft(
              draft: draft,
              now: now,
              status: selectedCandidate == null
                  ? (draft.requestAiEnrichment
                        ? GlobalFoodItemStatus.candidate
                        : GlobalFoodItemStatus.active)
                  : GlobalFoodItemStatus.candidate,
              selectedProduct: selectedCandidate?.item,
            );
      final requiresGlobalPersistence =
          !shouldReuseSelected || shouldPersistSelectedCandidate;
      if (requiresGlobalPersistence) {
        globalItemsToSave.add(resolvedProduct);
      }

      resolvedItems.add(
        _ResolvedReviewItem(
          sourceDraft: draft,
          sourceItem: draft.item,
          resolvedProduct: resolvedProduct,
          requiresGlobalPersistence: requiresGlobalPersistence,
        ),
      );
    }

    final globalSaved =
        globalItemsToSave.isEmpty ||
        await _globalFoodItemRepository.appendAll(globalItemsToSave);
    if (!globalSaved) {
      log(
        'Failed to persist global food items. '
        'Continuing with inventory-only save.',
        name: _resolutionLogName,
      );
    }

    final inventoryItemsToSave = resolvedItems
        .map(
          (item) => _inventoryItemForResolvedProduct(
            item,
            canReferenceGlobalItem:
                globalSaved || !item.requiresGlobalPersistence,
          ),
        )
        .toList(growable: false);
    final itemsNeedingEnrichment = <InventoryItem>[
      for (final item in resolvedItems.indexed)
        if (item.$2.sourceDraft.requestAiEnrichment)
          inventoryItemsToSave[item.$1],
    ];

    final inventorySaved = await _inventoryItemRepository.appendAll(
      inventoryItemsToSave,
    );
    return ReceiptReviewPersistResult(
      saved: inventorySaved,
      inventoryItems: inventorySaved
          ? inventoryItemsToSave
          : const <InventoryItem>[],
      itemsNeedingEnrichment: inventorySaved
          ? itemsNeedingEnrichment
          : const <InventoryItem>[],
    );
  }

  GlobalFoodItem _buildProductFromDraft({
    required ReceiptReviewItemDraft draft,
    required DateTime now,
    required GlobalFoodItemStatus status,
    GlobalFoodItem? selectedProduct,
  }) {
    return GlobalFoodItem.create(
      id: _globalFoodItemIdGenerator(),
      name: draft.item.name,
      now: now,
      brand: draft.item.brand ?? selectedProduct?.brand,
      category: draft.item.category ?? selectedProduct?.category,
      barcode: draft.item.barcode ?? selectedProduct?.barcode,
      imageUrl: draft.item.imageUrl ?? selectedProduct?.imageUrl,
      packageWeight: selectedProduct?.packageWeight,
      foodFingerprint: draft.item.resolvedFoodFingerprint,
      nutrition: draft.item.nutrition ?? selectedProduct?.nutrition,
      status: status,
    );
  }

  InventoryItem _inventoryItemForResolvedProduct(
    _ResolvedReviewItem item, {
    required bool canReferenceGlobalItem,
  }) {
    final resolvedProduct = item.resolvedProduct;
    return item.sourceItem.copyWith(
      globalFoodItemId: canReferenceGlobalItem
          ? resolvedProduct.id
          : 'pending-${resolvedProduct.resolvedFoodFingerprint}',
      name: resolvedProduct.name,
      brand: resolvedProduct.brand,
      category: resolvedProduct.category,
      barcode: resolvedProduct.barcode,
      imageUrl: resolvedProduct.imageUrl,
      foodFingerprint: resolvedProduct.resolvedFoodFingerprint,
      nutrition: resolvedProduct.nutrition,
    );
  }
}

String _defaultGlobalFoodItemId() {
  return 'global-food-${_globalFoodItemUuid.v4()}';
}

class _ResolvedReviewItem {
  const _ResolvedReviewItem({
    required this.sourceDraft,
    required this.sourceItem,
    required this.resolvedProduct,
    required this.requiresGlobalPersistence,
  });

  final ReceiptReviewItemDraft sourceDraft;
  final InventoryItem sourceItem;
  final GlobalFoodItem resolvedProduct;
  final bool requiresGlobalPersistence;
}
