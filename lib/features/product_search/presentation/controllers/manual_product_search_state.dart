import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_nutrition/domain/nutrition_label_ocr_models.dart';
import 'package:yamt/features/product_search/domain/manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search/presentation/controllers/manual_product_search_models.dart';

const _keepValue = Object();

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
    this.isManualDraft = false,
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

  /// Whether editing a user-created product draft.
  final bool isManualDraft;

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
    return isManualDraft ||
        selectedProduct != null ||
        ocrDraft != null ||
        hasBarcode ||
        hasNutritionInput ||
        error != null;
  }

  /// Whether own product draft can start from search text.
  bool get canCreateManualDraft {
    return normalizeManualProductText(searchQuery) != null && !showDetails;
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
    bool? isManualDraft,
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
      isManualDraft: isManualDraft ?? this.isManualDraft,
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
