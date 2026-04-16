import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/utils/store_name_normalizer.dart';
import 'package:yamt/features/calories/data/'
    'calorie_nutrition_ocr_repository.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_item_edit_policy.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'inventory_receipt_manual_product_form_utils.dart';

part 'inventory_receipt_manual_product_controller.g.dart';

const _manualProductControllerLogName =
    'InventoryReceiptManualProductController';
const _keepValue = Object();

/// Defines inventory receipt manual product config.
class InventoryReceiptManualProductConfig {
  /// The inventory receipt manual product config.
  const InventoryReceiptManualProductConfig({
    required this.item,
    this.selectedProduct,
    this.includeStoreInSearch = true,
    this.includeWeightInSearch = true,
  });

  /// The item.
  final InventoryItem item;

  /// The selected product.
  final OffProductSearchResult? selectedProduct;

  /// The include store in search.
  final bool includeStoreInSearch;

  /// The include weight in search.
  final bool includeWeightInSearch;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InventoryReceiptManualProductConfig &&
            other.item == item &&
            _selectedProductEquals(other.selectedProduct, selectedProduct) &&
            other.includeStoreInSearch == includeStoreInSearch &&
            other.includeWeightInSearch == includeWeightInSearch;
  }

  @override
  int get hashCode {
    return Object.hash(
      item,
      _selectedProductHash(selectedProduct),
      includeStoreInSearch,
      includeWeightInSearch,
    );
  }

  static bool _selectedProductEquals(
    OffProductSearchResult? left,
    OffProductSearchResult? right,
  ) {
    return left?.code == right?.code &&
        left?.name == right?.name &&
        left?.score == right?.score &&
        left?.brand == right?.brand &&
        left?.imageUrl == right?.imageUrl &&
        left?.packageWeight == right?.packageWeight &&
        left?.servingSize == right?.servingSize &&
        left?.servingQuantity == right?.servingQuantity &&
        left?.servingQuantityUnit == right?.servingQuantityUnit &&
        left?.nutrition == right?.nutrition;
  }

  static int _selectedProductHash(OffProductSearchResult? product) {
    return Object.hash(
      product?.code,
      product?.name,
      product?.score,
      product?.brand,
      product?.imageUrl,
      product?.packageWeight,
      product?.servingSize,
      product?.servingQuantity,
      product?.servingQuantityUnit,
      product?.nutrition,
    );
  }
}

/// Defines inventory receipt manual product error.
enum InventoryReceiptManualProductError {
  /// Documented member.
  requiredProductOrNutrition,

  /// Documented member.
  requiredPackageWeight,
}

/// Defines inventory receipt manual product nutrition scan outcome.
enum InventoryReceiptManualProductNutritionScanOutcome {
  /// Documented member.
  applied,

  /// Documented member.
  canceled,

  /// Documented member.
  failed,

  /// Documented member.
  missingBarcode,
}

/// Defines inventory receipt manual product selection source.
enum InventoryReceiptManualProductSelectionSource {
  /// Documented member.
  externalSearch,

  /// Documented member.
  recentInventory,
}

/// Defines inventory receipt optional nutrition type.
enum InventoryReceiptOptionalNutritionType {
  /// Polyunsaturated fat.
  polyunsaturatedFat,

  /// Fiber.
  fiber,
}

/// Defines inventory receipt manual product selection.
class InventoryReceiptManualProductSelection {
  /// The inventory receipt manual product selection.
  const InventoryReceiptManualProductSelection({
    required this.source,
    required this.name,
    required this.barcode,
    this.brand,
    this.imageUrl,
    this.packageWeight,
    this.servingSize,
    this.servingQuantity,
    this.servingQuantityUnit,
    this.nutrition,
    this.externalProduct,
    this.globalFoodItemId,
  });

