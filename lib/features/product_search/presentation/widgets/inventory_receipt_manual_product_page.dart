import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page.dart';
import 'package:yamt/features/product_search/data/'
    'manual_product_speech_service.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'inventory_receipt_manual_product_form.dart';
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
    this.eatImmediately = false,
  });

  final InventoryItem item;
  final OffProductSearchResult? selectedProduct;
  final String? selectedGlobalFoodItemId;
  final bool eatImmediately;
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
                  product: candidate,
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
        final product = result.product;
        if (product == null) {
          return;
        }
        await _openEditor(selectedProduct: product);
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
    this.product,
    this.scannedBarcode,
  });

  const _ManualBarcodeScanResult.selected({
    required OffProductSearchResult product,
    required String scannedBarcode,
  }) : this._(
         kind: _ManualBarcodeScanResultKind.selected,
         product: product,
         scannedBarcode: scannedBarcode,
       );

  const _ManualBarcodeScanResult.notFound({required String scannedBarcode})
    : this._(
        kind: _ManualBarcodeScanResultKind.notFound,
        scannedBarcode: scannedBarcode,
      );

  final _ManualBarcodeScanResultKind kind;
  final OffProductSearchResult? product;
  final String? scannedBarcode;
}

class _InventoryReceiptManualProductEditorPageState
    extends ConsumerState<_InventoryReceiptManualProductEditorPage> {
  late final ManualProductSpeechService _speechService;
  late final TextEditingController _searchController;
  late final TextEditingController _weightAmountController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  ProviderSubscription<InventoryReceiptManualProductState>? _stateSubscription;
  bool _didBindProviderState = false;
  bool _didScheduleInitialRecentItem = false;
  bool _isDisposing = false;
  bool _isSyncingControllers = false;
  late bool _eatImmediately = widget.initialEatImmediately;
  bool _isListeningToSpeech = false;
  bool _isStartingVoiceSearch = false;

  InventoryReceiptManualProductControllerProvider get _provider {
    return inventoryReceiptManualProductControllerProvider(widget.config);
  }

  InventoryReceiptManualProductController get _controller {
    return ref.read(_provider.notifier);
  }

  @override
  void initState() {
    super.initState();
    _speechService = ref.read(manualProductSpeechServiceProvider);
    _searchController = TextEditingController();
    _searchController.addListener(_handleSearchChanged);
    _weightAmountController = TextEditingController();
    _weightAmountController.addListener(_handleWeightChanged);
    _kcalController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _kcalController.addListener(_handleKcalChanged);
    _proteinController.addListener(_handleProteinChanged);
    _carbsController.addListener(_handleCarbsChanged);
    _fatController.addListener(_handleFatChanged);
    final initialInfoMessage = widget.initialInfoMessage;
    if (initialInfoMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showSnackBar(initialInfoMessage);
      });
    }
    if (widget.initialStartVoiceSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(_toggleVoiceSearch());
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
    _replaceControllerText(_weightAmountController, state.weightAmount);
    _replaceControllerText(_kcalController, state.kcalText);
    _replaceControllerText(_proteinController, state.proteinText);
    _replaceControllerText(_carbsController, state.carbsText);
    _replaceControllerText(_fatController, state.fatText);
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

    controller.value = TextEditingValue(
      text: nextText,
      selection: collapseSelectionToEnd
          ? TextSelection.collapsed(offset: nextText.length)
          : controller.selection,
      composing: TextRange.empty,
    );
  }

  @override
  void dispose() {
    _isDisposing = true;
    unawaited(_speechService.cancelListening());
    _stateSubscription?.close();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _weightAmountController.removeListener(_handleWeightChanged);
    _weightAmountController.dispose();
    _kcalController.removeListener(_handleKcalChanged);
    _kcalController.dispose();
    _proteinController.removeListener(_handleProteinChanged);
    _proteinController.dispose();
    _carbsController.removeListener(_handleCarbsChanged);
    _carbsController.dispose();
    _fatController.removeListener(_handleFatChanged);
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(_provider);
    final preview = _buildPreviewData();
    final canEatImmediately = _canEatImmediately(state);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inventoryReceiptReviewManualDataTitle)),
      body: InventoryReceiptManualProductForm(
        preview: preview,
        searchController: _searchController,
        isSearching: state.isSearching,
        isListeningToSpeech: _isListeningToSpeech,
        autofocusSearch: widget.autofocusSearch,
        showDetails: state.showDetails,
        searchResults: state.searchResults,
        recentItems: const <InventoryItem>[],
        weightAmountController: _weightAmountController,
        selectedWeightUnit: state.selectedWeightUnit,
        kcalController: _kcalController,
        fatController: _fatController,
        carbsController: _carbsController,
        proteinController: _proteinController,
        errorText: _resolveErrorText(l10n, state.error),
        showEatImmediatelyOption: widget.showEatImmediatelyOption,
        eatImmediately: _eatImmediately && canEatImmediately,
        canEatImmediately: canEatImmediately,
        onSearchResultSelected: _handleSearchResultSelected,
        onRecentItemSelected: _controller.applyRecentItem,
        onScanBarcode: () {
          unawaited(_openBarcodeScanner());
        },
        onToggleVoiceSearch: () {
          unawaited(_toggleVoiceSearch());
        },
        onWeightUnitChanged: _controller.updateWeightUnit,
        onScanNutritionLabel: state.canScanNutritionLabel
            ? () {
                unawaited(_scanNutritionLabel());
              }
            : null,
        onEatImmediatelyChanged: (value) {
          setState(() {
            _eatImmediately = value;
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
    unawaited(_stopVoiceSearchIfNeeded());
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
                initialEatImmediately: _eatImmediately,
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
      eatImmediately: eatImmediately,
    );
    final onSaved = widget.onSaved;
    if (onSaved != null) {
      await onSaved(result);
      return;
    }
    _closePage(result);
  }

  Future<void> _openBarcodeScanner() async {
    await _stopVoiceSearchIfNeeded();
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
                  product: candidate,
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
        final product = result.product;
        if (product == null) {
          return;
        }
        if (widget.autofocusSearch) {
          await _openSelectedProductEditor(product);
          return;
        }
        _controller.applyScannedProduct(product);
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

  void _handleSearchChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateSearchQuery(_searchController.text);
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isStartingVoiceSearch) {
      return;
    }
    if (_isListeningToSpeech) {
      await _stopVoiceSearchIfNeeded();
      return;
    }

    setState(() {
      _isStartingVoiceSearch = true;
    });

    final failure = await _speechService.startListening(
      onResult: _handleSpeechResult,
      onListeningStateChanged: _handleSpeechListeningChanged,
      onError: _handleSpeechError,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _isStartingVoiceSearch = false;
      _isListeningToSpeech = failure == null;
    });

    if (failure != null) {
      final l10n = AppLocalizations.of(context)!;
      _showSnackBar(_resolveSpeechErrorText(l10n, failure));
    }
  }

  Future<void> _stopVoiceSearchIfNeeded() async {
    if (!_isListeningToSpeech && !_speechService.isListening) {
      return;
    }

    await _speechService.stopListening();
    if (!mounted) {
      return;
    }

    setState(() {
      _isListeningToSpeech = false;
      _isStartingVoiceSearch = false;
    });
  }

  void _handleSpeechResult(ManualProductSpeechRecognition result) {
    if (_isDisposing || !mounted) {
      return;
    }
    if (_searchController.text == result.transcript) {
      return;
    }

    _searchController.value = TextEditingValue(
      text: result.transcript,
      selection: TextSelection.collapsed(offset: result.transcript.length),
      composing: TextRange.empty,
    );
  }

  void _handleSpeechListeningChanged(bool isListening) {
    if (_isDisposing || !mounted) {
      return;
    }
    if (_isListeningToSpeech == isListening &&
        (isListening || !_isStartingVoiceSearch)) {
      return;
    }

    setState(() {
      _isListeningToSpeech = isListening;
      if (!isListening) {
        _isStartingVoiceSearch = false;
      }
    });
  }

  void _handleSpeechError(ManualProductSpeechFailure failure) {
    if (_isDisposing || !mounted) {
      return;
    }

    if (_isListeningToSpeech || _isStartingVoiceSearch) {
      setState(() {
        _isListeningToSpeech = false;
        _isStartingVoiceSearch = false;
      });
    }
    _showSnackBar(
      _resolveSpeechErrorText(AppLocalizations.of(context)!, failure),
    );
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

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _closePage<T extends Object?>([T? result]) {
    if (!mounted) {
      return;
    }

    unawaited(_speechService.cancelListening());
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

  void _handleKcalChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateKcalText(_kcalController.text);
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

  void _handleFatChanged() {
    if (_isSyncingControllers) {
      return;
    }
    _controller.updateFatText(_fatController.text);
  }

  String? _resolveErrorText(
    AppLocalizations l10n,
    InventoryReceiptManualProductError? error,
  ) {
    return switch (error) {
      null => null,
      InventoryReceiptManualProductError.requiredProductOrNutrition =>
        l10n.inventoryReceiptReviewManualDataRequired,
    };
  }

  String _resolveSpeechErrorText(
    AppLocalizations l10n,
    ManualProductSpeechFailure failure,
  ) {
    return switch (failure) {
      ManualProductSpeechFailure.unavailable =>
        l10n.inventoryManualAddVoiceSearchUnavailable,
      ManualProductSpeechFailure.permissionDenied =>
        l10n.inventoryManualAddVoiceSearchPermissionDenied,
      ManualProductSpeechFailure.error =>
        l10n.inventoryManualAddVoiceSearchFailed,
    };
  }
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
