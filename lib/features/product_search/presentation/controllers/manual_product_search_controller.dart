import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/utils/store_name_normalizer.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_result_quality.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_item_edit_policy.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_nutrition/data/'
    'nutrition_label_ocr_repository.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_eat_now_nutrition.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search/domain/manual_product_weight_input.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_state.dart';

part 'manual_product_search_controller.g.dart';

const _manualProductControllerLogName =
    'InventoryReceiptManualProductController';

/// Defines inventory receipt manual product controller.
@riverpod
class InventoryReceiptManualProductController
    extends _$InventoryReceiptManualProductController {
  static const _searchDebounceDuration = Duration(milliseconds: 300);
  static const _searchResultLimit = 20;

  Timer? _searchDebounce;
  @override
  InventoryReceiptManualProductState build(
    InventoryReceiptManualProductConfig config,
  ) {
    ref.onDispose(() {
      _searchDebounce?.cancel();
    });

    final nutrition =
        config.item.nutrition ?? config.selectedProduct?.nutrition;
    final weightInput = resolveManualProductWeightInput(
      config.selectedProduct?.packageWeight ?? config.item.weight,
      fallbackUnit: config.item.amountUnit,
    );

    return InventoryReceiptManualProductState(
      searchQuery: buildManualProductInitialSearchQuery(config) ?? '',
      nameText: config.selectedProduct?.name ?? config.item.name,
      brandText: config.selectedProduct?.brand ?? config.item.brand ?? '',
      barcode:
          config.item.normalizedBarcode ?? config.selectedProduct?.code ?? '',
      weightAmount: weightInput.amount,
      selectedWeightUnit: weightInput.unit,
      kcalText: formatManualProductDouble(nutrition?.per100Kcal),
      saturatedFatText: formatManualProductDouble(
        nutrition?.per100SaturatedFat,
      ),
      polyunsaturatedFatText: formatManualProductDouble(
        nutrition?.per100PolyunsaturatedFat,
      ),
      proteinText: formatManualProductDouble(nutrition?.per100Protein),
      carbsText: formatManualProductDouble(nutrition?.per100Carbs),
      sugarText: formatManualProductDouble(nutrition?.per100Sugar),
      fiberText: formatManualProductDouble(nutrition?.per100Fiber),
      fatText: formatManualProductDouble(nutrition?.per100Fat),
      saltText: formatManualProductDouble(nutrition?.per100Salt),
      showPolyunsaturatedFatField: nutrition?.per100PolyunsaturatedFat != null,
      showFiberField: nutrition?.per100Fiber != null,
      selectedProduct: config.selectedProduct == null
          ? null
          : InventoryReceiptManualProductSelection.fromSearchResult(
              config.selectedProduct!,
            ),
    );
  }

  /// Update search query.
  void updateSearchQuery(String value) {
    state = state.copyWith(searchQuery: value, error: null);
    _searchDebounce?.cancel();

    final query = normalizeManualProductText(value);
    if (query == null || query.length < 2) {
      _activeSearchRequestId++;
      state = state.copyWith(
        isSearching: false,
        searchResults: const <OffProductSearchResult>[],
      );
      return;
    }

    _searchDebounce = Timer(_searchDebounceDuration, () {
      unawaited(_runProductSearch(query));
    });
  }

  /// Update name text.
  void updateNameText(String value) {
    state = state.copyWith(nameText: value, error: null);
  }

  /// Update brand text.
  void updateBrandText(String value) {
    state = state.copyWith(brandText: value, error: null);
  }

  /// Update weight amount.
  void updateWeightAmount(String value) {
    state = state.copyWith(weightAmount: value, error: null);
  }

  /// Update weight unit.
  void updateWeightUnit(InventoryAmountUnit unit) {
    state = state.copyWith(selectedWeightUnit: unit, error: null);
  }

  /// Update kcal text.
  void updateKcalText(String value) {
    state = state.copyWith(kcalText: value, error: null);
  }

  /// Update saturated fat text.
  void updateSaturatedFatText(String value) {
    state = state.copyWith(saturatedFatText: value, error: null);
  }

  /// Update polyunsaturated fat text.
  void updatePolyunsaturatedFatText(String value) {
    state = state.copyWith(polyunsaturatedFatText: value, error: null);
  }

  /// Update protein text.
  void updateProteinText(String value) {
    state = state.copyWith(proteinText: value, error: null);
  }

  /// Update carbs text.
  void updateCarbsText(String value) {
    state = state.copyWith(carbsText: value, error: null);
  }

  /// Update sugar text.
  void updateSugarText(String value) {
    state = state.copyWith(sugarText: value, error: null);
  }

  /// Update fiber text.
  void updateFiberText(String value) {
    state = state.copyWith(fiberText: value, error: null);
  }

  /// Start adding optional nutrition.
  void startAddingOptionalNutrition() {
    final nutritionType = state.resolvedOptionalNutritionType;
    if (nutritionType == null) {
      return;
    }
    state = state.copyWith(
      isAddingOptionalNutrition: true,
      optionalNutritionValueText: '',
      optionalNutritionType: nutritionType,
      optionalNutritionUnit: InventoryAmountUnit.gram,
      error: null,
    );
  }

  /// Cancel adding optional nutrition.
  void cancelAddingOptionalNutrition() {
    state = state.copyWith(
      isAddingOptionalNutrition: false,
      optionalNutritionValueText: '',
      error: null,
    );
  }

  /// Update optional nutrition value text.
  void updateOptionalNutritionValueText(String value) {
    state = state.copyWith(optionalNutritionValueText: value, error: null);
  }

  /// Update optional nutrition unit.
  void updateOptionalNutritionUnit(InventoryAmountUnit unit) {
    state = state.copyWith(optionalNutritionUnit: unit, error: null);
  }

  /// Update optional nutrition type.
  void updateOptionalNutritionType(InventoryReceiptOptionalNutritionType type) {
    state = state.copyWith(optionalNutritionType: type, error: null);
  }

  /// Apply optional nutrition.
  void applyOptionalNutrition() {
    final nutritionType = state.resolvedOptionalNutritionType;
    final valueText = state.optionalNutritionValueText;
    if (nutritionType == null || parseManualProductDouble(valueText) == null) {
      return;
    }

    switch (nutritionType) {
      case InventoryReceiptOptionalNutritionType.polyunsaturatedFat:
        state = state.copyWith(
          showPolyunsaturatedFatField: true,
          polyunsaturatedFatText: valueText,
          isAddingOptionalNutrition: false,
          optionalNutritionValueText: '',
          error: null,
        );
      case InventoryReceiptOptionalNutritionType.fiber:
        state = state.copyWith(
          showFiberField: true,
          fiberText: valueText,
          isAddingOptionalNutrition: false,
          optionalNutritionValueText: '',
          error: null,
        );
    }
  }

  /// Update fat text.
  void updateFatText(String value) {
    state = state.copyWith(fatText: value, error: null);
  }

  /// Update salt text.
  void updateSaltText(String value) {
    state = state.copyWith(saltText: value, error: null);
  }

  /// Apply search result.
  void applySearchResult(OffProductSearchResult product) {
    _searchDebounce?.cancel();
    _activeSearchRequestId++;
    _applySelectedProductSelection(
      InventoryReceiptManualProductSelection.fromSearchResult(product),
    );
  }

  /// Starts a user-created product draft from the current search query.
  void startManualProductDraft() {
    _searchDebounce?.cancel();
    _activeSearchRequestId++;
    final draftName =
        normalizeManualProductText(state.searchQuery) ??
        normalizeManualProductText(state.nameText) ??
        normalizeManualProductText(_config.item.name) ??
        '';
    state = state.copyWith(
      searchQuery: draftName,
      nameText: draftName,
      isSearching: false,
      searchResults: const <OffProductSearchResult>[],
      isManualDraft: true,
      selectedProduct: null,
      ocrDraft: null,
      error: null,
    );
  }

  /// Apply scanned product.
  void applyScannedProduct(OffProductSearchResult product) {
    _searchDebounce?.cancel();
    _activeSearchRequestId++;
    _applySelectedProductSelection(
      InventoryReceiptManualProductSelection.fromSearchResult(product),
    );
  }

  /// Apply recent item.
  void applyRecentItem(InventoryItem item) {
    _searchDebounce?.cancel();
    _activeSearchRequestId++;
    _applySelectedProductSelection(
      InventoryReceiptManualProductSelection.fromInventoryItem(item),
    );
  }

  /// Apply scanned barcode only.
  void applyScannedBarcodeOnly(String barcode) {
    _searchDebounce?.cancel();
    _activeSearchRequestId++;
    state = state.copyWith(
      barcode: barcode,
      nameText: _config.item.name,
      brandText: _config.item.brand ?? '',
      selectedProduct: null,
      ocrDraft: null,
      kcalText: '',
      saturatedFatText: '',
      polyunsaturatedFatText: '',
      proteinText: '',
      carbsText: '',
      sugarText: '',
      fiberText: '',
      fatText: '',
      saltText: '',
      showPolyunsaturatedFatField: false,
      showFiberField: false,
      isAddingOptionalNutrition: false,
      optionalNutritionValueText: '',
      searchResults: const <OffProductSearchResult>[],
      isSearching: false,
      isManualDraft: true,
      error: null,
    );
  }

  /// Scans the nutrition label.
  Future<InventoryReceiptManualProductNutritionScanOutcome>
  scanNutritionLabel() async {
    final barcode = normalizeBarcode(state.barcode);
    if (barcode.isEmpty || state.isRunningNutritionOcr) {
      if (barcode.isEmpty) {
        state = state.copyWith(
          error: InventoryReceiptManualProductError.requiredProductOrNutrition,
        );
      }
      return InventoryReceiptManualProductNutritionScanOutcome.missingBarcode;
    }

    state = state.copyWith(isRunningNutritionOcr: true, error: null);

    try {
      final result = await ref
          .read(nutritionLabelOcrRepositoryProvider)
          .scanNutritionLabel(barcode: barcode);
      if (!ref.mounted) {
        return InventoryReceiptManualProductNutritionScanOutcome.canceled;
      }

      switch (result.status) {
        case NutritionLabelOcrStatus.succeeded:
          final draft = result.draft;
          if (draft == null) {
            return InventoryReceiptManualProductNutritionScanOutcome.canceled;
          }
          _applyOcrDraft(draft);
          return InventoryReceiptManualProductNutritionScanOutcome.applied;
        case NutritionLabelOcrStatus.canceled:
          return InventoryReceiptManualProductNutritionScanOutcome.canceled;
        case NutritionLabelOcrStatus.failed:
          if (result.errorCode ==
              NutritionLabelOcrErrorCodes.appCheckThrottled) {
            return InventoryReceiptManualProductNutritionScanOutcome
                .appCheckThrottled;
          }
          return InventoryReceiptManualProductNutritionScanOutcome.failed;
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isRunningNutritionOcr: false);
      }
    }
  }

  int _activeSearchRequestId = 0;

  InventoryReceiptManualProductConfig get _config => config;

  /// Builds preview data.
  ({String? imageUrl, String name, String? brand, String? weight})?
  buildPreviewData() {
    final matchedProduct = _currentMatchedProduct();
    return (
      imageUrl: normalizeProductImageUrl(
        matchedProduct?.imageUrl ?? _config.item.imageUrl,
      ),
      name: _resolvedManualName(
        fallbackName: matchedProduct?.name ?? _config.item.name,
      ),
      brand: _resolvedManualBrand(),
      weight: _resolvedWeight,
    );
  }

  String? get _resolvedWeight {
    return _resolvedManualWeightInput.normalizedWeight;
  }

  ManualProductResolvedWeightInput get _resolvedManualWeightInput {
    return resolveManualProductWeightInput(
      state.weightAmount,
      fallbackUnit: state.selectedWeightUnit,
    );
  }

  /// Builds the save payload.
  InventoryReceiptManualProductSavePayload? buildSavePayload({
    InventoryReceiptManualProductAction action =
        InventoryReceiptManualProductAction.addToInventory,
  }) {
    final barcode = normalizeManualProductText(state.barcode);
    final kcal = parseManualProductDouble(state.kcalText);
    final saturatedFat = parseManualProductDouble(state.saturatedFatText);
    final polyunsaturatedFat = parseManualProductDouble(
      state.polyunsaturatedFatText,
    );
    final protein = parseManualProductDouble(state.proteinText);
    final carbs = parseManualProductDouble(state.carbsText);
    final sugar = parseManualProductDouble(state.sugarText);
    final fiber = parseManualProductDouble(state.fiberText);
    final fat = parseManualProductDouble(state.fatText);
    final salt = parseManualProductDouble(state.saltText);
    final hasNutrition =
        kcal != null ||
        saturatedFat != null ||
        polyunsaturatedFat != null ||
        protein != null ||
        carbs != null ||
        sugar != null ||
        fiber != null ||
        fat != null ||
        salt != null;

    if (barcode == null && !hasNutrition) {
      state = state.copyWith(
        error: InventoryReceiptManualProductError.requiredProductOrNutrition,
      );
      return null;
    }
    if (action == InventoryReceiptManualProductAction.addToInventory &&
        !state.hasPackageWeightInput) {
      state = state.copyWith(
        error: InventoryReceiptManualProductError.requiredPackageWeight,
      );
      return null;
    }

    final matchedProduct = _currentMatchedProduct();
    final selectedProduct = state.selectedProduct;
    final resolvedWeightInput = _resolvedManualWeightInput;
    final globalPackageWeight = _resolvedGlobalPackageWeight(
      action: action,
      matchedProduct: matchedProduct,
    );
    final inventoryWeight = resolvedWeightInput.normalizedWeight;
    final updatedItem = _config.item
        .copyWith(
          name: _resolvedManualName(
            fallbackName: matchedProduct?.name ?? _config.item.name,
          ),
          brand: _resolvedManualBrand(),
          barcode: barcode,
          imageUrl: matchedProduct?.imageUrl ?? _config.item.imageUrl,
          weight: inventoryWeight,
          servingSize:
              matchedProduct?.servingSize ??
              state.ocrDraft?.servingSizeLabel ??
              _config.item.servingSize,
          servingQuantity:
              matchedProduct?.servingQuantity ?? _config.item.servingQuantity,
          servingQuantityUnit:
              matchedProduct?.servingQuantityUnit ??
              _config.item.servingQuantityUnit,
          nutrition: hasNutrition
              ? GlobalFoodNutrition(
                  qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
                  per100Kcal: kcal,
                  per100SaturatedFat: saturatedFat,
                  per100PolyunsaturatedFat: polyunsaturatedFat,
                  per100Protein: protein,
                  per100Carbs: carbs,
                  per100Sugar: sugar,
                  per100Fiber: fiber,
                  per100Fat: fat,
                  per100Salt: salt,
                )
              : selectedProduct?.nutrition ?? _config.item.nutrition,
        )
        .withResolvedAmount(
          weight: inventoryWeight,
          parsedAmount: resolvedWeightInput.parsedAmount,
          quantity: _config.item.quantity,
        );
    final selectedEditKind = _selectedProductEditKindForItem(
      updatedItem,
      globalPackageWeight: globalPackageWeight,
    );
    final effectiveSelectedProduct =
        selectedProduct == null ||
            selectedEditKind == GlobalFoodItemEditKind.createNewCandidate
        ? null
        : selectedProduct;
    return (
      item: updatedItem,
      selectedProduct: effectiveSelectedProduct?.externalProduct,
      selectedGlobalFoodItemId: effectiveSelectedProduct?.globalFoodItemId,
      requiresGlobalPersistence: _requiresGlobalPersistenceForSelection(
        selection: effectiveSelectedProduct,
        editKind: selectedEditKind,
      ),
      globalPackageWeight: globalPackageWeight,
    );
  }

  /// Builds a direct search-result payload without mutating page state.
  InventoryReceiptManualProductSavePayload? buildDirectSearchResultPayload({
    required OffProductSearchResult product,
    required InventoryReceiptManualProductAction action,
  }) {
    final selection = InventoryReceiptManualProductSelection.fromSearchResult(
      product,
    );
    final weightInput = resolveManualProductWeightInput(
      selection.packageWeight,
      fallbackUnit: _config.item.amountUnit,
    );
    final inventoryWeight = weightInput.normalizedWeight;
    final nutrition = selection.nutrition ?? _config.item.nutrition;
    if (action == InventoryReceiptManualProductAction.eatNow) {
      if (!hasRequiredEatNowNutrition(nutrition)) {
        return null;
      }
    }

    final barcode = normalizeManualProductText(selection.barcode);
    if (barcode == null) {
      return null;
    }

    final updatedItem = _config.item
        .copyWith(
          name: selection.name,
          brand: selection.brand,
          barcode: barcode,
          imageUrl: selection.imageUrl ?? _config.item.imageUrl,
          weight: inventoryWeight,
          servingSize: selection.servingSize ?? _config.item.servingSize,
          servingQuantity:
              selection.servingQuantity ?? _config.item.servingQuantity,
          servingQuantityUnit:
              selection.servingQuantityUnit ?? _config.item.servingQuantityUnit,
          nutrition: nutrition,
        )
        .withResolvedAmount(
          weight: inventoryWeight,
          parsedAmount: weightInput.parsedAmount,
          quantity: _config.item.quantity,
        );
    final globalPackageWeight = _resolvedGlobalPackageWeightForSelection(
      action: action,
      selection: selection,
    );
    final selectedEditKind = _selectedProductEditKind(
      selection: selection,
      item: updatedItem,
      globalPackageWeight: globalPackageWeight,
    );
    final effectiveSelectedProduct =
        selectedEditKind == GlobalFoodItemEditKind.createNewCandidate
        ? null
        : selection;
    return (
      item: updatedItem,
      selectedProduct: effectiveSelectedProduct?.externalProduct,
      selectedGlobalFoodItemId: effectiveSelectedProduct?.globalFoodItemId,
      requiresGlobalPersistence: _requiresGlobalPersistenceForSelection(
        selection: effectiveSelectedProduct,
        editKind: selectedEditKind,
      ),
      globalPackageWeight: globalPackageWeight,
    );
  }

  Future<void> _runProductSearch(String query) async {
    final requestId = ++_activeSearchRequestId;
    state = state.copyWith(isSearching: true);

    try {
      final results = await ref
          .read(offProductSearchRepositoryProvider)
          .search(
            query: query,
            store: _resolvedSearchStore(),
            weight: _resolvedSearchWeight(),
            limit: _searchResultLimit,
          );
      final visibleResults = collapseDominatedOffProductSearchResults(results);

      if (!ref.mounted || requestId != _activeSearchRequestId) {
        return;
      }

      state = state.copyWith(
        isSearching: false,
        searchResults: visibleResults,
      );
    } on Object catch (error, stackTrace) {
      log(
        'Manual product search failed for query "$query".',
        name: _manualProductControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      if (!ref.mounted || requestId != _activeSearchRequestId) {
        return;
      }

      state = state.copyWith(
        isSearching: false,
        searchResults: const <OffProductSearchResult>[],
      );
    }
  }

  void _applySelectedProductSelection(
    InventoryReceiptManualProductSelection product,
  ) {
    final nutrition = product.nutrition;
    final weightInput = resolveManualProductWeightInput(
      product.packageWeight,
      fallbackUnit: state.selectedWeightUnit,
    );
    state = state.copyWith(
      searchQuery: product.name,
      nameText: product.name,
      brandText: product.brand ?? '',
      barcode: product.barcode,
      weightAmount: weightInput.amount,
      selectedWeightUnit: weightInput.unit,
      kcalText: formatManualProductDouble(nutrition?.per100Kcal),
      saturatedFatText: formatManualProductDouble(
        nutrition?.per100SaturatedFat,
      ),
      polyunsaturatedFatText: formatManualProductDouble(
        nutrition?.per100PolyunsaturatedFat,
      ),
      proteinText: formatManualProductDouble(nutrition?.per100Protein),
      carbsText: formatManualProductDouble(nutrition?.per100Carbs),
      sugarText: formatManualProductDouble(nutrition?.per100Sugar),
      fiberText: formatManualProductDouble(nutrition?.per100Fiber),
      fatText: formatManualProductDouble(nutrition?.per100Fat),
      saltText: formatManualProductDouble(nutrition?.per100Salt),
      showPolyunsaturatedFatField: nutrition?.per100PolyunsaturatedFat != null,
      showFiberField: nutrition?.per100Fiber != null,
      isAddingOptionalNutrition: false,
      optionalNutritionValueText: '',
      isManualDraft: false,
      selectedProduct: product,
      ocrDraft: null,
      searchResults: const <OffProductSearchResult>[],
      isSearching: false,
      error: null,
    );
  }

  void _applyOcrDraft(NutritionLabelOcrDraft draft) {
    final ocrWeightInput = resolveManualProductOcrWeightInput(
      draft.quantityLabel,
      fallbackUnit: state.selectedWeightUnit,
    );
    state = state.copyWith(
      ocrDraft: draft,
      weightAmount: ocrWeightInput?.amount ?? state.weightAmount,
      selectedWeightUnit: ocrWeightInput?.unit ?? state.selectedWeightUnit,
      kcalText: formatManualProductDouble(draft.per100Kcal),
      saturatedFatText: formatManualProductDouble(draft.per100SaturatedFat),
      polyunsaturatedFatText: formatManualProductDouble(
        draft.per100PolyunsaturatedFat,
      ),
      proteinText: formatManualProductDouble(draft.per100Protein),
      carbsText: formatManualProductDouble(draft.per100Carbs),
      sugarText: formatManualProductDouble(draft.per100Sugar),
      fiberText: formatManualProductDouble(draft.per100Fiber),
      fatText: formatManualProductDouble(draft.per100Fat),
      saltText: formatManualProductDouble(draft.per100Salt),
      showPolyunsaturatedFatField:
          state.showPolyunsaturatedFatField ||
          draft.per100PolyunsaturatedFat != null,
      showFiberField: state.showFiberField || draft.per100Fiber != null,
      isAddingOptionalNutrition: false,
      optionalNutritionValueText: '',
      error: null,
    );
  }

  GlobalFoodItemEditKind _selectedProductEditKindForItem(
    InventoryItem item, {
    required String? globalPackageWeight,
  }) {
    return _selectedProductEditKind(
      selection: state.selectedProduct,
      item: item,
      globalPackageWeight: globalPackageWeight,
    );
  }

  GlobalFoodItemEditKind _selectedProductEditKind({
    required InventoryReceiptManualProductSelection? selection,
    required InventoryItem item,
    required String? globalPackageWeight,
  }) {
    final selectedProduct = state.selectedProduct;
    final resolvedSelection = selection ?? selectedProduct;
    if (resolvedSelection == null) {
      return GlobalFoodItemEditKind.createNewCandidate;
    }

    return classifyGlobalFoodItemEdit(
      currentItem: _globalFoodItemFromSelection(resolvedSelection),
      name: item.name,
      brand: item.brand,
      barcode: item.barcode,
      imageUrl: normalizeProductImageUrl(item.imageUrl),
      packageWeight: globalPackageWeight,
      servingSize: item.servingSize,
      servingQuantity: item.servingQuantity,
      servingQuantityUnit: item.servingQuantityUnit,
      nutrition: item.nutrition,
    );
  }

  String? _resolvedGlobalPackageWeight({
    required InventoryReceiptManualProductAction action,
    required InventoryReceiptManualProductSelection? matchedProduct,
  }) {
    return _resolvedGlobalPackageWeightForSelection(
      action: action,
      selection: matchedProduct,
    );
  }

  String? _resolvedGlobalPackageWeightForSelection({
    required InventoryReceiptManualProductAction action,
    required InventoryReceiptManualProductSelection? selection,
  }) {
    if (action == InventoryReceiptManualProductAction.addToInventory) {
      return _resolvedWeight;
    }
    return selection?.packageWeight ?? _config.item.weight;
  }

  String _resolvedManualName({required String fallbackName}) {
    return normalizeManualProductText(state.nameText) ?? fallbackName;
  }

  String? _resolvedManualBrand() {
    return normalizeManualProductText(state.brandText);
  }

  InventoryReceiptManualProductSelection? _currentMatchedProduct() {
    final selectedProduct = state.selectedProduct;
    if (selectedProduct == null) {
      return null;
    }

    final normalizedBarcode = normalizeBarcode(state.barcode);
    if (normalizedBarcode.isEmpty) {
      return selectedProduct;
    }
    if (normalizedBarcode != normalizeBarcode(selectedProduct.barcode)) {
      return null;
    }
    return selectedProduct;
  }

  bool _requiresGlobalPersistenceForSelection({
    required InventoryReceiptManualProductSelection? selection,
    required GlobalFoodItemEditKind editKind,
  }) {
    if (selection == null) {
      return true;
    }
    if (selection.externalProduct != null) {
      return true;
    }
    return editKind == GlobalFoodItemEditKind.patchExisting;
  }

  GlobalFoodItem _globalFoodItemFromSelection(
    InventoryReceiptManualProductSelection selection,
  ) {
    return GlobalFoodItem.create(
      id: selection.globalFoodItemId ?? '',
      name: selection.name,
      now: DateTime.fromMillisecondsSinceEpoch(0),
      brand: selection.brand,
      barcode: selection.barcode,
      imageUrl: normalizeProductImageUrl(selection.imageUrl),
      packageWeight: selection.packageWeight,
      servingSize: selection.servingSize,
      servingQuantity: selection.servingQuantity,
      servingQuantityUnit: selection.servingQuantityUnit,
      nutrition: selection.nutrition,
    );
  }

  String? _resolvedSearchStore() {
    if (!_config.includeStoreInSearch) {
      return null;
    }

    final normalizedStoreName = normalizeStoreName(_config.item.storeName);
    final normalizedBrandStore = _normalizeSupportedExternalStore(
      _config.item.brand,
    );
    final supportedStore = _normalizeSupportedExternalStore(
      normalizedStoreName,
    );
    return supportedStore ?? normalizedBrandStore;
  }

  String? _resolvedSearchWeight() {
    if (!_config.includeWeightInSearch) {
      return null;
    }
    return normalizeManualProductText(_config.item.weight ?? '');
  }

  String? _normalizeSupportedExternalStore(String? rawValue) {
    final normalized = normalizeStoreName(rawValue);
    return switch (normalized) {
      'Aldi' => 'Aldi',
      'Netto' => 'Netto',
      _ => null,
    };
  }
}
