import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
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
    this.selectedWeightUnit,
    this.pieceWeightText = '',
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
    this.selectedProduct,
    this.ocrDraft,
    this.barcodeOrigin,
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
  final InventoryAmountUnit? selectedWeightUnit;

  /// Grams of one piece, for a package counted in pieces.
  final String pieceWeightText;

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

  /// The selected product.
  final InventoryReceiptManualProductSelection? selectedProduct;

  /// The ocr draft.
  final NutritionLabelOcrDraft? ocrDraft;

  /// Where the barcode came from when a photo delivered it, or null when
  /// the user typed or scanned it.
  final ManualProductBarcodeOrigin? barcodeOrigin;

  /// The error.
  final InventoryReceiptManualProductError? error;

  /// Whether barcode.
  bool get hasBarcode => normalizeBarcode(barcode).isNotEmpty;

  /// The selected product, unless the barcode was changed to another one.
  InventoryReceiptManualProductSelection? get matchedProduct {
    final product = selectedProduct;
    if (product == null) {
      return null;
    }
    final normalizedBarcode = normalizeBarcode(barcode);
    if (normalizedBarcode.isNotEmpty &&
        normalizedBarcode != normalizeBarcode(product.barcode)) {
      return null;
    }
    return product;
  }

  /// Whether package weight input.
  bool get hasPackageWeightInput {
    return parseManualProductDouble(weightAmount) != null;
  }

  /// Whether the name, the unit, and every value of the EU nutrition label
  /// are filled in.
  bool get hasRequiredFields {
    return normalizeManualProductText(nameText) != null &&
        selectedWeightUnit != null &&
        hasMandatoryNutrition;
  }

  /// Whether the seven values of the EU nutrition label are filled in:
  /// energy, fat, saturates, carbohydrate, sugars, protein, and salt.
  bool get hasMandatoryNutrition {
    return [
      kcalText,
      fatText,
      saturatedFatText,
      carbsText,
      sugarText,
      proteinText,
      saltText,
    ].every((text) => parseManualProductDouble(text) != null);
  }

  /// Whether the barcode is settled: entered, or marked as missing.
  bool get hasBarcodeDecision => hasBarcode || hasNoBarcode;

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

  /// Fills the nutrition inputs from [nutrition], and shows the optional
  /// rows that it has values for.
  InventoryReceiptManualProductState withNutrition(
    GlobalFoodNutrition? nutrition,
  ) {
    return copyWith(
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
    );
  }

  /// Copy with.
  InventoryReceiptManualProductState copyWith({
    String? nameText,
    String? brandText,
    String? barcode,
    bool? hasNoBarcode,
    String? weightAmount,
    InventoryAmountUnit? selectedWeightUnit,
    String? pieceWeightText,
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
    Object? selectedProduct = _keepValue,
    Object? ocrDraft = _keepValue,
    Object? barcodeOrigin = _keepValue,
    Object? error = _keepValue,
  }) {
    return InventoryReceiptManualProductState(
      nameText: nameText ?? this.nameText,
      brandText: brandText ?? this.brandText,
      barcode: barcode ?? this.barcode,
      hasNoBarcode: hasNoBarcode ?? this.hasNoBarcode,
      weightAmount: weightAmount ?? this.weightAmount,
      selectedWeightUnit: selectedWeightUnit ?? this.selectedWeightUnit,
      pieceWeightText: pieceWeightText ?? this.pieceWeightText,
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
      selectedProduct: selectedProduct == _keepValue
          ? this.selectedProduct
          : selectedProduct as InventoryReceiptManualProductSelection?,
      ocrDraft: ocrDraft == _keepValue
          ? this.ocrDraft
          : ocrDraft as NutritionLabelOcrDraft?,
      barcodeOrigin: barcodeOrigin == _keepValue
          ? this.barcodeOrigin
          : barcodeOrigin as ManualProductBarcodeOrigin?,
      error: error == _keepValue
          ? this.error
          : error as InventoryReceiptManualProductError?,
    );
  }
}
