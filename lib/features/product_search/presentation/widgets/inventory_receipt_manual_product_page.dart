import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/utils/barcode_utils.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'inventory_receipt_manual_product_form.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'inventory_receipt_manual_product_form_utils.dart';
import 'package:yamt/features/product_search/provider/'
    'inventory_receipt_manual_product_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _manualProductRecentItemLimit = 6;
const _manualProductPageLogName = 'InventoryReceiptManualProductPage';

class InventoryReceiptManualProductPage extends StatelessWidget {
  const InventoryReceiptManualProductPage({
    super.key,
    required this.item,
    this.selectedProduct,
    this.includeStoreInSearch = true,
    this.includeWeightInSearch = true,
    this.showEatImmediatelyOption = false,
    this.onSaved,
  });

  final InventoryItem item;
  final OffProductSearchResult? selectedProduct;
  final bool includeStoreInSearch;
  final bool includeWeightInSearch;
  final bool showEatImmediatelyOption;
  final Future<void> Function(InventoryReceiptManualProductResult result)?
  onSaved;

  @override
  Widget build(BuildContext context) {
    final config = InventoryReceiptManualProductConfig(
      item: item,
      selectedProduct: selectedProduct,
      includeStoreInSearch: includeStoreInSearch,
      includeWeightInSearch: includeWeightInSearch,
    );

    if (_shouldOpenEditorImmediately(
      item: item,
      selectedProduct: selectedProduct,
    )) {
      return _InventoryReceiptManualProductEditorPage(
        config: config,
        showEatImmediatelyOption: showEatImmediatelyOption,
        onSaved: onSaved,
      );
    }

    return _InventoryReceiptManualProductLauncherPage(
      config: config,
      showEatImmediatelyOption: showEatImmediatelyOption,
      onSaved: onSaved,
    );
  }
}

class InventoryReceiptManualProductResult {
  const InventoryReceiptManualProductResult({
    required this.item,
    this.selectedProduct,
    this.selectedGlobalFoodItemId,
    this.requiresGlobalPersistence = true,
    this.eatImmediately = false,
    this.eatNowWeight,
  });

  final InventoryItem item;
  final OffProductSearchResult? selectedProduct;
  final String? selectedGlobalFoodItemId;
  final bool requiresGlobalPersistence;
  final bool eatImmediately;
  final String? eatNowWeight;
}

bool _shouldOpenEditorImmediately({
  required InventoryItem item,
  required OffProductSearchResult? selectedProduct,
}) {
  return selectedProduct != null ||
      item.normalizedBarcode != null ||
      item.nutrition != null;
}

class _InventoryReceiptManualProductLauncherPage
    extends ConsumerStatefulWidget {
  const _InventoryReceiptManualProductLauncherPage({
    required this.config,
    required this.showEatImmediatelyOption,
    this.onSaved,
  });

  final InventoryReceiptManualProductConfig config;
  final bool showEatImmediatelyOption;
  final Future<void> Function(InventoryReceiptManualProductResult result)?
  onSaved;

  @override
  ConsumerState<_InventoryReceiptManualProductLauncherPage> createState() =>
      _InventoryReceiptManualProductLauncherPageState();
}

