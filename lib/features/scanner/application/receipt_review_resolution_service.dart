import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/debug/debug_log.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_receipt_alias_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_item_edit_policy.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_receipt_alias.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/data/receipt_to_review_item_draft_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/domain/'
    'receipt_review_weight_confirmation.dart';

part 'receipt_review_resolution_service.g.dart';

const Uuid _globalFoodItemUuid = Uuid();
const _resolutionLogName = 'ReceiptReviewResolutionService';
const _amountParser = InventoryAmountParser();

/// Defines receipt review persist result.
class ReceiptReviewPersistResult {
  /// The receipt review persist result.
  const ReceiptReviewPersistResult({
    required this.saved,
    required this.inventoryItems,
  });

  /// The saved.
  final bool saved;

  /// The inventory items.
  final List<InventoryItem> inventoryItems;
}

/// Receipt review resolution service.
@Riverpod(
  dependencies: [
    inventoryItemRepository,
  ],
)
ReceiptReviewResolutionService receiptReviewResolutionService(Ref ref) {
  return ReceiptReviewResolutionService(
    mapper: ref.watch(receiptToReviewItemDraftMapperProvider),
    globalFoodItemRepository: ref.watch(globalFoodItemRepositoryProvider),
    globalBarcodeCandidateRepository: ref.watch(
      globalBarcodeCandidateRepositoryProvider,
    ),
    globalFoodReceiptAliasRepository: ref.watch(
      globalFoodReceiptAliasRepositoryProvider,
    ),
    inventoryItemRepository: ref.watch(inventoryItemRepositoryProvider),
    calorieProductCacheRepository: ref.watch(
      calorieProductCacheRepositoryProvider,
    ),
  );
}

/// Defines receipt review resolution service.
class ReceiptReviewResolutionService {
  /// Creates an instance.
  ReceiptReviewResolutionService({
    required ReceiptToReviewItemDraftMapper mapper,
    required GlobalFoodItemRepository globalFoodItemRepository,
    required InventoryItemRepository inventoryItemRepository,
    GlobalBarcodeCandidateRepository? globalBarcodeCandidateRepository,
    GlobalFoodReceiptAliasRepository? globalFoodReceiptAliasRepository,
    CalorieProductCacheRepositoryContract? calorieProductCacheRepository,
    String Function()? globalFoodItemIdGenerator,
  }) : _mapper = mapper,
       _globalFoodItemRepository = globalFoodItemRepository,
       _globalBarcodeCandidateRepository = globalBarcodeCandidateRepository,
       _inventoryItemRepository = inventoryItemRepository,
       _globalFoodReceiptAliasRepository = globalFoodReceiptAliasRepository,
       _calorieProductCacheRepository = calorieProductCacheRepository,
       _globalFoodItemIdGenerator =
           globalFoodItemIdGenerator ?? _defaultGlobalFoodItemId;

  final ReceiptToReviewItemDraftMapper _mapper;
  final GlobalFoodItemRepository _globalFoodItemRepository;
  final GlobalBarcodeCandidateRepository? _globalBarcodeCandidateRepository;
  final InventoryItemRepository _inventoryItemRepository;
  final GlobalFoodReceiptAliasRepository? _globalFoodReceiptAliasRepository;
  final CalorieProductCacheRepositoryContract? _calorieProductCacheRepository;
  final String Function() _globalFoodItemIdGenerator;

  /// Prepare drafts.
  Future<List<ReceiptReviewItemDraft>> prepareDrafts(
    ReceiptAnalysisExtraction extraction,
  ) async {
    Stopwatch? stopwatch;
    assert(() {
      stopwatch = startDebugStopwatch();
      return true;
    }(), 'Start debug receipt review resolution timing.');
    final baseDrafts = _mapper.map(extraction);
    assert(() {
      _debugLogResolutionTiming(
        'mapped ${baseDrafts.length} draft(s) without candidate prefetch',
        stopDebugStopwatch(stopwatch),
      );
      return true;
    }(), 'Log debug receipt review resolution timing.');
    return baseDrafts;
  }

  /// Persist reviewed items.
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
      final selectedEditKind = _selectedCandidateEditKind(draft);
      final shouldReuseSelected =
          selectedCandidate != null &&
          selectedEditKind != GlobalFoodItemEditKind.createNewCandidate;
      final reusedCandidate = shouldReuseSelected ? selectedCandidate : null;
      final shouldPersistSelectedCandidate =
          reusedCandidate != null &&
          (reusedCandidate.requiresPersistence ||
              selectedEditKind == GlobalFoodItemEditKind.patchExisting);

      final resolvedProduct = reusedCandidate != null
          ? (shouldPersistSelectedCandidate
                ? _mergeSelectedProduct(
                    draft: draft,
                    now: now,
                    selectedProduct: reusedCandidate.item,
                  )
                : reusedCandidate.item)
          : _buildProductFromDraft(
              draft: draft,
              now: now,
              status: selectedCandidate == null
                  ? GlobalFoodItemStatus.active
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
      appLog(
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

    final inventorySaved = await _inventoryItemRepository.appendAll(
      inventoryItemsToSave,
    );
    if (inventorySaved) {
      await _recordBarcodeSelections(
        resolvedItems,
        globalSaved: globalSaved,
        now: now,
      );
      await _persistReceiptAliases(
        resolvedItems,
        globalSaved: globalSaved,
        now: now,
      );
      await _persistCalorieProfiles(inventoryItemsToSave, now: now);
    }
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
      brand: draft.item.brand,
      category: draft.item.category,
      storeName: draft.item.storeName.isEmpty
          ? selectedProduct?.storeName
          : draft.item.storeName,
      barcode: draft.item.barcode,
      imageUrl: draft.item.imageUrl,
      packageWeight: persistedWeight.weight,
      servingSize: draft.item.servingSize,
      servingQuantity: draft.item.servingQuantity,
      servingQuantityUnit: draft.item.servingQuantityUnit,
      foodFingerprint: draft.item.resolvedFoodFingerprint,
      nutrition: draft.item.nutrition,
      status: status,
    );
  }

