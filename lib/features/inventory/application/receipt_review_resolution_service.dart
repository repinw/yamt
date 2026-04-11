import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/domain/'
    'receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/data/receipt_to_review_item_draft_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/'
    'receipt_review_weight_confirmation.dart';

part 'receipt_review_resolution_service.g.dart';

const Uuid _globalFoodItemUuid = Uuid();
const _resolutionLogName = 'ReceiptReviewResolutionService';
const _amountParser = InventoryAmountParser();

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
    calorieProductCacheRepository: ref.watch(
      calorieProductCacheRepositoryProvider,
    ),
  );
}

class ReceiptReviewResolutionService {
  ReceiptReviewResolutionService({
    required ReceiptToReviewItemDraftMapper mapper,
    required GlobalFoodItemMatcher matcher,
    required GlobalFoodItemRepository globalFoodItemRepository,
    required InventoryItemRepository inventoryItemRepository,
    CalorieProductCacheRepositoryContract? calorieProductCacheRepository,
    String Function()? globalFoodItemIdGenerator,
  }) : _mapper = mapper,
       _matcher = matcher,
       _globalFoodItemRepository = globalFoodItemRepository,
       _inventoryItemRepository = inventoryItemRepository,
       _calorieProductCacheRepository = calorieProductCacheRepository,
       _globalFoodItemIdGenerator =
           globalFoodItemIdGenerator ?? _defaultGlobalFoodItemId;

  final ReceiptToReviewItemDraftMapper _mapper;
  final GlobalFoodItemMatcher _matcher;
  final GlobalFoodItemRepository _globalFoodItemRepository;
  final InventoryItemRepository _inventoryItemRepository;
  final CalorieProductCacheRepositoryContract? _calorieProductCacheRepository;
  final String Function() _globalFoodItemIdGenerator;