class _InventoryReceiptManualProductLauncherPageState
    extends ConsumerState<_InventoryReceiptManualProductLauncherPage> {
  late final TextEditingController _searchController;
  List<InventoryItem> _recentItems = const <InventoryItem>[];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: buildManualProductInitialSearchQuery(widget.config) ?? '',
    );
    unawaited(_loadRecentItems());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inventoryReceiptReviewManualDataTitle)),
      body: InventoryReceiptManualProductLauncherContent(
        searchController: _searchController,
        recentItems: _recentItems,
        onSearchTap: () {
          unawaited(_openSearchEditor());
        },
        onVoiceSearchTap: () {
          unawaited(_openVoiceSearchEditor());
        },
        onRecentItemSelected: (item) {
          unawaited(_openRecentItemEditor(item));
        },
        onScanBarcode: () {
          unawaited(_openBarcodeScanner());
        },
      ),
    );
  }

  Future<void> _loadRecentItems() async {
    try {
      final items = await ref.read(inventoryItemRepositoryProvider).readAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _recentItems = _buildRecentItems(items);
      });
    } catch (error, stackTrace) {
      log(
        'Failed to load recent manual product items.',
        name: _manualProductPageLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _openSearchEditor() async {
    await _openEditor(autofocusSearch: true);
  }

  Future<void> _openVoiceSearchEditor() async {
    await _openEditor(autofocusSearch: true, initialStartVoiceSearch: true);
  }

  Future<void> _openRecentItemEditor(InventoryItem item) async {
    await _openEditor(initialRecentItem: item);
  }

  Future<void> _openEditor({
    InventoryItem? itemOverride,
    OffProductSearchResult? selectedProduct,
    InventoryItem? initialRecentItem,
    bool autofocusSearch = false,
    bool initialStartVoiceSearch = false,
    String? initialInfoMessage,
  }) async {
    final config = InventoryReceiptManualProductConfig(
      item: itemOverride ?? widget.config.item,
      selectedProduct: selectedProduct,
      includeStoreInSearch: widget.config.includeStoreInSearch,
      includeWeightInSearch: widget.config.includeWeightInSearch,
    );
    final result = await Navigator.of(context)
        .push<InventoryReceiptManualProductResult>(
          _NoAnimationMaterialPageRoute<InventoryReceiptManualProductResult>(
            fullscreenDialog: true,
            builder: (routeContext) {
              return _InventoryReceiptManualProductEditorPage(
                config: config,
                showEatImmediatelyOption: widget.showEatImmediatelyOption,
                onSaved: widget.onSaved,
                autofocusSearch: autofocusSearch,
                initialStartVoiceSearch: initialStartVoiceSearch,
                initialRecentItem: initialRecentItem,
                initialInfoMessage: initialInfoMessage,
              );
            },
          ),
        );
    if (!mounted || result == null) {
      return;
    }

    final onSaved = widget.onSaved;
    if (onSaved != null) {
      await onSaved(result);
      return;
    }
    _closePage(result);
  }

  Future<void> _openBarcodeScanner() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<_ManualBarcodeScanResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 1,
          child: InventoryBarcodeScannerPage(
            title: l10n.inventoryBarcodeMissingPromptScanNow,
            onProductSelected: (candidate, scannedBarcode) async {
              Navigator.of(sheetContext).pop(
                _ManualBarcodeScanResult.selected(
                  candidate: candidate,
                  scannedBarcode: scannedBarcode,
                ),
              );
              return true;
            },
            onProductNotFound: (scannedBarcode) async {
              Navigator.of(sheetContext).pop(
                _ManualBarcodeScanResult.notFound(
                  scannedBarcode: scannedBarcode,
                ),
              );
              return true;
            },
          ),
        );
      },
    );
    if (!mounted || result == null) {
      return;
    }

    switch (result.kind) {
      case _ManualBarcodeScanResultKind.selected:
        final candidate = result.candidate;
        if (candidate == null) {
          return;
        }
        final selectedProduct = candidate.externalProduct;
        if (selectedProduct != null) {
          await _openEditor(selectedProduct: selectedProduct);
          return;
        }

        final globalFoodItem = candidate.globalFoodItem;
        if (globalFoodItem == null) {
          return;
        }
        final selectedItem = _inventoryItemFromBarcodeCandidate(
          baseItem: widget.config.item,
          globalFoodItem: globalFoodItem,
          barcode: result.scannedBarcode ?? candidate.barcode,
        );
        await _openEditor(
          itemOverride: selectedItem,
          initialRecentItem: selectedItem,
        );
      case _ManualBarcodeScanResultKind.notFound:
        final scannedBarcode = result.scannedBarcode;
        if (scannedBarcode == null || scannedBarcode.isEmpty) {
          return;
        }
        await _openEditor(
          itemOverride: widget.config.item.copyWith(barcode: scannedBarcode),
          initialInfoMessage: l10n.inventoryManualAddNotFound,
        );
    }
  }

  void _closePage<T extends Object?>([T? result]) {
    if (!mounted) {
      return;
    }

    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.pop(result);
      return;
    }
    Navigator.of(context).pop(result);
  }
}

