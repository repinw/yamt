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

class ReceiptReviewPersistResult {
  const ReceiptReviewPersistResult({
    required this.saved,
    required this.inventoryItems,
  });

  final bool saved;
  final List<InventoryItem> inventoryItems;
}

@riverpod
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
    final globalItemsToSave = <GlobalFoodItem>[];
    final inventoryItemsToSave = <InventoryItem>[];

    for (final draft in reviewedItems) {
      if (!draft.canBeSavedToInventory) {
        continue;
      }

      final selectedCandidate = draft.selectedCandidate;
      final shouldReuseSelected =
          selectedCandidate != null && !draft.differsFromSelectedCandidate;

      final resolvedProduct = shouldReuseSelected
          ? selectedCandidate.item
          : _buildProductFromDraft(
              draft: draft,
              now: now,
              status: selectedCandidate == null
                  ? GlobalFoodItemStatus.active
                  : GlobalFoodItemStatus.candidate,
            );
      if (!shouldReuseSelected) {
        globalItemsToSave.add(resolvedProduct);
      }

      inventoryItemsToSave.add(
        draft.item.copyWith(
          globalFoodItemId: resolvedProduct.id,
          productSnapshot: resolvedProduct.toProductSnapshot(),
        ),
      );
    }

    final globalSaved =
        globalItemsToSave.isEmpty ||
        await _globalFoodItemRepository.appendAll(globalItemsToSave);
    if (!globalSaved) {
      return const ReceiptReviewPersistResult(
        saved: false,
        inventoryItems: <InventoryItem>[],
      );
    }

    final inventorySaved = await _inventoryItemRepository.appendAll(
      inventoryItemsToSave,
    );
    return ReceiptReviewPersistResult(
      saved: inventorySaved,
      inventoryItems: inventorySaved
          ? inventoryItemsToSave
          : const <InventoryItem>[],
    );
  }

  GlobalFoodItem _buildProductFromDraft({
    required ReceiptReviewItemDraft draft,
    required DateTime now,
    required GlobalFoodItemStatus status,
  }) {
    return GlobalFoodItem.create(
      id: _globalFoodItemIdGenerator(),
      name: draft.item.name,
      now: now,
      brand: draft.item.brand,
      category: draft.item.category,
      barcode: draft.item.barcode,
      imageUrl: draft.item.imageUrl,
      foodFingerprint: draft.item.resolvedFoodFingerprint,
      nutrition: draft.item.nutrition,
      status: status,
    );
  }
}

String _defaultGlobalFoodItemId() {
  return 'global-food-${_globalFoodItemUuid.v4()}';
}
