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
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'inventory_receipt_manual_product_form_utils.dart';

part 'inventory_receipt_manual_product_controller.g.dart';

const _manualProductControllerLogName =
    'InventoryReceiptManualProductController';
const _keepValue = Object();

class InventoryReceiptManualProductConfig {
  const InventoryReceiptManualProductConfig({
    required this.item,
    this.selectedProduct,
    this.includeStoreInSearch = true,
    this.includeWeightInSearch = true,
  });

  final InventoryItem item;
  final OffProductSearchResult? selectedProduct;
  final bool includeStoreInSearch;
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
      product?.nutrition,
    );
  }
}

enum InventoryReceiptManualProductError { requiredProductOrNutrition }

enum InventoryReceiptManualProductNutritionScanOutcome {
  applied,
  canceled,
  failed,
  missingBarcode,
}

enum InventoryReceiptManualProductSelectionSource {
  externalSearch,
  recentInventory,
}

class InventoryReceiptManualProductSelection {
  const InventoryReceiptManualProductSelection({
    required this.source,
    required this.name,
    required this.barcode,
    this.brand,
    this.imageUrl,
    this.packageWeight,
    this.nutrition,
    this.externalProduct,
    this.globalFoodItemId,
  });

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
      nutrition: result.nutrition,
      externalProduct: result,
    );
  }

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
      nutrition: item.nutrition,
      globalFoodItemId: _normalizeReusableGlobalFoodItemId(
        item.globalFoodItemId,
      ),
    );
  }

  final InventoryReceiptManualProductSelectionSource source;
  final String name;
  final String barcode;
  final String? brand;
  final String? imageUrl;
  final String? packageWeight;
  final GlobalFoodNutrition? nutrition;
  final OffProductSearchResult? externalProduct;
  final String? globalFoodItemId;
}

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

class InventoryReceiptManualProductState {
  const InventoryReceiptManualProductState({
    this.searchQuery = '',
    this.barcode = '',
    this.weightAmount = '',
    this.selectedWeightUnit = InventoryAmountUnit.gram,
    this.kcalText = '',
    this.proteinText = '',
    this.carbsText = '',
    this.fatText = '',
    this.isSearching = false,
    this.searchResults = const <OffProductSearchResult>[],
    this.selectedProduct,
    this.ocrProfile,
    this.isRunningNutritionOcr = false,
    this.error,
  });

  final String searchQuery;
  final String barcode;
  final String weightAmount;
  final InventoryAmountUnit selectedWeightUnit;
  final String kcalText;
  final String proteinText;
  final String carbsText;
  final String fatText;
  final bool isSearching;
  final List<OffProductSearchResult> searchResults;
  final InventoryReceiptManualProductSelection? selectedProduct;
  final CalorieProductProfile? ocrProfile;
  final bool isRunningNutritionOcr;
  final InventoryReceiptManualProductError? error;

  bool get hasBarcode => normalizeBarcode(barcode).isNotEmpty;

  bool get hasNutritionInput {
    return normalizeManualProductText(kcalText) != null ||
        normalizeManualProductText(proteinText) != null ||
        normalizeManualProductText(carbsText) != null ||
        normalizeManualProductText(fatText) != null;
  }

  bool get showDetails {
    return selectedProduct != null ||
        ocrProfile != null ||
        hasBarcode ||
        hasNutritionInput ||
        error != null;
  }

  bool get canScanNutritionLabel {
    return !isRunningNutritionOcr && hasBarcode;
  }

