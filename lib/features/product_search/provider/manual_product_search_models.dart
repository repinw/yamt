part of 'manual_product_search_controller.dart';

@immutable
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

/// Defines inventory receipt manual product action.
enum InventoryReceiptManualProductAction {
  /// Save only to inventory.
  addToInventory,

  /// Save to inventory and continue to eat flow.
  eatNow,
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

  /// Creates a [InventoryReceiptManualProductSelection] from inventory item.
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

/// Structured save payload returned by manual product save builders.
typedef InventoryReceiptManualProductSavePayload = ({
  InventoryItem item,
  OffProductSearchResult? selectedProduct,
  String? selectedGlobalFoodItemId,
  bool requiresGlobalPersistence,
  String? globalPackageWeight,
});

typedef _ResolvedWeightInput = ({
  String amount,
  InventoryAmountUnit unit,
  String? normalizedWeight,
  InventoryAmountParseResult? parsedAmount,
});

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
  final NutritionLabelOcrDraft? ocrDraft;

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
          : ocrDraft as NutritionLabelOcrDraft?,
      isRunningNutritionOcr:
          isRunningNutritionOcr ?? this.isRunningNutritionOcr,
      error: error == _keepValue
          ? this.error
          : error as InventoryReceiptManualProductError?,
    );
  }
}