class _InventoryReceiptManualProductEditorPage extends ConsumerStatefulWidget {
  const _InventoryReceiptManualProductEditorPage({
    required this.config,
    required this.showEatImmediatelyOption,
    this.onSaved,
    this.autofocusSearch = false,
    this.initialStartVoiceSearch = false,
    this.initialRecentItem,
    this.initialInfoMessage,
    this.initialEatImmediately = false,
    this.initialEatNowAmount = '',
    this.initialEatNowUnit,
  });

  final InventoryReceiptManualProductConfig config;
  final bool showEatImmediatelyOption;
  final Future<void> Function(InventoryReceiptManualProductResult result)?
  onSaved;
  final bool autofocusSearch;
  final bool initialStartVoiceSearch;
  final InventoryItem? initialRecentItem;
  final String? initialInfoMessage;
  final bool initialEatImmediately;
  final String initialEatNowAmount;
  final InventoryAmountUnit? initialEatNowUnit;

  @override
  ConsumerState<_InventoryReceiptManualProductEditorPage> createState() =>
      _InventoryReceiptManualProductEditorPageState();
}

class _NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  _NoAnimationMaterialPageRoute({
    required super.builder,
    super.fullscreenDialog,
  });

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

enum _ManualBarcodeScanResultKind { selected, notFound }

class _ManualBarcodeScanResult {
  const _ManualBarcodeScanResult._({
    required this.kind,
    this.candidate,
    this.scannedBarcode,
  });

  const _ManualBarcodeScanResult.selected({
    required InventoryBarcodeLookupCandidate candidate,
    required String scannedBarcode,
  }) : this._(
         kind: _ManualBarcodeScanResultKind.selected,
         candidate: candidate,
         scannedBarcode: scannedBarcode,
       );

  const _ManualBarcodeScanResult.notFound({required String scannedBarcode})
    : this._(
        kind: _ManualBarcodeScanResultKind.notFound,
        scannedBarcode: scannedBarcode,
      );

  final _ManualBarcodeScanResultKind kind;
  final InventoryBarcodeLookupCandidate? candidate;
  final String? scannedBarcode;
}