  /// Creates a [InventoryReceiptManualProductSelection] for from search result.
  factory InventoryReceiptManualProductSelection.fromSearchResult(
    OffProductSearchResult result,
  ) {
    return InventoryReceiptManualProductSelection(
      source: InventoryReceiptManualProductSelectionSource.externalSearch,
      name: result.name,
      barcode: result.code,
      brand: result.brand,
      imageUrl: result.imageUrl,
      packageWeight: result.packageWeight,
      servingSize: result.servingSize,
      servingQuantity: result.servingQuantity,
      servingQuantityUnit: result.servingQuantityUnit,
      nutrition: result.nutrition,
      externalProduct: result,
    );
  }

  /// Creates a [InventoryReceiptManualProductSelection] for from inventory item.
  factory InventoryReceiptManualProductSelection.fromInventoryItem(
    InventoryItem item,
  ) {
    return InventoryReceiptManualProductSelection(
      source: InventoryReceiptManualProductSelectionSource.recentInventory,
      name: item.name,
      barcode: item.normalizedBarcode ?? '',
      brand: item.brand,
      imageUrl: item.imageUrl,
      packageWeight: item.weight,
      servingSize: item.servingSize,
      servingQuantity: item.servingQuantity,
      servingQuantityUnit: item.servingQuantityUnit,
      nutrition: item.nutrition,
      globalFoodItemId: _normalizeReusableGlobalFoodItemId(
        item.globalFoodItemId,
      ),
    );
  }

  /// The source.
  final InventoryReceiptManualProductSelectionSource source;

  /// The name.
  final String name;

  /// The barcode.
  final String barcode;

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

  /// The external product.
  final OffProductSearchResult? externalProduct;

  /// The global food item id.
  final String? globalFoodItemId;
}

/// Build manual product initial search query.
String? buildManualProductInitialSearchQuery(
  InventoryReceiptManualProductConfig config,
) {
  final selectedProductName = normalizeManualProductText(
    config.selectedProduct?.name ?? '',
  );
  if (selectedProductName != null) {
    return selectedProductName;
  }

  final parts = <String>[];
  final normalizedParts = <String>{};

  void addPart(String? value, {bool canBeBarcode = true}) {
    final normalized = normalizeManualProductText(value ?? '');
    if (normalized == null) {
      return;
    }
    if (!canBeBarcode && _looksLikeBarcodeText(normalized)) {
      return;
    }

    final key = normalized.toLowerCase();
    if (!normalizedParts.add(key)) {
      return;
    }
    parts.add(normalized);
  }

  addPart(config.item.ocrName ?? config.item.name, canBeBarcode: false);
  addPart(config.item.brand);
  addPart(_initialSearchStoreName(config.item));

  if (parts.isEmpty) {
    return null;
  }
  return parts.join(' ');
}

/// Defines inventory receipt manual product state.
class InventoryReceiptManualProductState {
  /// The inventory receipt manual product state.
  const InventoryReceiptManualProductState({
    this.searchQuery = '',
    this.nameText = '',
    this.brandText = '',
    this.barcode = '',
    this.weightAmount = '',
    this.selectedWeightUnit = InventoryAmountUnit.gram,
    this.kcalText = '',
    this.saturatedFatText = '',
    this.polyunsaturatedFatText = '',
    this.proteinText = '',
    this.carbsText = '',
    this.sugarText = '',
    this.fiberText = '',
    this.fatText = '',
    this.saltText = '',
    this.showPolyunsaturatedFatField = false,
    this.showFiberField = false,
    this.isAddingOptionalNutrition = false,
    this.optionalNutritionValueText = '',
    this.optionalNutritionUnit = InventoryAmountUnit.gram,
    this.optionalNutritionType =
        InventoryReceiptOptionalNutritionType.polyunsaturatedFat,
    this.isSearching = false,
    this.searchResults = const <OffProductSearchResult>[],
    this.selectedProduct,
    this.ocrDraft,
    this.isRunningNutritionOcr = false,
    this.error,
  });

  /// The search query.
  final String searchQuery;

  /// The name text.
  final String nameText;

  /// The brand text.
  final String brandText;

  /// The barcode.
  final String barcode;

  /// The weight amount.
  final String weightAmount;

