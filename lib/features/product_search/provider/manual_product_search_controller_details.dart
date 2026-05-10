part of 'manual_product_search_controller.dart';

mixin _ManualProductSearchControllerDetails
    on _$InventoryReceiptManualProductController {
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

  _ResolvedWeightInput get _resolvedManualWeightInput {
    return _resolveWeightInput(
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
    final weightInput = _resolveWeightInput(
      selection.packageWeight,
      fallbackUnit: _config.item.amountUnit,
    );
    final inventoryWeight = weightInput.normalizedWeight;
    final nutrition = selection.nutrition ?? _config.item.nutrition;
    if (action == InventoryReceiptManualProductAction.eatNow) {
      if (nutrition?.hasAnyNutritionValue != true) {
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
            limit: InventoryReceiptManualProductController._searchResultLimit,
          );
      final filteredResults = results
          .where(
            (result) =>
                result.nutrition?.hasEuMandatoryNutritionDeclaration == true,
          )
          .toList(growable: false);

      if (!ref.mounted || requestId != _activeSearchRequestId) {
        return;
      }

      state = state.copyWith(
        isSearching: false,
        searchResults: filteredResults,
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

  void _applyOcrDraft(NutritionLabelOcrDraft draft) {
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

  _ResolvedWeightInput? _resolveOcrWeightInput(
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

  _ResolvedWeightInput _resolveWeightInput(
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
      final amount = formatInventoryAmountValue(
        amount: parsed.amount,
        unit: parsed.unit,
        scale: parsed.scale,
      );
      return (
        amount: amount,
        unit: parsed.unit,
        normalizedWeight: '$amount ${parsed.unit.code}',
        parsedAmount: parsed,
      );
    }

    final normalized = normalizeManualProductText(rawWeight ?? '');
    final amountMatch = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(normalized ?? '');
    final amount = amountMatch?.group(0)?.replaceAll(',', '.') ?? '';
    final unit =
        _unitFromRawWeight(normalized) ??
        fallbackUnit ??
        InventoryAmountUnit.gram;
    final parsedAmount = _parseWeightAmount(amount: amount, unit: unit);
    return (
      amount: amount,
      unit: unit,
      normalizedWeight: amount.isEmpty ? null : '$amount ${unit.code}',
      parsedAmount: parsedAmount,
    );
  }

  InventoryAmountParseResult? _parseWeightAmount({
    required String amount,
    required InventoryAmountUnit unit,
  }) {
    if (amount.isEmpty) {
      return null;
    }

    final scale = unit == InventoryAmountUnit.piece
        ? inventoryPieceAmountScale
        : 1;
    final parsedAmount = parseInventoryAmountInput(
      rawValue: amount,
      unit: unit,
      scale: scale,
    );
    if (parsedAmount == null) {
      return null;
    }
    return InventoryAmountParseResult(
      amount: parsedAmount,
      unit: unit,
      scale: scale,
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
}
