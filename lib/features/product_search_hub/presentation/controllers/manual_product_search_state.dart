import 'dart:typed_data';

import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_nutrition/domain/nutrition_label_ocr_models.dart';
import 'package:yamt/features/product_search_hub/domain/manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/manual_product_search_models.dart';

const _keepValue = Object();

/// Defines inventory receipt manual product state.
class InventoryReceiptManualProductState {
  /// The inventory receipt manual product state.
  const new({
    this.nameText = '',
    this.brandText = '',
    this.barcode = '',
    this.hasNoBarcode = false,
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
    this.selectedProduct,
    this.ocrDraft,
    this.isRunningNutritionOcr = false,
    this.nutritionOcrImageBytes,
    this.error,
  });

  /// The name text.
  final String nameText;

  /// The brand text.
  final String brandText;

  /// The barcode.
  final String barcode;

  /// Whether the user marked the product as having no barcode.
  final bool hasNoBarcode;

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

  /// The selected product.
  final InventoryReceiptManualProductSelection? selectedProduct;

  /// The ocr draft.
  final NutritionLabelOcrDraft? ocrDraft;

  /// Whether running nutrition ocr.
  final bool isRunningNutritionOcr;

  /// Captured image shown while nutrition OCR is running.
  final Uint8List? nutritionOcrImageBytes;

  /// The error.
  final InventoryReceiptManualProductError? error;

  /// Whether barcode.
  bool get hasBarcode => normalizeBarcode(barcode).isNotEmpty;

  /// Whether package weight input.
  bool get hasPackageWeightInput {
    return parseManualProductDouble(weightAmount) != null;
  }

  /// Whether name, kcal, carbs, protein and fat are filled in.
  bool get hasRequiredFields {
    return normalizeManualProductText(nameText) != null &&
        parseManualProductDouble(kcalText) != null &&
        parseManualProductDouble(carbsText) != null &&
        parseManualProductDouble(proteinText) != null &&
        parseManualProductDouble(fatText) != null;
  }

  /// Whether scan nutrition label.
  bool get canScanNutritionLabel {
    return !isRunningNutritionOcr && (hasBarcode || hasNoBarcode);
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
    String? nameText,
    String? brandText,
    String? barcode,
    bool? hasNoBarcode,
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
    Object? selectedProduct = _keepValue,
    Object? ocrDraft = _keepValue,
    bool? isRunningNutritionOcr,
    Object? nutritionOcrImageBytes = _keepValue,
    Object? error = _keepValue,
  }) {
    return InventoryReceiptManualProductState(
      nameText: nameText ?? this.nameText,
      brandText: brandText ?? this.brandText,
      barcode: barcode ?? this.barcode,
      hasNoBarcode: hasNoBarcode ?? this.hasNoBarcode,
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
      selectedProduct: selectedProduct == _keepValue
          ? this.selectedProduct
          : selectedProduct as InventoryReceiptManualProductSelection?,
      ocrDraft: ocrDraft == _keepValue
          ? this.ocrDraft
          : ocrDraft as NutritionLabelOcrDraft?,
      isRunningNutritionOcr:
          isRunningNutritionOcr ?? this.isRunningNutritionOcr,
      nutritionOcrImageBytes: nutritionOcrImageBytes == _keepValue
          ? this.nutritionOcrImageBytes
          : nutritionOcrImageBytes as Uint8List?,
      error: error == _keepValue
          ? this.error
          : error as InventoryReceiptManualProductError?,
    );
  }
}