  /// The selected weight unit.
  final InventoryAmountUnit selectedWeightUnit;

  /// The kcal text.
  final String kcalText;

  /// The saturated fat text.
  final String saturatedFatText;

  /// The polyunsaturated fat text.
  final String polyunsaturatedFatText;

  /// The protein text.
  final String proteinText;

  /// The carbs text.
  final String carbsText;

  /// The sugar text.
  final String sugarText;

  /// The fiber text.
  final String fiberText;

  /// The fat text.
  final String fatText;

  /// The salt text.
  final String saltText;

  /// The show polyunsaturated fat field.
  final bool showPolyunsaturatedFatField;

  /// The show fiber field.
  final bool showFiberField;

  /// Whether adding optional nutrition.
  final bool isAddingOptionalNutrition;

  /// The optional nutrition value text.
  final String optionalNutritionValueText;

  /// The optional nutrition unit.
  final InventoryAmountUnit optionalNutritionUnit;

  /// The optional nutrition type.
  final InventoryReceiptOptionalNutritionType optionalNutritionType;

  /// Whether searching.
  final bool isSearching;

  /// The search results.
  final List<OffProductSearchResult> searchResults;

  /// The selected product.
  final InventoryReceiptManualProductSelection? selectedProduct;

  /// The ocr draft.
  final CalorieNutritionOcrDraft? ocrDraft;

  /// Whether running nutrition ocr.
  final bool isRunningNutritionOcr;

  /// The error.
  final InventoryReceiptManualProductError? error;

  /// Whether barcode.
  bool get hasBarcode => normalizeBarcode(barcode).isNotEmpty;

  /// Whether package weight input.
  bool get hasPackageWeightInput {
    return parseManualProductDouble(weightAmount) != null;
  }

  /// Whether nutrition input.
  bool get hasNutritionInput {
    return normalizeManualProductText(kcalText) != null ||
        normalizeManualProductText(saturatedFatText) != null ||
        normalizeManualProductText(polyunsaturatedFatText) != null ||
        normalizeManualProductText(proteinText) != null ||
        normalizeManualProductText(carbsText) != null ||
        normalizeManualProductText(sugarText) != null ||
        normalizeManualProductText(fiberText) != null ||
        normalizeManualProductText(fatText) != null ||
        normalizeManualProductText(saltText) != null;
  }

  /// Whether complete nutrition input.
  bool get hasCompleteNutritionInput {
    return parseManualProductDouble(kcalText) != null &&
        parseManualProductDouble(saturatedFatText) != null &&
        parseManualProductDouble(proteinText) != null &&
        parseManualProductDouble(carbsText) != null &&
        parseManualProductDouble(sugarText) != null &&
        parseManualProductDouble(fatText) != null &&
        parseManualProductDouble(saltText) != null;
  }

  /// The show details.
  bool get showDetails {
    return selectedProduct != null ||
        ocrDraft != null ||
        hasBarcode ||
        hasNutritionInput ||
        error != null;
  }

  /// Whether save.
  bool get canSave {
    return hasPackageWeightInput && (hasBarcode || hasNutritionInput);
  }

  /// Whether scan nutrition label.
  bool get canScanNutritionLabel {
    return !isRunningNutritionOcr && hasBarcode;
  }

  /// The available optional nutrition types.
  List<InventoryReceiptOptionalNutritionType>
  get availableOptionalNutritionTypes {
    final types = <InventoryReceiptOptionalNutritionType>[];
    if (!showPolyunsaturatedFatField) {
      types.add(InventoryReceiptOptionalNutritionType.polyunsaturatedFat);
    }
    if (!showFiberField) {
      types.add(InventoryReceiptOptionalNutritionType.fiber);
    }
    return types;
  }

  /// Whether add optional nutrition.
  bool get canAddOptionalNutrition {
    return availableOptionalNutritionTypes.isNotEmpty;
  }

