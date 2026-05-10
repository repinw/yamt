import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/core/utils/product_image_url.dart';
import 'package:yamt/core/utils/store_name_normalizer.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_item_edit_policy.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_nutrition/data/'
    'nutrition_label_ocr_repository.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_search_value_utils.dart';

part 'manual_product_search_controller.g.dart';
part 'manual_product_search_models.dart';
part 'manual_product_search_controller_details.dart';

const _manualProductControllerLogName =
    'InventoryReceiptManualProductController';
const _keepValue = Object();

/// Defines inventory receipt manual product controller.
@riverpod
class InventoryReceiptManualProductController
    extends _$InventoryReceiptManualProductController
    with _ManualProductSearchControllerDetails {
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
          return InventoryReceiptManualProductNutritionScanOutcome.failed;
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isRunningNutritionOcr: false);
      }
    }
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