  GlobalFoodItem _mergeSelectedProduct({
    required ReceiptReviewItemDraft draft,
    required DateTime now,
    required GlobalFoodItem selectedProduct,
  }) {
    final persistedWeight = _resolvePersistedWeight(
      item: draft.item,
      fallbackWeight: selectedProduct.packageWeight,
    );

    return selectedProduct.copyWith(
      name: draft.item.name,
      brand: draft.item.brand,
      category: draft.item.category,
      storeName: draft.item.storeName.isEmpty
          ? selectedProduct.storeName
          : draft.item.storeName,
      barcode: draft.item.barcode,
      imageUrl: draft.item.imageUrl,
      packageWeight: persistedWeight.weight,
      servingSize: draft.item.servingSize,
      servingQuantity: draft.item.servingQuantity,
      servingQuantityUnit: draft.item.servingQuantityUnit,
      foodFingerprint: draft.item.resolvedFoodFingerprint,
      nutrition: draft.item.nutrition,
      updatedAt: now,
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
      servingSize: resolvedProduct.servingSize,
      servingQuantity: resolvedProduct.servingQuantity,
      servingQuantityUnit: resolvedProduct.servingQuantityUnit,
      nutrition: resolvedProduct.nutrition,
    );
  }

  GlobalFoodItemEditKind _selectedCandidateEditKind(
    ReceiptReviewItemDraft draft,
  ) {
    final selectedCandidate = draft.selectedCandidate;
    if (selectedCandidate == null) {
      return GlobalFoodItemEditKind.createNewCandidate;
    }

    final selectedProduct = selectedCandidate.item;
    final persistedWeight = _resolvePersistedWeight(
      item: draft.item,
      fallbackWeight: selectedProduct.packageWeight,
    );
    return classifyGlobalFoodItemEdit(
      currentItem: selectedProduct,
      name: draft.item.name,
      brand: draft.item.brand,
      category: draft.item.category,
      storeName: draft.item.storeName.isEmpty
          ? selectedProduct.storeName
          : draft.item.storeName,
      barcode: draft.item.barcode,
      imageUrl: draft.item.imageUrl,
      packageWeight: persistedWeight.weight,
      servingSize: draft.item.servingSize,
      servingQuantity: draft.item.servingQuantity,
      servingQuantityUnit: draft.item.servingQuantityUnit,
      nutrition: draft.item.nutrition,
    );
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

  Future<void> _persistReceiptAliases(
    List<_ResolvedReviewItem> resolvedItems, {
    required bool globalSaved,
    required DateTime now,
  }) async {
    final repository = _globalFoodReceiptAliasRepository;
    if (repository == null) {
      return;
    }

    final aliases = <GlobalFoodReceiptAlias>[
      for (final item in resolvedItems)
        if ((globalSaved || !item.requiresGlobalPersistence) &&
            item.sourceDraft.shouldSaveReceiptAlias)
          if (_buildReceiptAlias(item, now: now) case final alias?) ...[
            alias,
          ],
    ];
    if (aliases.isEmpty) {
      return;
    }

    final saved = await repository.appendAll(aliases);
    if (!saved) {
      appLog(
        'Failed to persist global food receipt aliases.',
        name: _resolutionLogName,
      );
    }
  }

  GlobalFoodReceiptAlias? _buildReceiptAlias(
    _ResolvedReviewItem item, {
    required DateTime now,
  }) {
    final receiptName =
        item.sourceDraft.ocrName ??
        item.sourceItem.ocrName ??
        item.sourceItem.name;
    return GlobalFoodReceiptAlias.tryCreate(
      storeName: item.sourceItem.storeName,
      receiptName: receiptName,
      globalFoodItem: item.resolvedProduct,
      now: now,
    );
  }

  Future<void> _recordBarcodeSelections(
    List<_ResolvedReviewItem> resolvedItems, {
    required bool globalSaved,
    required DateTime now,
  }) async {
    final repository = _globalBarcodeCandidateRepository;
    if (repository == null) {
      return;
    }

    final futures = <Future<void>>[];
    for (final item in resolvedItems) {
      if (!globalSaved && item.requiresGlobalPersistence) {
        continue;
      }
      final barcode = item.resolvedProduct.normalizedBarcode;
      if (barcode == null || barcode.isEmpty) {
        continue;
      }
      futures.add(
        repository.recordSelection(
          barcode: barcode,
          globalFoodItem: item.resolvedProduct,
          selectedAt: now,
        ),
      );
    }
    await Future.wait<void>(futures);
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

    await Future.wait<void>([
      for (final profile in profilesByBarcode.values)
        _saveCalorieOverride(cacheRepository, profile),
    ]);
  }

  Future<void> _saveCalorieOverride(
    CalorieProductCacheRepositoryContract cacheRepository,
    CalorieProductProfile profile,
  ) async {
    final saved = await cacheRepository.saveUserOverride(
      profile: _buildUserOverrideProfile(profile),
      reason: 'receipt_review_selection',
    );
    if (!saved) {
      appLog(
        'Failed to persist calorie override for ${profile.barcode}.',
        name: _resolutionLogName,
      );
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

void _debugLogResolutionTiming(String stage, Duration elapsed) {
  debugLog(
    'Receipt review resolution $stage in ${elapsed.inMilliseconds}ms.',
    name: _resolutionLogName,
  );
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