  /// The resolved optional nutrition type.
  InventoryReceiptOptionalNutritionType? get resolvedOptionalNutritionType {
    final availableTypes = availableOptionalNutritionTypes;
    if (availableTypes.isEmpty) {
      return null;
    }
    if (availableTypes.contains(optionalNutritionType)) {
      return optionalNutritionType;
    }
    return availableTypes.first;
  }

  /// Copy with.
  InventoryReceiptManualProductState copyWith({
    String? searchQuery,
    String? nameText,
    String? brandText,
    String? barcode,
    String? weightAmount,
    InventoryAmountUnit? selectedWeightUnit,
    String? kcalText,
    String? saturatedFatText,
    String? polyunsaturatedFatText,
    String? proteinText,
    String? carbsText,
    String? sugarText,
    String? fiberText,
    String? fatText,
    String? saltText,
    bool? showPolyunsaturatedFatField,
    bool? showFiberField,
    bool? isAddingOptionalNutrition,
    String? optionalNutritionValueText,
    InventoryAmountUnit? optionalNutritionUnit,
    InventoryReceiptOptionalNutritionType? optionalNutritionType,
    bool? isSearching,
    List<OffProductSearchResult>? searchResults,
    Object? selectedProduct = _keepValue,
    Object? ocrDraft = _keepValue,
    bool? isRunningNutritionOcr,
    Object? error = _keepValue,
  }) {
    return InventoryReceiptManualProductState(
      searchQuery: searchQuery ?? this.searchQuery,
      nameText: nameText ?? this.nameText,
      brandText: brandText ?? this.brandText,
      barcode: barcode ?? this.barcode,
      weightAmount: weightAmount ?? this.weightAmount,
      selectedWeightUnit: selectedWeightUnit ?? this.selectedWeightUnit,
      kcalText: kcalText ?? this.kcalText,
      saturatedFatText: saturatedFatText ?? this.saturatedFatText,
      polyunsaturatedFatText:
          polyunsaturatedFatText ?? this.polyunsaturatedFatText,
      proteinText: proteinText ?? this.proteinText,
      carbsText: carbsText ?? this.carbsText,
      sugarText: sugarText ?? this.sugarText,
      fiberText: fiberText ?? this.fiberText,
      fatText: fatText ?? this.fatText,
      saltText: saltText ?? this.saltText,
      showPolyunsaturatedFatField:
          showPolyunsaturatedFatField ?? this.showPolyunsaturatedFatField,
      showFiberField: showFiberField ?? this.showFiberField,
      isAddingOptionalNutrition:
          isAddingOptionalNutrition ?? this.isAddingOptionalNutrition,
      optionalNutritionValueText:
          optionalNutritionValueText ?? this.optionalNutritionValueText,
      optionalNutritionUnit:
          optionalNutritionUnit ?? this.optionalNutritionUnit,
      optionalNutritionType:
          optionalNutritionType ?? this.optionalNutritionType,
      isSearching: isSearching ?? this.isSearching,
      searchResults: searchResults ?? this.searchResults,
      selectedProduct: selectedProduct == _keepValue
          ? this.selectedProduct
          : selectedProduct as InventoryReceiptManualProductSelection?,
      ocrDraft: ocrDraft == _keepValue
          ? this.ocrDraft
          : ocrDraft as CalorieNutritionOcrDraft?,
      isRunningNutritionOcr:
          isRunningNutritionOcr ?? this.isRunningNutritionOcr,
      error: error == _keepValue
          ? this.error
          : error as InventoryReceiptManualProductError?,
    );
  }
}

