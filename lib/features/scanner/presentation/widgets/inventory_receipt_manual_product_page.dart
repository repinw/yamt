import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_manual_product_form.dart';
import 'package:yamt/features/scanner/provider/'
    'inventory_receipt_manual_product_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class InventoryReceiptManualProductPage extends StatelessWidget {
  const InventoryReceiptManualProductPage({
    super.key,
    required this.item,
    this.selectedProduct,
    this.includeStoreInSearch = true,
    this.includeWeightInSearch = true,
    this.onSaved,
  });

  final InventoryItem item;
  final OffProductSearchResult? selectedProduct;
  final bool includeStoreInSearch;
  final bool includeWeightInSearch;
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

    return _InventoryReceiptManualProductContent(
      config: config,
      onSaved: onSaved,
    );
  }
}

class InventoryReceiptManualProductResult {
  const InventoryReceiptManualProductResult({
    required this.item,
    this.selectedProduct,
  });

  final InventoryItem item;
  final OffProductSearchResult? selectedProduct;
}

class _InventoryReceiptManualProductContent extends ConsumerStatefulWidget {
  const _InventoryReceiptManualProductContent({
    required this.config,
    this.onSaved,
  });

  final InventoryReceiptManualProductConfig config;
  final Future<void> Function(InventoryReceiptManualProductResult result)?
  onSaved;

  @override
  ConsumerState<_InventoryReceiptManualProductContent> createState() =>
      _InventoryReceiptManualProductContentState();
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

class _InventoryReceiptManualProductContentState
    extends ConsumerState<_InventoryReceiptManualProductContent> {
  late final TextEditingController _searchController;
  late final TextEditingController _weightAmountController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  ProviderSubscription<InventoryReceiptManualProductState>? _stateSubscription;
  bool _didBindProviderState = false;
  bool _isSyncingControllers = false;

  InventoryReceiptManualProductControllerProvider get _provider {
    return inventoryReceiptManualProductControllerProvider(widget.config);
  }

  InventoryReceiptManualProductController get _controller {
    return ref.read(_provider.notifier);
  }

  @override
  void initState() {
    super.initState();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventoryReceiptReviewManualDataTitle),
      ),
      body: InventoryReceiptManualProductForm(
        preview: preview,
        searchController: _searchController,
        isSearching: state.isSearching,
        showDetails: state.showDetails,
        searchResults: state.searchResults,
        weightAmountController: _weightAmountController,
        selectedWeightUnit: state.selectedWeightUnit,
        kcalController: _kcalController,
        fatController: _fatController,
        carbsController: _carbsController,
        proteinController: _proteinController,
        errorText: _resolveErrorText(l10n, state.error),
        onSearchResultSelected: _controller.applySearchResult,
        onScanBarcode: () {
          unawaited(_openBarcodeScanner());
        },
        onWeightUnitChanged: _controller.updateWeightUnit,
        onScanNutritionLabel: state.canScanNutritionLabel
            ? () {
                unawaited(_scanNutritionLabel());
              }
            : null,
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

  Future<void> _save() async {
    final payload = _controller.buildSavePayload();
    if (payload == null) {
      return;
    }

    final result = InventoryReceiptManualProductResult(
      item: payload.item,
      selectedProduct: payload.selectedProduct,
    );
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

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
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
}