class _InventoryReceiptManualProductEditorPageState
    extends ConsumerState<_InventoryReceiptManualProductEditorPage> {
  late final VoiceSearchService _voiceSearchService;
  final _voiceSearchController = TextVoiceSearchController();
  late final TextEditingController _searchController;
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _weightAmountController;
  late final TextEditingController _eatNowAmountController;
  late final TextEditingController _kcalController;
  late final TextEditingController _saturatedFatController;
  late final TextEditingController _polyunsaturatedFatController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _sugarController;
  late final TextEditingController _fiberController;
  late final TextEditingController _fatController;
  late final TextEditingController _saltController;
  late final TextEditingController _optionalNutritionValueController;
  ProviderSubscription<InventoryReceiptManualProductState>? _stateSubscription;
  bool _didBindProviderState = false;
  bool _didScheduleInitialRecentItem = false;
  bool _isSyncingControllers = false;
  late bool _eatImmediately = widget.initialEatImmediately;
  late InventoryAmountUnit _selectedEatNowUnit =
      widget.initialEatNowUnit ?? _defaultEatNowUnit();

  InventoryReceiptManualProductControllerProvider get _provider {
    return inventoryReceiptManualProductControllerProvider(widget.config);
  }

  InventoryReceiptManualProductController get _controller {
    return ref.read(_provider.notifier);
  }

  @override
  void initState() {
    super.initState();
    _voiceSearchService = ref.read(voiceSearchServiceProvider);
    _searchController = TextEditingController();
    _nameController = TextEditingController();
    _brandController = TextEditingController();
    _weightAmountController = TextEditingController();
    _eatNowAmountController = TextEditingController(
      text: widget.initialEatNowAmount,
    );
    _nameController.addListener(_handleNameChanged);
    _brandController.addListener(_handleBrandChanged);
    _weightAmountController.addListener(_handleWeightChanged);
    _kcalController = TextEditingController();
    _saturatedFatController = TextEditingController();
    _polyunsaturatedFatController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _sugarController = TextEditingController();
    _fiberController = TextEditingController();
    _fatController = TextEditingController();
    _saltController = TextEditingController();
    _optionalNutritionValueController = TextEditingController();
    _kcalController.addListener(_handleKcalChanged);
    _saturatedFatController.addListener(_handleSaturatedFatChanged);
    _polyunsaturatedFatController.addListener(_handlePolyunsaturatedFatChanged);
    _proteinController.addListener(_handleProteinChanged);
    _carbsController.addListener(_handleCarbsChanged);
    _sugarController.addListener(_handleSugarChanged);
    _fiberController.addListener(_handleFiberChanged);
    _fatController.addListener(_handleFatChanged);
    _saltController.addListener(_handleSaltChanged);
    _optionalNutritionValueController.addListener(
      _handleOptionalNutritionValueChanged,
    );
    _eatNowAmountController.addListener(_handleEatNowAmountChanged);
    final initialInfoMessage = widget.initialInfoMessage;
    if (initialInfoMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showSnackBar(initialInfoMessage);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didBindProviderState) {
      return;
    }

    _didBindProviderState = true;
    _syncControllers(ref.read(_provider));
    _stateSubscription = ref.listenManual<InventoryReceiptManualProductState>(
      _provider,
      (previous, next) {
        _syncControllers(next);
      },
    );
    final initialRecentItem = widget.initialRecentItem;
    if (!_didScheduleInitialRecentItem && initialRecentItem != null) {
      _didScheduleInitialRecentItem = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _controller.applyRecentItem(initialRecentItem);
      });
    }
  }

  void _syncControllers(InventoryReceiptManualProductState state) {
    _isSyncingControllers = true;
    _replaceControllerText(
      _searchController,
      state.searchQuery,
      collapseSelectionToEnd: true,
    );
    _replaceControllerText(_nameController, state.nameText);
    _replaceControllerText(_brandController, state.brandText);
    _replaceControllerText(_weightAmountController, state.weightAmount);
    _replaceControllerText(_kcalController, state.kcalText);
    _replaceControllerText(_saturatedFatController, state.saturatedFatText);
    _replaceControllerText(
      _polyunsaturatedFatController,
      state.polyunsaturatedFatText,
    );
    _replaceControllerText(_proteinController, state.proteinText);
    _replaceControllerText(_carbsController, state.carbsText);
    _replaceControllerText(_sugarController, state.sugarText);
    _replaceControllerText(_fiberController, state.fiberText);
    _replaceControllerText(_fatController, state.fatText);
    _replaceControllerText(_saltController, state.saltText);
    _replaceControllerText(
      _optionalNutritionValueController,
      state.optionalNutritionValueText,
    );
    _isSyncingControllers = false;
  }

  void _replaceControllerText(
    TextEditingController controller,
    String nextText, {
    bool collapseSelectionToEnd = false,
  }) {
    if (controller.text == nextText) {
      return;
    }

    final selection = collapseSelectionToEnd
        ? TextSelection.collapsed(offset: nextText.length)
        : _clampSelection(controller.selection, nextText.length);

    controller.value = TextEditingValue(
      text: nextText,
      selection: selection,
      composing: TextRange.empty,
    );
  }

  TextSelection _clampSelection(TextSelection selection, int textLength) {
    final baseOffset = selection.baseOffset.clamp(0, textLength);
    final extentOffset = selection.extentOffset.clamp(0, textLength);
    return TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: selection.affinity,
      isDirectional: selection.isDirectional,
    );
  }

  @override
  void dispose() {
    _voiceSearchController.dispose();
    _stateSubscription?.close();
    _searchController.dispose();
    _nameController.removeListener(_handleNameChanged);
    _nameController.dispose();
    _brandController.removeListener(_handleBrandChanged);
    _brandController.dispose();
    _weightAmountController.removeListener(_handleWeightChanged);
    _weightAmountController.dispose();
    _eatNowAmountController.removeListener(_handleEatNowAmountChanged);
    _eatNowAmountController.dispose();
    _kcalController.removeListener(_handleKcalChanged);
    _kcalController.dispose();
    _saturatedFatController.removeListener(_handleSaturatedFatChanged);
    _saturatedFatController.dispose();
    _polyunsaturatedFatController.removeListener(
      _handlePolyunsaturatedFatChanged,
    );
    _polyunsaturatedFatController.dispose();
    _proteinController.removeListener(_handleProteinChanged);
    _proteinController.dispose();
    _carbsController.removeListener(_handleCarbsChanged);
    _carbsController.dispose();
    _sugarController.removeListener(_handleSugarChanged);
    _sugarController.dispose();
    _fiberController.removeListener(_handleFiberChanged);
    _fiberController.dispose();
    _fatController.removeListener(_handleFatChanged);
    _fatController.dispose();
    _saltController.removeListener(_handleSaltChanged);
    _saltController.dispose();
    _optionalNutritionValueController.removeListener(
      _handleOptionalNutritionValueChanged,
    );
    _optionalNutritionValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(_provider);
    final preview = _buildPreviewData();
    final canEatImmediately = _canEatImmediately(state);
    final canSave = _canSave(state);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inventoryReceiptReviewManualDataTitle)),
      body: InventoryReceiptManualProductForm(
        preview: preview,
        searchController: _searchController,
        nameController: _nameController,
        brandController: _brandController,
        isSearching: state.isSearching,
        canSave: canSave,
        isRunningNutritionOcr: state.isRunningNutritionOcr,
        autofocusSearch: widget.autofocusSearch,
        showDetails: state.showDetails,
        searchResults: state.searchResults,
        recentItems: const <InventoryItem>[],
        weightAmountController: _weightAmountController,
        selectedWeightUnit: state.selectedWeightUnit,
        eatNowAmountController: _eatNowAmountController,
        selectedEatNowUnit: _selectedEatNowUnit,
        kcalController: _kcalController,
        saturatedFatController: _saturatedFatController,
        polyunsaturatedFatController: _polyunsaturatedFatController,
        showPolyunsaturatedFatField: state.showPolyunsaturatedFatField,
        fatController: _fatController,
        carbsController: _carbsController,
        sugarController: _sugarController,
        fiberController: _fiberController,
        showFiberField: state.showFiberField,
        proteinController: _proteinController,
        saltController: _saltController,
        canAddOptionalNutrition: state.canAddOptionalNutrition,
        isAddingOptionalNutrition: state.isAddingOptionalNutrition,
        optionalNutritionValueController: _optionalNutritionValueController,
        optionalNutritionUnit: state.optionalNutritionUnit,
        optionalNutritionType: state.resolvedOptionalNutritionType,
        availableOptionalNutritionTypes: state.availableOptionalNutritionTypes,
        errorText: _resolveErrorText(l10n, state.error),
        showEatImmediatelyOption: widget.showEatImmediatelyOption,
        eatImmediately: _eatImmediately && canEatImmediately,
        canEatImmediately: canEatImmediately,
        showEatNowAmountField:
            widget.showEatImmediatelyOption &&
            _eatImmediately &&
            canEatImmediately,
        onSearchResultSelected: _handleSearchResultSelected,
        onRecentItemSelected: _controller.applyRecentItem,
        onSearchChanged: _controller.updateSearchQuery,
        voiceSearchService: _voiceSearchService,
        voiceSearchController: _voiceSearchController,
        startVoiceSearchOnMount: widget.initialStartVoiceSearch,
        onScanBarcode: () {
          unawaited(_openBarcodeScanner());
        },
        onWeightUnitChanged: _controller.updateWeightUnit,
        onScanNutritionLabel: state.canScanNutritionLabel
            ? () {
                unawaited(_scanNutritionLabel());
              }
            : null,
        onStartAddingOptionalNutrition:
            _controller.startAddingOptionalNutrition,
        onOptionalNutritionUnitChanged: _controller.updateOptionalNutritionUnit,
        onOptionalNutritionTypeChanged: _controller.updateOptionalNutritionType,
        onApplyOptionalNutrition: _controller.applyOptionalNutrition,
        onCancelOptionalNutrition: _controller.cancelAddingOptionalNutrition,
        onEatImmediatelyChanged: (value) {
          setState(() {
            _eatImmediately = value;
          });
        },
        onEatNowUnitChanged: (value) {
          setState(() {
            _selectedEatNowUnit = value;
          });
        },
        onCancel: _closePage,
        onSave: () {
          unawaited(_save());
        },
      ),
    );
  }

  InventoryReceiptManualProductPreviewData? _buildPreviewData() {
    final preview = _controller.buildPreviewData();
    if (preview == null) {
      return null;
    }
    return InventoryReceiptManualProductPreviewData(
      imageUrl: preview.imageUrl,
      name: preview.name,
      brand: preview.brand,
      weight: preview.weight,
    );
  }

  void _handleSearchResultSelected(OffProductSearchResult product) {
    unawaited(_voiceSearchController.stopVoiceSearchIfNeeded());
    if (widget.autofocusSearch) {
      unawaited(_openSelectedProductEditor(product));
      return;
    }
    _controller.applySearchResult(product);
  }

  Future<void> _openSelectedProductEditor(
    OffProductSearchResult product,
  ) async {
    final config = InventoryReceiptManualProductConfig(
      item: widget.config.item,
      selectedProduct: product,
      includeStoreInSearch: widget.config.includeStoreInSearch,
      includeWeightInSearch: widget.config.includeWeightInSearch,
    );
    final result = await Navigator.of(context)
        .push<InventoryReceiptManualProductResult>(
          _NoAnimationMaterialPageRoute<InventoryReceiptManualProductResult>(
            fullscreenDialog: true,
            builder: (routeContext) {
              return _InventoryReceiptManualProductEditorPage(
                config: config,
                showEatImmediatelyOption: widget.showEatImmediatelyOption,
                onSaved: widget.onSaved,
                initialEatImmediately: _eatImmediately,
                initialEatNowAmount: _eatNowAmountController.text,
                initialEatNowUnit: _selectedEatNowUnit,
              );
            },
          ),
        );
    if (!mounted || result == null) {
      return;
    }

    _closePage(result);
  }

  Future<void> _save() async {
    final state = ref.read(_provider);
    if (state.isRunningNutritionOcr || !_canSave(state)) {
      return;
    }
    final payload = _controller.buildSavePayload();
    if (payload == null) {
      return;
    }

    final eatImmediately =
        widget.showEatImmediatelyOption &&
            _canEatImmediately(ref.read(_provider))
        ? _eatImmediately
        : false;

    final result = InventoryReceiptManualProductResult(
      item: payload.item,
      selectedProduct: payload.selectedProduct,
      selectedGlobalFoodItemId: payload.selectedGlobalFoodItemId,
      requiresGlobalPersistence: payload.requiresGlobalPersistence,
      eatImmediately: eatImmediately,
      eatNowWeight: eatImmediately ? _resolvedEatNowWeight() : null,
    );
    final onSaved = widget.onSaved;
    if (onSaved != null) {
      await onSaved(result);
      return;
    }
    _closePage(result);
  }

  Future<void> _openBarcodeScanner() async {
    await _voiceSearchController.stopVoiceSearchIfNeeded();
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<_ManualBarcodeScanResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 1,
          child: InventoryBarcodeScannerPage(
            title: l10n.inventoryBarcodeMissingPromptScanNow,
            onProductSelected: (candidate, scannedBarcode) async {
              Navigator.of(sheetContext).pop(
                _ManualBarcodeScanResult.selected(
                  candidate: candidate,
                  scannedBarcode: scannedBarcode,
                ),
              );
              return true;
            },
            onProductNotFound: (scannedBarcode) async {
              Navigator.of(sheetContext).pop(
                _ManualBarcodeScanResult.notFound(
                  scannedBarcode: scannedBarcode,
                ),
              );
              return true;
            },
          ),
        );
      },
    );
    if (!mounted || result == null) {
      return;
    }

    switch (result.kind) {
      case _ManualBarcodeScanResultKind.selected:
        final candidate = result.candidate;
        if (candidate == null) {
          return;
        }
        final selectedProduct = candidate.externalProduct;
        if (selectedProduct != null && widget.autofocusSearch) {
          await _openSelectedProductEditor(selectedProduct);
          return;
        }
        if (selectedProduct != null) {
          _controller.applyScannedProduct(selectedProduct);
          return;
        }

        final globalFoodItem = candidate.globalFoodItem;
        if (globalFoodItem == null) {
          return;
        }
        _controller.applyRecentItem(
          _inventoryItemFromBarcodeCandidate(
            baseItem: widget.config.item,
            globalFoodItem: globalFoodItem,
            barcode: result.scannedBarcode ?? candidate.barcode,
          ),
        );
      case _ManualBarcodeScanResultKind.notFound:
        final scannedBarcode = result.scannedBarcode;
        if (scannedBarcode == null || scannedBarcode.isEmpty) {
          return;
        }
        _controller.applyScannedBarcodeOnly(scannedBarcode);
        _showSnackBar(AppLocalizations.of(context)!.inventoryManualAddNotFound);
    }
  }

  Future<void> _scanNutritionLabel() async {
    final outcome = await _controller.scanNutritionLabel();
    if (!mounted) {
      return;
    }
    if (outcome == InventoryReceiptManualProductNutritionScanOutcome.failed) {
      _showSnackBar(AppLocalizations.of(context)!.caloriesOcrFailed);
    }
  }

  bool _canEatImmediately(InventoryReceiptManualProductState state) {
    if (state.hasNutritionInput) {
      return true;
    }
    if (state.selectedProduct?.nutrition?.hasAnyNutritionValue == true) {
      return true;
    }
    if (widget.config.selectedProduct?.nutrition?.hasAnyNutritionValue ==
        true) {
      return true;
    }
    return widget.config.item.nutrition?.hasAnyNutritionValue == true;
  }

  bool _requiresEatNowAmount(InventoryReceiptManualProductState state) {
    return widget.showEatImmediatelyOption &&
        _eatImmediately &&
        _canEatImmediately(state);
  }

  bool _hasValidEatNowAmount() {
    return parseManualProductDouble(_eatNowAmountController.text) != null;
  }

  bool _canSave(InventoryReceiptManualProductState state) {
    if (!state.canSave) {
      return false;
    }
    if (!_requiresEatNowAmount(state)) {
      return true;
    }
    return _hasValidEatNowAmount();
  }

  InventoryAmountUnit _defaultEatNowUnit() {
    final parser = const InventoryAmountParser();
    final rawWeight =
        widget.config.selectedProduct?.packageWeight ??
        widget.config.item.weight;
    final parsed = parser.tryParse(rawWeight: rawWeight, quantity: 1);
    if (parsed != null) {
      return parsed.unit;
    }
    return widget.config.item.amountUnit ?? InventoryAmountUnit.gram;
  }

  String? _resolvedEatNowWeight() {
    final amount = parseManualProductDouble(_eatNowAmountController.text);
    if (amount == null) {
      return null;
    }
    return '${formatManualProductDouble(amount)} '
        '${_weightUnitCode(_selectedEatNowUnit)}';
  }

  String _weightUnitCode(InventoryAmountUnit unit) {
    return switch (unit) {
      InventoryAmountUnit.gram => 'g',
      InventoryAmountUnit.milliliter => 'ml',
      InventoryAmountUnit.piece => 'Stk',
    };
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _closePage<T extends Object?>([T? result]) {
    if (!mounted) {
      return;
    }

    unawaited(_voiceSearchController.cancelVoiceSearch());
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.pop(result);
      return;
    }
    Navigator.of(context).pop(result);
  }

  void _handleWeightChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateWeightAmount(_weightAmountController.text);
  }

  void _handleNameChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateNameText(_nameController.text);
  }

  void _handleBrandChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateBrandText(_brandController.text);
  }

  void _handleKcalChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateKcalText(_kcalController.text);
  }

  void _handleSaturatedFatChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateSaturatedFatText(_saturatedFatController.text);
  }

  void _handlePolyunsaturatedFatChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updatePolyunsaturatedFatText(
      _polyunsaturatedFatController.text,
    );
  }

  void _handleProteinChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateProteinText(_proteinController.text);
  }

  void _handleCarbsChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateCarbsText(_carbsController.text);
  }

  void _handleSugarChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateSugarText(_sugarController.text);
  }

  void _handleFiberChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateFiberText(_fiberController.text);
  }

  void _handleFatChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateFatText(_fatController.text);
  }

  void _handleSaltChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateSaltText(_saltController.text);
  }

  void _handleOptionalNutritionValueChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateOptionalNutritionValueText(
      _optionalNutritionValueController.text,
    );
  }

  void _handleEatNowAmountChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  String? _resolveErrorText(
    AppLocalizations l10n,
    InventoryReceiptManualProductError? error,
  ) {
    return switch (error) {
      null => null,
      InventoryReceiptManualProductError.requiredProductOrNutrition =>
        l10n.inventoryReceiptReviewManualDataRequired,
      InventoryReceiptManualProductError.requiredPackageWeight =>
        '${l10n.inventoryManualAddPackageSizeLabel}: '
            '${l10n.caloriesRequiredField}',
    };
  }
}