/// Defines inventory receipt manual product controller.
@riverpod
class InventoryReceiptManualProductController
    extends _$InventoryReceiptManualProductController {
  static const _searchDebounceDuration = Duration(milliseconds: 300);
  static const _searchResultLimit = 20;

  Timer? _searchDebounce;
  int _activeSearchRequestId = 0;

  InventoryReceiptManualProductConfig get _config => config;

  @override
  InventoryReceiptManualProductState build(
    InventoryReceiptManualProductConfig config,
  ) {
    ref.onDispose(() {
      _searchDebounce?.cancel();
    });

    final nutrition =
        config.item.nutrition ?? config.selectedProduct?.nutrition;
    final weightInput = _resolveWeightInput(
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
    final amountText = normalizeManualProductText(state.weightAmount);
    if (amountText == null) {
      return null;
    }
    return '$amountText ${_weightUnitCode(state.selectedWeightUnit)}';
  }

  /// Update search query.
  void updateSearchQuery(String value) {
    state = state.copyWith(searchQuery: value, error: null);
    _searchDebounce?.cancel();

    final query = normalizeManualProductText(value);
    if (query == null || query.length < 2) {
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

  /// Update barcode.
  void updateBarcode(String value) {
    state = state.copyWith(barcode: value, error: null);
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
    _applySelectedProductSelection(
      InventoryReceiptManualProductSelection.fromSearchResult(product),
    );
  }

  /// Apply scanned product.
  void applyScannedProduct(OffProductSearchResult product) {
    _applySelectedProductSelection(
      InventoryReceiptManualProductSelection.fromSearchResult(product),
    );
  }

  /// Apply recent item.
  void applyRecentItem(InventoryItem item) {
    _searchDebounce?.cancel();
    _applySelectedProductSelection(
      InventoryReceiptManualProductSelection.fromInventoryItem(item),
    );
  }

  /// Apply scanned barcode only.
  void applyScannedBarcodeOnly(String barcode) {
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
          .read(calorieNutritionOcrRepositoryProvider)
          .scanNutritionLabel(barcode: barcode);
      if (!ref.mounted) {
        return InventoryReceiptManualProductNutritionScanOutcome.canceled;
      }

      switch (result.status) {
        case CalorieNutritionOcrStatus.succeeded:
          final draft =
              result.draft ?? _buildOcrDraftFromProfile(result.profile);
          if (draft == null) {
            return InventoryReceiptManualProductNutritionScanOutcome.canceled;
          }
          _applyOcrDraft(draft);
          return InventoryReceiptManualProductNutritionScanOutcome.applied;
        case CalorieNutritionOcrStatus.canceled:
          return InventoryReceiptManualProductNutritionScanOutcome.canceled;
        case CalorieNutritionOcrStatus.failed:
          return InventoryReceiptManualProductNutritionScanOutcome.failed;
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isRunningNutritionOcr: false);
      }
    }
  }

  /// Builds the save payload.
  ({
    InventoryItem item,
    OffProductSearchResult? selectedProduct,
    String? selectedGlobalFoodItemId,
    bool requiresGlobalPersistence,
  })?
  buildSavePayload() {
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
    if (!state.hasPackageWeightInput) {
      state = state.copyWith(
        error: InventoryReceiptManualProductError.requiredPackageWeight,
      );
      return null;
    }

    final matchedProduct = _currentMatchedProduct();
    final selectedProduct = state.selectedProduct;
    final updatedItem = _config.item
        .copyWith(
          name: _resolvedManualName(
            fallbackName: matchedProduct?.name ?? _config.item.name,
          ),
          brand: _resolvedManualBrand(),
          barcode: barcode,
          imageUrl: matchedProduct?.imageUrl ?? _config.item.imageUrl,
          weight: _resolvedWeight,
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
                  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
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
        .withDerivedAmount(
          weight: _resolvedWeight,
          quantity: _config.item.quantity,
          fallbackUnit: state.selectedWeightUnit,
        );
    final selectedEditKind = _selectedProductEditKindForItem(updatedItem);
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

      if (!ref.mounted || requestId != _activeSearchRequestId) {
        return;
      }

      state = state.copyWith(isSearching: false, searchResults: results);
    } catch (error, stackTrace) {
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
    final weightInput = _resolveWeightInput(
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
      selectedProduct: product,
      ocrDraft: null,
      searchResults: const <OffProductSearchResult>[],
      error: null,
    );
  }

  void _applyOcrDraft(CalorieNutritionOcrDraft draft) {
    final ocrWeightInput = _resolveOcrWeightInput(draft.quantityLabel);
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

  CalorieNutritionOcrDraft? _buildOcrDraftFromProfile(
    CalorieProductProfile? profile,
  ) {
    if (profile == null) {
      return null;
    }
    return CalorieNutritionOcrDraft(
      barcode: profile.barcode,
      name: profile.name,
      brand: profile.brand,
      per100Kcal: profile.per100Kcal,
      per100Protein: profile.per100Protein,
      per100Carbs: profile.per100Carbs,
      per100Fat: profile.per100Fat,
    );
  }

  GlobalFoodItemEditKind _selectedProductEditKindForItem(InventoryItem item) {
    final selectedProduct = state.selectedProduct;
    if (selectedProduct == null) {
      return GlobalFoodItemEditKind.createNewCandidate;
    }

    return classifyGlobalFoodItemEdit(
      currentItem: _globalFoodItemFromSelection(selectedProduct),
      name: item.name,
      brand: item.brand,
      barcode: item.barcode,
      imageUrl: normalizeProductImageUrl(item.imageUrl),
      packageWeight: item.weight,
      servingSize: item.servingSize,
      servingQuantity: item.servingQuantity,
      servingQuantityUnit: item.servingQuantityUnit,
      nutrition: item.nutrition,
    );
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

  ({String amount, InventoryAmountUnit unit})? _resolveOcrWeightInput(
    String? rawWeight,
  ) {
    final weight = normalizeManualProductText(rawWeight ?? '');
    if (weight == null) {
      return null;
    }
    final resolved = _resolveWeightInput(
      weight,
      fallbackUnit: state.selectedWeightUnit,
    );
    if (resolved.amount.isEmpty) {
      return null;
    }
    return resolved;
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

  ({String amount, InventoryAmountUnit unit}) _resolveWeightInput(
    String? rawWeight, {
    InventoryAmountUnit? fallbackUnit,
  }) {
    const parser = InventoryAmountParser();
    final parsed = parser.tryParse(
      rawWeight: rawWeight,
      quantity: 1,
      fallbackUnit: fallbackUnit,
    );
    if (parsed != null) {
      return (amount: parsed.amount.toString(), unit: parsed.unit);
    }

    final normalized = normalizeManualProductText(rawWeight ?? '');
    final amountMatch = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(normalized ?? '');
    final amount = amountMatch?.group(0)?.replaceAll(',', '.') ?? '';
    return (
      amount: amount,
      unit:
          _unitFromRawWeight(normalized) ??
          fallbackUnit ??
          InventoryAmountUnit.gram,
    );
  }

  InventoryAmountUnit? _unitFromRawWeight(String? rawWeight) {
    final normalized = rawWeight?.toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (normalized.contains('ml') ||
        RegExp(r'(^|\s)l\b').hasMatch(normalized)) {
      return InventoryAmountUnit.milliliter;
    }
    if (normalized.contains('stk') ||
        normalized.contains('stück') ||
        normalized.contains('st ') ||
        normalized.endsWith(' st') ||
        normalized.contains('pc') ||
        normalized.contains('piece')) {
      return InventoryAmountUnit.piece;
    }
    if (normalized.contains('g')) {
      return InventoryAmountUnit.gram;
    }
    return null;
  }

  String _weightUnitCode(InventoryAmountUnit unit) {
    return switch (unit) {
      InventoryAmountUnit.gram => 'g',
      InventoryAmountUnit.milliliter => 'ml',
      InventoryAmountUnit.piece => 'Stk',
    };
  }
}

String? _initialSearchStoreName(InventoryItem item) {
  if (item.isManuallyAdded) {
    return null;
  }
  return normalizeManualProductText(item.storeName);
}

bool _looksLikeBarcodeText(String value) {
  final normalized = normalizeBarcode(value);
  if (normalized.isEmpty) {
    return false;
  }
  final compact = value.replaceAll(RegExp(r'[\s-]+'), '');
  return compact == normalized;
}

String? _normalizeReusableGlobalFoodItemId(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (isPendingGlobalFoodItemId(normalized)) {
    return null;
  }
  return normalized;
}
