import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_item_edit_policy.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'manual_product_eat_now_nutrition.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'manual_product_piece_weight.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search_hub/domain/manual_product_weight_input.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_state.dart';

part 'manual_product_search_controller.g.dart';

/// Defines inventory receipt manual product controller.
@riverpod
class InventoryReceiptManualProductController
    extends _$InventoryReceiptManualProductController {
  static const _nutritionValueTolerance = 0.000001;

  @override
  InventoryReceiptManualProductState build(
    InventoryReceiptManualProductConfig config,
  ) {
    final nutrition =
        config.item.nutrition ?? config.selectedProduct?.nutrition;
    final weightInput = resolveManualProductWeightInput(
      config.selectedProduct?.packageWeight ?? config.item.weight,
      fallbackUnit: config.item.amountUnit,
    );

    return InventoryReceiptManualProductState(
      nameText: config.selectedProduct?.name ?? config.item.name,
      brandText: config.selectedProduct?.brand ?? config.item.brand ?? '',
      barcode:
          config.item.normalizedBarcode ?? config.selectedProduct?.code ?? '',
      weightAmount: weightInput.amount,
      selectedWeightUnit: weightInput.amount.isEmpty
          ? config.item.amountUnit
          : weightInput.unit,
      // The same order as the save, which compares the input with it.
      pieceWeightText: manualProductPieceWeightText((
        size: null,
        quantity:
            config.selectedProduct?.servingQuantity ??
            config.item.servingQuantity,
        quantityUnit:
            config.selectedProduct?.servingQuantityUnit ??
            config.item.servingQuantityUnit,
      )),
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

  /// Update name text.
  void updateNameText(String value) {
    state = state.copyWith(nameText: value, error: null);
  }

  /// Update brand text.
  void updateBrandText(String value) {
    state = state.copyWith(brandText: value, error: null);
  }

  /// Update barcode.
  void updateBarcode(String value) {
    state = state.copyWith(barcode: value, barcodeOrigin: null, error: null);
  }

  /// Marks the product as having no barcode and clears the barcode.
  void updateHasNoBarcode({required bool value}) {
    state = state.copyWith(
      hasNoBarcode: value,
      barcode: value ? '' : state.barcode,
      barcodeOrigin: value ? null : state.barcodeOrigin,
      error: null,
    );
  }

  /// Update weight amount.
  void updateWeightAmount(String value) {
    state = state.copyWith(weightAmount: value, error: null);
  }

  /// Update weight unit.
  void updateWeightUnit(InventoryAmountUnit unit) {
    state = state.copyWith(selectedWeightUnit: unit, error: null);
  }

  /// Sets the grams of one piece.
  void updatePieceWeightText(String value) {
    state = state.copyWith(pieceWeightText: value, error: null);
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

  /// Shows the input row of the optional nutrient [type], empty.
  void showOptionalNutrition(InventoryReceiptOptionalNutritionType type) {
    state = switch (type) {
      InventoryReceiptOptionalNutritionType.polyunsaturatedFat =>
        state.copyWith(showPolyunsaturatedFatField: true, error: null),
      InventoryReceiptOptionalNutritionType.fiber => state.copyWith(
        showFiberField: true,
        error: null,
      ),
    };
  }

  /// Update fat text.
  void updateFatText(String value) {
    state = state.copyWith(fatText: value, error: null);
  }

  /// Update salt text.
  void updateSaltText(String value) {
    state = state.copyWith(saltText: value, error: null);
  }

  /// Apply scanned product.
  void applyScannedProduct(OffProductSearchResult product) {
    _applySelectedProductSelection(
      InventoryReceiptManualProductSelection.fromSearchResult(product),
    );
  }

  /// Apply recent item.
  void applyRecentItem(InventoryItem item) {
    _applySelectedProductSelection(
      InventoryReceiptManualProductSelection.fromInventoryItem(item),
    );
  }

  /// Apply scanned barcode only.
  void applyScannedBarcodeOnly(String barcode) {
    state = state.copyWith(
      barcode: barcode,
      barcodeOrigin: null,
      hasNoBarcode: false,
      selectedProduct: null,
      error: null,
    );
  }

  /// Fills name, brand, and package size from the front of the package.
  ///
  /// The barcode the AI read counts only while no other barcode is set.
  void applyFrontDetails(ProductFrontDetails details) {
    final weightInput = resolveManualProductOcrWeightInput(
      details.quantityLabel,
      fallbackUnit: state.selectedWeightUnit ?? InventoryAmountUnit.gram,
    );
    final aiBarcode = details.barcode;
    final takesAiBarcode =
        aiBarcode != null && !state.hasBarcode && !state.hasNoBarcode;
    state = state.copyWith(
      nameText: details.name,
      brandText: details.brand ?? state.brandText,
      weightAmount: weightInput?.amount ?? state.weightAmount,
      selectedWeightUnit: weightInput?.unit ?? state.selectedWeightUnit,
      barcode: takesAiBarcode ? aiBarcode : null,
      barcodeOrigin: takesAiBarcode
          ? ManualProductBarcodeOrigin.ai
          : state.barcodeOrigin,
      error: null,
    );
  }

  /// Takes [barcode] that the scanner found on a package photo, unless the
  /// user already entered or scanned one.
  void applyPhotoBarcode(String barcode) {
    final hasOwnBarcode =
        state.hasBarcode &&
        state.barcodeOrigin != ManualProductBarcodeOrigin.ai;
    if (hasOwnBarcode || state.hasNoBarcode) {
      return;
    }
    state = state.copyWith(
      barcode: barcode,
      barcodeOrigin: ManualProductBarcodeOrigin.photo,
      error: null,
    );
  }

  ManualProductResolvedWeightInput get _resolvedManualWeightInput {
    return resolveManualProductWeightInput(
      state.weightAmount,
      fallbackUnit: state.selectedWeightUnit,
    );
  }

  /// Builds the save payload.
  ///
  /// [photoImageUrl] is the stored front photo; it is the product image when
  /// the product has none.
  InventoryReceiptManualProductSavePayload? buildSavePayload({
    InventoryReceiptManualProductAction action =
        InventoryReceiptManualProductAction.addToInventory,
    String? photoImageUrl,
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

    final matchedProduct = state.matchedProduct;
    final selectedProduct = state.selectedProduct;
    final resolvedWeightInput = _resolvedManualWeightInput;
    final globalPackageWeight = _resolvedGlobalPackageWeightForSelection(
      action: action,
      selection: matchedProduct,
    );
    final inventoryWeight = resolvedWeightInput.normalizedWeight;
    final serving = resolveManualProductServing(
      packageUnit:
          resolvedWeightInput.parsedAmount?.unit ?? state.selectedWeightUnit,
      pieceWeightText: state.pieceWeightText,
      serving: (
        size:
            matchedProduct?.servingSize ??
            state.ocrDraft?.servingSizeLabel ??
            config.item.servingSize,
        quantity:
            matchedProduct?.servingQuantity ?? config.item.servingQuantity,
        quantityUnit:
            matchedProduct?.servingQuantityUnit ??
            config.item.servingQuantityUnit,
      ),
    );
    final updatedItem = config.item
        .copyWith(
          name: _resolvedManualName(
            fallbackName: matchedProduct?.name ?? config.item.name,
          ),
          brand: normalizeManualProductText(state.brandText),
          barcode: barcode,
          imageUrl:
              config.item.imageUrl ?? matchedProduct?.imageUrl ?? photoImageUrl,
          weight: inventoryWeight,
          servingSize: serving.size,
          servingQuantity: serving.quantity,
          servingQuantityUnit: serving.quantityUnit,
          nutrition: _resolvedSaveNutrition(
            hasNutrition: hasNutrition,
            selectedProduct: selectedProduct,
            kcal: kcal,
            saturatedFat: saturatedFat,
            polyunsaturatedFat: polyunsaturatedFat,
            protein: protein,
            carbs: carbs,
            sugar: sugar,
            fiber: fiber,
            fat: fat,
            salt: salt,
          ),
        )
        .withResolvedAmount(
          weight: inventoryWeight,
          parsedAmount: resolvedWeightInput.parsedAmount,
          quantity: config.item.quantity,
        )
        .withWeightUnitWithoutPackage(state.selectedWeightUnit);
    final selectedEditKind = _selectedProductEditKind(
      selection: state.selectedProduct,
      item: updatedItem,
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

  GlobalFoodNutrition? _resolvedSaveNutrition({
    required bool hasNutrition,
    required InventoryReceiptManualProductSelection? selectedProduct,
    required double? kcal,
    required double? saturatedFat,
    required double? polyunsaturatedFat,
    required double? protein,
    required double? carbs,
    required double? sugar,
    required double? fiber,
    required double? fat,
    required double? salt,
  }) {
    final sourceNutrition = selectedProduct?.nutrition ?? config.item.nutrition;
    if (!hasNutrition) {
      return sourceNutrition;
    }

    final nutrition = GlobalFoodNutrition(
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
    );
    if (sourceNutrition == null ||
        !_hasSameNutritionValues(nutrition, sourceNutrition)) {
      return nutrition;
    }
    return nutrition.copyWith(qualityStatus: sourceNutrition.qualityStatus);
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
      fallbackUnit: config.item.amountUnit,
    );
    final inventoryWeight = weightInput.normalizedWeight;
    final nutrition = selection.nutrition ?? config.item.nutrition;
    if (action == InventoryReceiptManualProductAction.eatNow) {
      if (!hasRequiredEatNowNutrition(nutrition)) {
        return null;
      }
    }

    final barcode = normalizeManualProductText(selection.barcode);
    if (barcode == null) {
      return null;
    }

    final updatedItem = config.item
        .copyWith(
          name: selection.name,
          brand: selection.brand,
          barcode: barcode,
          imageUrl: config.item.imageUrl ?? selection.imageUrl,
          weight: inventoryWeight,
          servingSize: selection.servingSize ?? config.item.servingSize,
          servingQuantity:
              selection.servingQuantity ?? config.item.servingQuantity,
          servingQuantityUnit:
              selection.servingQuantityUnit ?? config.item.servingQuantityUnit,
          nutrition: nutrition,
        )
        .withResolvedAmount(
          weight: inventoryWeight,
          parsedAmount: weightInput.parsedAmount,
          quantity: config.item.quantity,
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

  void _applySelectedProductSelection(
    InventoryReceiptManualProductSelection product,
  ) {
    final nutrition = product.nutrition;
    final weightInput = resolveManualProductWeightInput(
      product.packageWeight,
      fallbackUnit: state.selectedWeightUnit,
    );
    state = state.copyWith(
      nameText: product.name,
      brandText: product.brand ?? '',
      barcode: product.barcode,
      weightAmount: weightInput.amount,
      selectedWeightUnit: weightInput.amount.isEmpty
          ? state.selectedWeightUnit
          : weightInput.unit,
      pieceWeightText: manualProductPieceWeightText((
        size: null,
        quantity: product.servingQuantity,
        quantityUnit: product.servingQuantityUnit,
      )),
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
      selectedProduct: product,
      barcodeOrigin: null,
      ocrDraft: null,
      error: null,
    );
  }

  /// Fills the nutrition values, and name, brand, and package size when
  /// printed, from a read nutrition table.
  void applyNutritionLabelDraft(NutritionLabelOcrDraft draft) {
    final ocrWeightInput = resolveManualProductOcrWeightInput(
      draft.quantityLabel,
      fallbackUnit: state.selectedWeightUnit ?? InventoryAmountUnit.gram,
    );
    final ocrName = normalizeManualProductText(draft.name ?? '');
    final ocrBrand = normalizeManualProductText(draft.brand ?? '');
    state = state.copyWith(
      ocrDraft: draft,
      nameText: ocrName ?? state.nameText,
      brandText: ocrBrand ?? state.brandText,
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
      error: null,
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

  String? _resolvedGlobalPackageWeightForSelection({
    required InventoryReceiptManualProductAction action,
    required InventoryReceiptManualProductSelection? selection,
  }) {
    if (action == InventoryReceiptManualProductAction.addToInventory) {
      return _resolvedManualWeightInput.normalizedWeight;
    }
    return selection?.packageWeight ?? config.item.weight;
  }

  String _resolvedManualName({required String fallbackName}) {
    return normalizeManualProductText(state.nameText) ?? fallbackName;
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

  bool _hasSameNutritionValues(
    GlobalFoodNutrition left,
    GlobalFoodNutrition right,
  ) {
    return _hasSameNutritionAmount(left.per100Kcal, right.per100Kcal) &&
        _hasSameNutritionAmount(left.per100Protein, right.per100Protein) &&
        _hasSameNutritionAmount(left.per100Carbs, right.per100Carbs) &&
        _hasSameNutritionAmount(left.per100Fat, right.per100Fat) &&
        _hasSameNutritionAmount(left.per100Salt, right.per100Salt) &&
        _hasSameNutritionAmount(
          left.per100SaturatedFat,
          right.per100SaturatedFat,
        ) &&
        _hasSameNutritionAmount(
          left.per100PolyunsaturatedFat,
          right.per100PolyunsaturatedFat,
        ) &&
        _hasSameNutritionAmount(left.per100Sugar, right.per100Sugar) &&
        _hasSameNutritionAmount(left.per100Fiber, right.per100Fiber);
  }

  bool _hasSameNutritionAmount(double? left, double? right) {
    if (left == null || right == null) {
      return left == right;
    }
    return (left - right).abs() <= _nutritionValueTolerance;
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
}