InventoryItem _inventoryItemFromBarcodeCandidate({
  required InventoryItem baseItem,
  required GlobalFoodItem globalFoodItem,
  required String barcode,
}) {
  final normalizedBarcode = normalizeBarcode(barcode);
  final weight = globalFoodItem.packageWeight ?? baseItem.weight;
  return baseItem
      .copyWith(
        globalFoodItemId: globalFoodItem.id,
        name: globalFoodItem.name,
        brand: globalFoodItem.brand,
        category: globalFoodItem.category,
        barcode: normalizedBarcode.isEmpty ? barcode : normalizedBarcode,
        imageUrl: globalFoodItem.imageUrl,
        weight: weight,
        foodFingerprint: globalFoodItem.resolvedFoodFingerprint,
        servingSize: globalFoodItem.servingSize,
        servingQuantity: globalFoodItem.servingQuantity,
        servingQuantityUnit: globalFoodItem.servingQuantityUnit,
        nutrition: globalFoodItem.nutrition,
      )
      .withDerivedAmount(
        weight: weight,
        quantity: baseItem.quantity,
        fallbackUnit: baseItem.amountUnit,
      );
}

List<InventoryItem> _buildRecentItems(List<InventoryItem> items) {
  final sortedItems =
      items
          .where((item) => item.canBeSavedToInventory)
          .where((item) => item.name.trim().isNotEmpty)
          .where((item) => item.isManuallyAdded)
          .toList(growable: false)
        ..sort((left, right) => right.entryDate.compareTo(left.entryDate));

  final recentItems = <InventoryItem>[];
  final seenKeys = <String>{};
  for (final item in sortedItems) {
    final key = _recentItemKey(item);
    if (!seenKeys.add(key)) {
      continue;
    }
    recentItems.add(item);
    if (recentItems.length >= _manualProductRecentItemLimit) {
      break;
    }
  }
  return recentItems;
}

String _recentItemKey(InventoryItem item) {
  final globalFoodItemId = item.globalFoodItemId.trim();
  if (globalFoodItemId.isNotEmpty &&
      !isPendingGlobalFoodItemId(globalFoodItemId)) {
    return 'global:$globalFoodItemId';
  }

  final barcode = item.normalizedBarcode;
  if (barcode != null && barcode.isNotEmpty) {
    return 'barcode:$barcode';
  }

  final normalizedName = item.name.trim().toLowerCase();
  final normalizedBrand = (item.brand ?? '').trim().toLowerCase();
  final normalizedWeight = (item.weight ?? '').trim().toLowerCase();
  return 'name:$normalizedName'
      '|brand:$normalizedBrand'
      '|weight:$normalizedWeight';
}