  InventoryReceiptManualProductState copyWith({
    String? searchQuery,
    String? barcode,
    String? weightAmount,
    InventoryAmountUnit? selectedWeightUnit,
    String? kcalText,
    String? proteinText,
    String? carbsText,
    String? fatText,
    bool? isSearching,
    List<OffProductSearchResult>? searchResults,
    Object? selectedProduct = _keepValue,
    Object? ocrProfile = _keepValue,
    bool? isRunningNutritionOcr,
    Object? error = _keepValue,
  }) {
    return InventoryReceiptManualProductState(
      searchQuery: searchQuery ?? this.searchQuery,
      barcode: barcode ?? this.barcode,
      weightAmount: weightAmount ?? this.weightAmount,
      selectedWeightUnit: selectedWeightUnit ?? this.selectedWeightUnit,
      kcalText: kcalText ?? this.kcalText,
      proteinText: proteinText ?? this.proteinText,
      carbsText: carbsText ?? this.carbsText,
      fatText: fatText ?? this.fatText,
      isSearching: isSearching ?? this.isSearching,
      searchResults: searchResults ?? this.searchResults,
      selectedProduct: selectedProduct == _keepValue
          ? this.selectedProduct
          : selectedProduct as InventoryReceiptManualProductSelection?,
      ocrProfile: ocrProfile == _keepValue
          ? this.ocrProfile
          : ocrProfile as CalorieProductProfile?,
      isRunningNutritionOcr:
          isRunningNutritionOcr ?? this.isRunningNutritionOcr,
      error: error == _keepValue
          ? this.error
          : error as InventoryReceiptManualProductError?,
    );
  }
}

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
      barcode:
          config.item.normalizedBarcode ?? config.selectedProduct?.code ?? '',
      weightAmount: weightInput.amount,
      selectedWeightUnit: weightInput.unit,
      kcalText: formatManualProductDouble(nutrition?.per100Kcal),
      proteinText: formatManualProductDouble(nutrition?.per100Protein),
      carbsText: formatManualProductDouble(nutrition?.per100Carbs),
      fatText: formatManualProductDouble(nutrition?.per100Fat),
      selectedProduct: config.selectedProduct == null
          ? null
          : InventoryReceiptManualProductSelection.fromSearchResult(
              config.selectedProduct!,
            ),
    );
  }

  ({String imageUrl, String name, String? brand, String? weight})?
  buildPreviewData() {
    final selectedProduct = _currentPreviewProduct();
    final imageUrl = normalizeProductImageUrl(
      selectedProduct?.imageUrl ?? _config.item.imageUrl,
    );
    if (imageUrl == null) {
      return null;
    }

    final ocrProfile = _resolvedOcrProfile();
    return (
      imageUrl: imageUrl,
      name:
          selectedProduct?.name ??
          _resolvedNameFromOcr(ocrProfile) ??
          _config.item.name,
      brand: selectedProduct?.brand ?? ocrProfile?.brand ?? _config.item.brand,
      weight: resolvedWeight,
    );
  }

  String? get resolvedWeight {
    final amountText = normalizeManualProductText(state.weightAmount);
    if (amountText == null) {
      return null;
    }
    return '$amountText ${_weightUnitCode(state.selectedWeightUnit)}';
  }

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

  void updateBarcode(String value) {
    state = state.copyWith(barcode: value, error: null);
  }

  void updateWeightAmount(String value) {
    state = state.copyWith(weightAmount: value, error: null);
  }

  void updateWeightUnit(InventoryAmountUnit unit) {
    state = state.copyWith(selectedWeightUnit: unit, error: null);
  }

  void updateKcalText(String value) {
    state = state.copyWith(kcalText: value, error: null);
  }

  void updateProteinText(String value) {
    state = state.copyWith(proteinText: value, error: null);
  }

  void updateCarbsText(String value) {
    state = state.copyWith(carbsText: value, error: null);
  }

  void updateFatText(String value) {
    state = state.copyWith(fatText: value, error: null);
  }

  void applySearchResult(OffProductSearchResult product) {
    _searchDebounce?.cancel();
    _applySelectedProductSelection(
      InventoryReceiptManualProductSelection.fromSearchResult(product),
    );
  }

  void applyScannedProduct(OffProductSearchResult product) {
    _applySelectedProductSelection(
      InventoryReceiptManualProductSelection.fromSearchResult(product),
    );
  }

  void applyRecentItem(InventoryItem item) {
    _searchDebounce?.cancel();
    _applySelectedProductSelection(
      InventoryReceiptManualProductSelection.fromInventoryItem(item),
    );
  }

  void applyScannedBarcodeOnly(String barcode) {
    state = state.copyWith(
      barcode: barcode,
      selectedProduct: null,
      ocrProfile: null,
      kcalText: '',
      proteinText: '',
      carbsText: '',
      fatText: '',
      error: null,
    );
  }

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
          final profile = result.profile;
          if (profile == null) {
            return InventoryReceiptManualProductNutritionScanOutcome.canceled;
          }
          _applyOcrProfile(profile);
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

  ({
    InventoryItem item,
    OffProductSearchResult? selectedProduct,
    String? selectedGlobalFoodItemId,
  })?
  buildSavePayload() {
    final barcode = normalizeManualProductText(state.barcode);
    final kcal = parseManualProductDouble(state.kcalText);
    final protein = parseManualProductDouble(state.proteinText);
    final carbs = parseManualProductDouble(state.carbsText);
    final fat = parseManualProductDouble(state.fatText);
    final hasNutrition =
        kcal != null || protein != null || carbs != null || fat != null;

    if (barcode == null && !hasNutrition) {
      state = state.copyWith(
        error: InventoryReceiptManualProductError.requiredProductOrNutrition,
      );
      return null;
    }

    final selectedProduct = _effectiveSelectedProductSelection(
      barcode: barcode,
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
    final ocrProfile = _resolvedOcrProfile();
    final updatedItem = _config.item
        .copyWith(
          name:
              selectedProduct?.name ??
              _resolvedNameFromOcr(ocrProfile) ??
              _config.item.name,
          brand:
              selectedProduct?.brand ?? ocrProfile?.brand ?? _config.item.brand,
          barcode: barcode,
          imageUrl: selectedProduct?.imageUrl ?? _config.item.imageUrl,
          weight: resolvedWeight,
          nutrition: hasNutrition
              ? GlobalFoodNutrition(
                  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
                  per100Kcal: kcal,
                  per100Protein: protein,
                  per100Carbs: carbs,
                  per100Fat: fat,
                )
              : selectedProduct?.nutrition ??
                    _nutritionFromProfile(ocrProfile) ??
                    _config.item.nutrition,
        )
        .withDerivedAmount(
          weight: resolvedWeight,
          quantity: _config.item.quantity,
          fallbackUnit: state.selectedWeightUnit,
        );
    return (
      item: updatedItem,
      selectedProduct: selectedProduct?.externalProduct,
      selectedGlobalFoodItemId: selectedProduct?.globalFoodItemId,
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
            brand: null,
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
      barcode: product.barcode,
      weightAmount: weightInput.amount,
      selectedWeightUnit: weightInput.unit,
      kcalText: formatManualProductDouble(nutrition?.per100Kcal),
      proteinText: formatManualProductDouble(nutrition?.per100Protein),
      carbsText: formatManualProductDouble(nutrition?.per100Carbs),
      fatText: formatManualProductDouble(nutrition?.per100Fat),
      selectedProduct: product,
      ocrProfile: null,
      searchResults: const <OffProductSearchResult>[],
      error: null,
    );
  }

  void _applyOcrProfile(CalorieProductProfile profile) {
    state = state.copyWith(
      ocrProfile: profile,
      kcalText: formatManualProductDouble(profile.per100Kcal),
      proteinText: formatManualProductDouble(profile.per100Protein),
      carbsText: formatManualProductDouble(profile.per100Carbs),
      fatText: formatManualProductDouble(profile.per100Fat),
      error: null,
    );
  }

  InventoryReceiptManualProductSelection? _effectiveSelectedProductSelection({
    required String? barcode,
    required double? kcal,
    required double? protein,
    required double? carbs,
    required double? fat,
  }) {
    final selectedProduct = state.selectedProduct;
    if (selectedProduct == null) {
      return null;
    }

    final normalizedBarcode = barcode == null ? '' : normalizeBarcode(barcode);
    if (normalizedBarcode != normalizeBarcode(selectedProduct.barcode)) {
      return null;
    }

    final nutrition = selectedProduct.nutrition;
    final matchesOriginalNutrition =
        kcal == nutrition?.per100Kcal &&
        protein == nutrition?.per100Protein &&
        carbs == nutrition?.per100Carbs &&
        fat == nutrition?.per100Fat;
    if (!matchesOriginalNutrition) {
      return null;
    }
    return selectedProduct;
  }

  InventoryReceiptManualProductSelection? _currentPreviewProduct() {
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

  CalorieProductProfile? _resolvedOcrProfile() {
    final profile = state.ocrProfile;
    if (profile == null) {
      return null;
    }

    final barcode = normalizeBarcode(state.barcode);
    if (barcode.isEmpty || barcode != normalizeBarcode(profile.barcode)) {
      return null;
    }
    return profile;
  }

  String? _resolvedNameFromOcr(CalorieProductProfile? profile) {
    if (profile == null) {
      return null;
    }
    final name = profile.name.trim();
    if (name.isEmpty || name == profile.barcode) {
      return null;
    }
    return name;
  }

  GlobalFoodNutrition? _nutritionFromProfile(CalorieProductProfile? profile) {
    if (profile == null) {
      return null;
    }
    return GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: profile.per100Kcal,
      per100Protein: profile.per100Protein,
      per100Carbs: profile.per100Carbs,
      per100Fat: profile.per100Fat,
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

  ({String amount, InventoryAmountUnit unit}) _resolveWeightInput(
    String? rawWeight, {
    InventoryAmountUnit? fallbackUnit,
  }) {
    final parser = const InventoryAmountParser();
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
