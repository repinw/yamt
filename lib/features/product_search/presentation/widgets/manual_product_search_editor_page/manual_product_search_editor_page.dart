import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_eat_now_nutrition.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_state.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_barcode_scan_result.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_preview.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_form/manual_product_search_form.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'product_ai_search_page/product_ai_search_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Full manual product editor for search, product details, and nutrition input.
@Dependencies([inventoryManualAddQuickEatConfig])
class InventoryReceiptManualProductEditorPage extends ConsumerStatefulWidget {
  /// Creates a manual product editor page.
  const InventoryReceiptManualProductEditorPage({
    required this.config,
    required this.showEatImmediatelyOption,
    required this.initialAction,
    required this.closeCurrentEditorOnSave,
    this.showActionSelector = true,
    this.onSaved,
    this.autofocusSearch = false,
    this.initialStartVoiceSearch = false,
    this.initialRecentItem,
    this.initialInfoMessage,
    super.key,
  });

  /// Product search configuration.
  final InventoryReceiptManualProductConfig config;

  /// Whether the user can complete the flow as an immediate eat action.
  final bool showEatImmediatelyOption;

  /// Initially selected save action.
  final InventoryReceiptManualProductAction initialAction;

  /// Whether saving should pop only this editor route.
  final bool closeCurrentEditorOnSave;

  /// Whether the form should show the action selector.
  final bool showActionSelector;

  /// Called when the editor saves a product.
  final Future<void> Function(InventoryReceiptManualProductResult result)?
  onSaved;

  /// Whether the search field should autofocus.
  final bool autofocusSearch;

  /// Whether voice search should start when mounted.
  final bool initialStartVoiceSearch;

  /// Optional recent item to apply after mount.
  final InventoryItem? initialRecentItem;

  /// Optional message shown when the editor opens.
  final String? initialInfoMessage;

  @override
  ConsumerState<InventoryReceiptManualProductEditorPage> createState() =>
      _InventoryReceiptManualProductEditorPageState();
}