  Future<List<ReceiptReviewItemDraft>> prepareDrafts(
    ReceiptAnalysisExtraction extraction,
  ) async {
    final baseDrafts = _mapper.map(extraction);
    final resolvedDrafts = <ReceiptReviewItemDraft>[];

    for (final draft in baseDrafts) {
      resolvedDrafts.add(await _prepareDraft(draft));
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
      final shouldReuseSelected = _shouldReuseSelectedCandidate(draft);
      final reusedCandidate = shouldReuseSelected ? selectedCandidate : null;
      final shouldPersistSelectedCandidate =
          reusedCandidate?.requiresPersistence ?? false;

      final resolvedProduct = reusedCandidate != null
          ? reusedCandidate.item
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
    if (inventorySaved) {
      await _persistCalorieProfiles(inventoryItemsToSave, now: now);
    }
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
    final persistedWeight = _resolvePersistedWeight(
      item: draft.item,
      fallbackWeight: selectedProduct?.packageWeight,
    );

    return GlobalFoodItem.create(
      id: _globalFoodItemIdGenerator(),
      name: draft.item.name,
      now: now,
      brand: draft.item.brand ?? selectedProduct?.brand,
      category: draft.item.category ?? selectedProduct?.category,
      barcode: draft.item.barcode ?? selectedProduct?.barcode,
      imageUrl: draft.item.imageUrl ?? selectedProduct?.imageUrl,
      packageWeight: persistedWeight.weight,
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
    final persistedWeight = _resolvePersistedWeight(
      item: item.sourceItem,
      fallbackWeight: resolvedProduct.packageWeight,
    );
    final normalizedItem = item.sourceItem.withDerivedAmount(
      weight: persistedWeight.weight,
      quantity: item.sourceItem.quantity,
      fallbackUnit: persistedWeight.fallbackUnit,
    );

    return normalizedItem.copyWith(
      globalFoodItemId: canReferenceGlobalItem
          ? resolvedProduct.id
          : buildPendingGlobalFoodItemId(
              resolvedProduct.resolvedFoodFingerprint,
            ),
      name: resolvedProduct.name,
      brand: resolvedProduct.brand,
      category: resolvedProduct.category,
      barcode: resolvedProduct.barcode,
      imageUrl: resolvedProduct.imageUrl,
      foodFingerprint: resolvedProduct.resolvedFoodFingerprint,
      nutrition: resolvedProduct.nutrition,
    );
  }

  Future<ReceiptReviewItemDraft> _prepareDraft(
    ReceiptReviewItemDraft draft,
  ) async {
    if (!draft.canBeSavedToInventory) {
      return draft;
    }

    final candidates = await _matcher.findCandidates(draft.item);
    final updatedDraft = draft.copyWith(
      candidates: candidates,
      selectedGlobalFoodItemId: _matcher.defaultSelectionFor(candidates),
      selectionNeedsReview: _matcher.defaultSelectionNeedsReviewFor(candidates),
    );
    return updatedDraft;
  }

  bool _shouldReuseSelectedCandidate(ReceiptReviewItemDraft draft) {
    final selectedCandidate = draft.selectedCandidate;
    if (selectedCandidate == null) {
      return false;
    }
    return selectedCandidate.requiresPersistence ||
        !draft.differsFromSelectedCandidate;
  }

  ({String? weight, InventoryAmountUnit? fallbackUnit})
  _resolvePersistedWeight({
    required InventoryItem item,
    required String? fallbackWeight,
  }) {
    final itemWeight = normalizeReceiptReviewWeight(item.weight);
    final itemParse = _amountParser.tryParse(
      rawWeight: itemWeight,
      quantity: item.quantity,
      fallbackUnit: item.amountUnit,
    );
    if (itemParse != null) {
      return (
        weight: itemWeight,
        fallbackUnit: item.amountUnit ?? itemParse.unit,
      );
    }

    final normalizedFallbackWeight = normalizeReceiptReviewWeight(
      fallbackWeight,
    );
    final fallbackParse = _amountParser.tryParse(
      rawWeight: normalizedFallbackWeight,
      quantity: item.quantity,
      fallbackUnit: item.amountUnit,
    );
    if (fallbackParse != null) {
      return (
        weight: normalizedFallbackWeight,
        fallbackUnit: fallbackParse.unit,
      );
    }

    return (
      weight: itemWeight ?? normalizedFallbackWeight,
      fallbackUnit: item.amountUnit,
    );
  }

  Future<void> _persistCalorieProfiles(
    List<InventoryItem> items, {
    required DateTime now,
  }) async {
    final cacheRepository = _calorieProductCacheRepository;
    if (cacheRepository == null) {
      return;
    }

    final profilesByBarcode = <String, CalorieProductProfile>{};
    for (final item in items) {
      final profile = _buildCalorieProfile(item, now: now);
      if (profile == null) {
        continue;
      }
      profilesByBarcode[profile.barcode] = profile;
    }

    for (final profile in profilesByBarcode.values) {
      final saved = await cacheRepository.saveUserOverride(
        profile: _buildUserOverrideProfile(profile),
        reason: 'receipt_review_selection',
      );
      if (!saved) {
        log(
          'Failed to persist calorie override for ${profile.barcode}.',
          name: _resolutionLogName,
        );
      }
    }
  }

  CalorieProductProfile? _buildCalorieProfile(
    InventoryItem item, {
    required DateTime now,
  }) {
    final barcode = item.normalizedBarcode;
    final nutrition = item.nutrition;
    if (barcode == null || !_hasPersistableNutrition(nutrition)) {
      return null;
    }

    return CalorieProductProfile(
      barcode: barcode,
      name: item.name,
      brand: item.brand,
      per100Kcal: nutrition?.per100Kcal ?? 0,
      per100Protein: nutrition?.per100Protein ?? 0,
      per100Carbs: nutrition?.per100Carbs ?? 0,
      per100Fat: nutrition?.per100Fat ?? 0,
      source: CalorieProductSource.globalCatalog,
      offProductId: _offProductIdForItem(item.globalFoodItemId),
      imageUrl: item.imageUrl,
      createdAt: now,
      updatedAt: now,
    );
  }

  CalorieProductProfile _buildUserOverrideProfile(
    CalorieProductProfile profile,
  ) {
    return CalorieProductProfile(
      barcode: profile.barcode,
      name: profile.name,
      brand: profile.brand,
      per100Kcal: profile.per100Kcal,
      per100Protein: profile.per100Protein,
      per100Carbs: profile.per100Carbs,
      per100Fat: profile.per100Fat,
      source: profile.source,
      offProductId: profile.offProductId,
      imageUrl: null,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  bool _hasPersistableNutrition(GlobalFoodNutrition? nutrition) {
    return nutrition != null && nutrition.hasAnyNutritionValue;
  }

  String? _offProductIdForItem(String? globalFoodItemId) {
    final normalizedGlobalId = globalFoodItemId?.trim();
    if (normalizedGlobalId == null || normalizedGlobalId.isEmpty) {
      return null;
    }
    if (normalizedGlobalId.startsWith('off-')) {
      return normalizedGlobalId;
    }
    return null;
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