class _InventoryReceiptManualProductEditorPageState
    extends ConsumerState<InventoryReceiptManualProductEditorPage> {
  late final VoiceSearchService _voiceSearchService;
  final _voiceSearchController = TextVoiceSearchController();
  late final TextEditingController _searchController;
  ProviderSubscription<InventoryReceiptManualProductState>? _stateSubscription;
  bool _didBindProviderState = false;
  bool _didScheduleInitialRecentItem = false;
  late InventoryReceiptManualProductAction _selectedAction =
      widget.initialAction;
  late bool _showActionSelector = widget.showActionSelector;

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
    final quickEatConfig = ref.read(inventoryManualAddQuickEatConfigProvider);
    if (quickEatConfig.quickEatOnly) {
      _selectedAction = InventoryReceiptManualProductAction.eatNow;
    }
    _searchController = TextEditingController();
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
    _syncSearchController(ref.read(_provider));
    _stateSubscription = ref.listenManual<InventoryReceiptManualProductState>(
      _provider,
      (previous, next) {
        _syncSearchController(next);
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

  void _syncSearchController(InventoryReceiptManualProductState state) {
    _replaceControllerText(
      _searchController,
      state.searchQuery,
      collapseSelectionToEnd: true,
    );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(_provider);
    final quickEatConfig = ref.watch(
      inventoryManualAddQuickEatConfigProvider,
    );
    final preview = _buildPreviewData();
    final canSave = _canSave(state);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: InventoryReceiptManualProductForm(
        title: l10n.inventoryManualAddSearchDialogTitle,
        preview: preview,
        searchController: _searchController,
        isSearching: state.isSearching,
        canSave: canSave,
        isRunningNutritionOcr: state.isRunningNutritionOcr,
        autofocusSearch: widget.autofocusSearch,
        showDetails: state.showDetails,
        searchResults: state.searchResults,
        recentItems: const <InventoryItem>[],
        nameText: state.nameText,
        brandText: state.brandText,
        weightAmount: state.weightAmount,
        selectedWeightUnit: state.selectedWeightUnit,
        kcalText: state.kcalText,
        saturatedFatText: state.saturatedFatText,
        polyunsaturatedFatText: state.polyunsaturatedFatText,
        showPolyunsaturatedFatField: state.showPolyunsaturatedFatField,
        fatText: state.fatText,
        carbsText: state.carbsText,
        sugarText: state.sugarText,
        fiberText: state.fiberText,
        showFiberField: state.showFiberField,
        proteinText: state.proteinText,
        saltText: state.saltText,
        canAddOptionalNutrition: state.canAddOptionalNutrition,
        isAddingOptionalNutrition: state.isAddingOptionalNutrition,
        optionalNutritionValueText: state.optionalNutritionValueText,
        optionalNutritionUnit: state.optionalNutritionUnit,
        optionalNutritionType: state.resolvedOptionalNutritionType,
        availableOptionalNutritionTypes: state.availableOptionalNutritionTypes,
        errorText: _resolveErrorText(l10n, state.error),
        onAiSearchTap: () {
          unawaited(_openAiSearchPage());
        },
        canCreateManualDraft: state.canCreateManualDraft,
        onCreateManualDraft: () {
          unawaited(_startManualProductDraft());
        },
        showActionSelector:
            widget.showEatImmediatelyOption &&
            _showActionSelector &&
            !quickEatConfig.quickEatOnly,
        selectedAction: _selectedAction,
        onSearchResultSelected: _handleSearchResultSelected,
        onSearchResultStoreSelected: widget.showEatImmediatelyOption
            ? quickEatConfig.quickEatOnly
                  ? null
                  : _handleSearchResultStoreSelected
            : null,
        onSearchResultEatSelected: widget.showEatImmediatelyOption
            ? _handleSearchResultEatSelected
            : null,
        onRecentItemSelected: _controller.applyRecentItem,
        onSearchChanged: _controller.updateSearchQuery,
        voiceSearchService: _voiceSearchService,
        voiceSearchController: _voiceSearchController,
        startVoiceSearchOnMount: widget.initialStartVoiceSearch,
        onScanBarcode: () {
          unawaited(_openBarcodeScanner());
        },
        onNameChanged: _controller.updateNameText,
        onBrandChanged: _controller.updateBrandText,
        onWeightAmountChanged: _controller.updateWeightAmount,
        onWeightUnitChanged: _controller.updateWeightUnit,
        onKcalChanged: _controller.updateKcalText,
        onFatChanged: _controller.updateFatText,
        onSaturatedFatChanged: _controller.updateSaturatedFatText,
        onCarbsChanged: _controller.updateCarbsText,
        onSugarChanged: _controller.updateSugarText,
        onProteinChanged: _controller.updateProteinText,
        onSaltChanged: _controller.updateSaltText,
        onPolyunsaturatedFatChanged: _controller.updatePolyunsaturatedFatText,
        onFiberChanged: _controller.updateFiberText,
        onScanNutritionLabel: state.canScanNutritionLabel
            ? () {
                unawaited(_scanNutritionLabel());
              }
            : null,
        onStartAddingOptionalNutrition:
            _controller.startAddingOptionalNutrition,
        onOptionalNutritionValueChanged:
            _controller.updateOptionalNutritionValueText,
        onOptionalNutritionUnitChanged: _controller.updateOptionalNutritionUnit,
        onOptionalNutritionTypeChanged: _controller.updateOptionalNutritionType,
        onApplyOptionalNutrition: _controller.applyOptionalNutrition,
        onCancelOptionalNutrition: _controller.cancelAddingOptionalNutrition,
        onActionChanged: (action) {
          setState(() {
            _selectedAction = action;
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
    final quickEatConfig = ref.read(inventoryManualAddQuickEatConfigProvider);
    unawaited(
      _handleSearchResultActionSelected(
        product,
        quickEatConfig.quickEatOnly
            ? InventoryReceiptManualProductAction.eatNow
            : InventoryReceiptManualProductAction.addToInventory,
      ),
    );
  }

  void _handleSearchResultStoreSelected(OffProductSearchResult product) {
    unawaited(
      _handleSearchResultActionSelected(
        product,
        InventoryReceiptManualProductAction.addToInventory,
      ),
    );
  }

  void _handleSearchResultEatSelected(OffProductSearchResult product) {
    unawaited(
      _handleSearchResultActionSelected(
        product,
        InventoryReceiptManualProductAction.eatNow,
      ),
    );
  }

  Future<void> _handleSearchResultActionSelected(
    OffProductSearchResult product,
    InventoryReceiptManualProductAction action,
  ) async {
    final eatNowRequiresNutritionMessage = AppLocalizations.of(
      context,
    )!.inventoryManualAddEatNowRequiresNutrition;
    await _voiceSearchController.stopVoiceSearchIfNeeded();
    if (action == InventoryReceiptManualProductAction.eatNow) {
      final didStartDirectEat = _startDirectEatFlowFromSearchResult(product);
      if (didStartDirectEat) {
        return;
      }
    }
    final quickEatConfig = ref.read(inventoryManualAddQuickEatConfigProvider);
    if (widget.autofocusSearch || quickEatConfig.quickEatOnly) {
      await _openSelectedProductEditor(
        product,
        action: action,
        showActionSelector: false,
        initialInfoMessage: action == InventoryReceiptManualProductAction.eatNow
            ? eatNowRequiresNutritionMessage
            : null,
      );
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedAction = action;
      _showActionSelector = false;
    });
    _controller.applySearchResult(product);
  }

  bool _startDirectEatFlowFromSearchResult(OffProductSearchResult product) {
    final payload = _controller.buildDirectSearchResultPayload(
      product: product,
      action: InventoryReceiptManualProductAction.eatNow,
    );
    if (payload == null) {
      return false;
    }

    _closePage(
      InventoryReceiptManualProductResult(
        item: payload.item,
        action: InventoryReceiptManualProductAction.eatNow,
        selectedProduct: payload.selectedProduct,
        selectedGlobalFoodItemId: payload.selectedGlobalFoodItemId,
        requiresGlobalPersistence: payload.requiresGlobalPersistence,
        globalPackageWeight: payload.globalPackageWeight,
      ),
    );
    return true;
  }

  bool _startDirectEatFlowFromInventoryItem(
    InventoryItem item, {
    required String? selectedGlobalFoodItemId,
    required String? globalPackageWeight,
  }) {
    if (!hasRequiredEatNowNutrition(item.nutrition)) {
      return false;
    }

    _closePage(
      InventoryReceiptManualProductResult(
        item: item,
        action: InventoryReceiptManualProductAction.eatNow,
        selectedGlobalFoodItemId: selectedGlobalFoodItemId,
        requiresGlobalPersistence: false,
        globalPackageWeight: globalPackageWeight,
      ),
    );
    return true;
  }

  Future<void> _openSelectedProductEditor(
    OffProductSearchResult product, {
    required InventoryReceiptManualProductAction action,
    required bool showActionSelector,
    String? initialInfoMessage,
  }) async {
    final config = InventoryReceiptManualProductConfig(
      item: widget.config.item,
      selectedProduct: product,
      includeStoreInSearch: widget.config.includeStoreInSearch,
      includeWeightInSearch: widget.config.includeWeightInSearch,
    );
    final result =
        await pushManualProductSearchPage<InventoryReceiptManualProductResult>(
          context: context,
          args: ManualProductSearchRouteArgs.editor(
            config: config,
            showEatImmediatelyOption: widget.showEatImmediatelyOption,
            initialAction: action,
            closeCurrentEditorOnSave: true,
            showActionSelector: showActionSelector,
            initialInfoMessage: initialInfoMessage,
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

  Future<void> _save() async {
    final state = ref.read(_provider);
    if (state.isRunningNutritionOcr || !_canSave(state)) {
      return;
    }
    final payload = _controller.buildSavePayload(action: _selectedAction);
    if (payload == null) {
      return;
    }

    final result = InventoryReceiptManualProductResult(
      item: payload.item,
      action: _selectedAction,
      selectedProduct: payload.selectedProduct,
      selectedGlobalFoodItemId: payload.selectedGlobalFoodItemId,
      requiresGlobalPersistence: payload.requiresGlobalPersistence,
      globalPackageWeight: payload.globalPackageWeight,
    );
    if (widget.closeCurrentEditorOnSave) {
      _closePage(result);
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
    await _voiceSearchController.stopVoiceSearchIfNeeded();
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final quickEatConfig = ref.read(inventoryManualAddQuickEatConfigProvider);
    final result = await showModalBottomSheet<ManualBarcodeScanResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 1,
          child: InventoryBarcodeScannerPage(
            title: l10n.inventoryManualAddScanBarcodeAction,
            showActionButtons: widget.showEatImmediatelyOption,
            onProductSelected: (candidate, scannedBarcode, action) async {
              sheetContext.pop(
                ManualBarcodeScanResult.selected(
                  candidate: candidate,
                  scannedBarcode: scannedBarcode,
                  action: action,
                ),
              );
              return true;
            },
            onProductNotFound: (scannedBarcode) async {
              sheetContext.pop(
                ManualBarcodeScanResult.notFound(
                  scannedBarcode: scannedBarcode,
                ),
              );
              return true;
            },
            onCreateManualProduct: (scannedBarcode) async {
              sheetContext.pop(
                ManualBarcodeScanResult.manual(
                  scannedBarcode: scannedBarcode,
                ),
              );
              return true;
            },
            eatOnly: quickEatConfig.quickEatOnly,
          ),
        );
      },
    );
    if (!mounted || result == null) {
      return;
    }

    switch (result.kind) {
      case ManualBarcodeScanResultKind.selected:
        final candidate = result.candidate;
        if (candidate == null) {
          return;
        }
        final action = manualProductActionFromBarcodeAction(result.action);
        final selectedProduct = candidate.externalProduct;
        if (selectedProduct != null &&
            action == InventoryReceiptManualProductAction.eatNow &&
            _startDirectEatFlowFromSearchResult(selectedProduct)) {
          return;
        }
        if (selectedProduct != null &&
            (widget.autofocusSearch || quickEatConfig.quickEatOnly)) {
          await _openSelectedProductEditor(
            selectedProduct,
            action: action,
            showActionSelector: false,
            initialInfoMessage:
                action == InventoryReceiptManualProductAction.eatNow
                ? AppLocalizations.of(
                    context,
                  )!.inventoryManualAddEatNowRequiresNutrition
                : null,
          );
          return;
        }
        if (selectedProduct != null) {
          if (mounted) {
            setState(() {
              _selectedAction = action;
              _showActionSelector = false;
            });
          }
          _controller.applyScannedProduct(selectedProduct);
          return;
        }

        final globalFoodItem = candidate.globalFoodItem;
        if (globalFoodItem == null) {
          return;
        }
        final selectedItem = inventoryItemFromBarcodeCandidate(
          baseItem: widget.config.item,
          globalFoodItem: globalFoodItem,
          barcode: result.scannedBarcode ?? candidate.barcode,
        );
        if (action == InventoryReceiptManualProductAction.eatNow &&
            _startDirectEatFlowFromInventoryItem(
              selectedItem,
              selectedGlobalFoodItemId: candidate.globalFoodItemId,
              globalPackageWeight: candidate.packageWeight,
            )) {
          return;
        }
        _controller.applyRecentItem(selectedItem);
        if (mounted) {
          setState(() {
            _selectedAction = action;
            _showActionSelector = false;
          });
        }
      case ManualBarcodeScanResultKind.notFound:
        final scannedBarcode = result.scannedBarcode;
        if (scannedBarcode == null || scannedBarcode.isEmpty) {
          return;
        }
        _controller.applyScannedBarcodeOnly(scannedBarcode);
        _showSnackBar(AppLocalizations.of(context)!.inventoryManualAddNotFound);
      case ManualBarcodeScanResultKind.manual:
        final scannedBarcode = result.scannedBarcode;
        if (scannedBarcode == null || scannedBarcode.isEmpty) {
          return;
        }
        _controller.applyScannedBarcodeOnly(scannedBarcode);
    }
  }

  Future<void> _openAiSearchPage() async {
    await _voiceSearchController.stopVoiceSearchIfNeeded();
    if (!mounted) {
      return;
    }

    final result =
        await pushManualProductSearchPage<ManualProductAiSearchResult>(
          context: context,
          args: ManualProductSearchRouteArgs.aiSearch(
            item: widget.config.item,
            initialPrompt: _searchController.text,
            showEatImmediatelyOption: widget.showEatImmediatelyOption,
            initialAction: _selectedAction,
          ),
        );
    if (!mounted || result == null) {
      return;
    }

    final wrappedResult = InventoryReceiptManualProductResult(
      item: result.item,
      action: result.action,
      globalPackageWeight: result.globalPackageWeight,
      skipMissingBarcodePrompt: true,
      eatSelection: result.eatSelection,
    );
    if (widget.closeCurrentEditorOnSave) {
      _closePage(wrappedResult);
      return;
    }
    final onSaved = widget.onSaved;
    if (onSaved != null) {
      await onSaved(wrappedResult);
      return;
    }
    _closePage(wrappedResult);
  }

  Future<void> _startManualProductDraft() async {
    final controller = _controller;
    await _voiceSearchController.stopVoiceSearchIfNeeded();
    if (!mounted) {
      return;
    }
    controller.startManualProductDraft();
  }

  Future<void> _scanNutritionLabel() async {
    final outcome = await _controller.scanNutritionLabel();
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    switch (outcome) {
      case InventoryReceiptManualProductNutritionScanOutcome.applied:
      case InventoryReceiptManualProductNutritionScanOutcome.canceled:
      case InventoryReceiptManualProductNutritionScanOutcome.missingBarcode:
        return;
      case InventoryReceiptManualProductNutritionScanOutcome.failed:
        _showSnackBar(l10n.caloriesOcrFailed);
      case InventoryReceiptManualProductNutritionScanOutcome.appCheckThrottled:
        _showSnackBar(l10n.caloriesOcrAppCheckThrottled);
    }
  }

  bool _canEatNow(InventoryReceiptManualProductState state) {
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

  bool _canSave(InventoryReceiptManualProductState state) {
    if (!state.hasBarcode && !state.hasNutritionInput) {
      return false;
    }
    if (_selectedAction == InventoryReceiptManualProductAction.eatNow) {
      return _canEatNow(state);
    }
    return state.hasPackageWeightInput;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _closePage<T extends Object?>([T? result]) {
    if (!mounted) {
      return;
    }

    unawaited(_voiceSearchController.cancelVoiceSearch());
    popManualProductSearchPage(context, result);
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
