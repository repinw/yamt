import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/inventory/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_receipt_manual_product_models.dart'
    as inventory_models;
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_barcode_scanner.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_completion_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_entry_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_navigation.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_result_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_selection_state.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_scaffold/product_search_hub_scaffold.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_selection_overlay/'
    'product_search_hub_selection_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Unified product search hub page.
@Dependencies([
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
  manualProductRecentItemsService,
])
class ProductSearchHubPage extends StatefulWidget {
  /// Creates a product search hub page.
  const ProductSearchHubPage({
    super.key,
    this.args = const ProductSearchHubRouteArgs.inventory(),
  });

  /// Route args.
  final ProductSearchHubRouteArgs args;

  @override
  State<ProductSearchHubPage> createState() => _ProductSearchHubPageState();
}

class _ProductSearchHubPageState extends State<ProductSearchHubPage> {
  var _selectionState = const ProductSearchHubSelectionState.empty();
  var _isMutatingSelection = false;

  @override
  void initState() {
    super.initState();
    if (widget.args.initialIntent == ProductSearchHubInitialIntent.launcher) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openInitialIntent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ProductSearchHubScaffold(
      title: widget.args.title(AppLocalizations.of(context)!),
      savedSelections: _selectionState.selections,
      isMutatingSelection: _isMutatingSelection,
      showDiarySourceActions: widget.args.showsDiarySourceActions,
      selectedProductKeys: _selectionState.sourceKeys,
      onSearchTap: _openProductSearch,
      onVoiceSearchTap: _openProductVoiceSearch,
      onBarcodePressed: _openBarcodeScan,
      onAiPressed: _openAiProduct,
      onCreateOwnPressed: _openCustomProduct,
      onRecentlySelectedProductPressed: _addRecentlySelectedProduct,
      onCountPressed: _openSelectedProductsSheet,
      onSubmitPressed: _closeHub,
    );
  }

  void _runWhenIdle(Future<void> Function() action) {
    if (!_isMutatingSelection) {
      unawaited(action());
    }
  }

  void _openProductSearch() => _runWhenIdle(_openProductSearchRoute);

  void _openProductVoiceSearch() => _runWhenIdle(
    () => _openProductSearchRoute(startVoiceSearchOnMount: true),
  );

  Future<void> _openProductSearchRoute({
    String? initialQuery,
    bool startVoiceSearchOnMount = false,
    bool autofocusSearchField = true,
  }) async {
    var routeArgs = widget.args;
    if (initialQuery != null) {
      routeArgs = routeArgs.withInitialQuery(
        initialQuery,
        autofocusSearchField: autofocusSearchField,
      );
    }
    if (startVoiceSearchOnMount) {
      routeArgs = routeArgs.withVoiceSearchOnMount();
    }
    final result = await context.push<Object?>(
      AppRoutes.homeProductSearchHubSearch,
      extra: routeArgs,
    );
    if (!mounted || result == null) {
      return;
    }
    await handleProductSearchHubSearchResult(
      context: context,
      args: widget.args,
      result: result,
      isSourceBlocked: _isSourceBlocked,
      completeResult: _completeEditedResult,
    );
  }

  void _addRecentlySelectedProduct(InventoryItem item) =>
      unawaited(_editAndSaveRecentItem(item));

  Future<void> _editAndSaveRecentItem(InventoryItem item) {
    return editAndSaveProductSearchHubRecentItem(
      context: context,
      args: widget.args,
      item: item,
      isSourceBlocked: _isSourceBlocked,
      completeResult: _completeEditedResult,
    );
  }

  void _openInitialIntent() {
    switch (widget.args.initialIntent) {
      case ProductSearchHubInitialIntent.launcher:
        break;
      case ProductSearchHubInitialIntent.search:
        _openProductSearch();
      case ProductSearchHubInitialIntent.ai:
        _openAiProduct();
      case ProductSearchHubInitialIntent.barcode:
        _openBarcodeScan();
    }
  }

  void _openBarcodeScan() =>
      _runWhenIdle(_openBarcodeScanFlow);

  Future<void> _openBarcodeScanFlow() async {
    final scannedBarcode = await openProductSearchHubBarcodeScanner(
      context: context,
      args: widget.args,
    );
    if (!mounted || scannedBarcode == null || scannedBarcode.trim().isEmpty) {
      return;
    }
    await _openProductSearchRoute(
      initialQuery: scannedBarcode.trim(),
      autofocusSearchField: false,
    );
  }

  void _openAiProduct() =>
      _runWhenIdle(() => _openEntry(openProductSearchHubAiEntry));

  void _openCustomProduct() =>
      _runWhenIdle(() => _openEntry(openProductSearchHubCustomEntry));

  Future<void> _openEntry(ProductSearchHubEntryOpener openEntry) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await openEntry(
      context: context,
      l10n: l10n,
      args: widget.args,
    );
    if (!context.mounted || result == null) {
      return;
    }
    await _completeEditedResult(
      sourceKey: result.sourceKey,
      result: result.result,
    );
  }

  bool _isSourceBlocked(String sourceKey) {
    return _selectionState.containsSourceKey(sourceKey) || _isMutatingSelection;
  }

  Future<void> _completeEditedResult({
    required String sourceKey,
    required inventory_models.InventoryReceiptManualProductResult result,
  }) async {
    if (_isSourceBlocked(sourceKey)) {
      return;
    }
    if (widget.args.mode == ProductSearchHubMode.selection) {
      _closeHub(result);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final container = ProviderScope.containerOf(context, listen: false);

    setState(() => _isMutatingSelection = true);

    final completion = await completeProductSearchHubResult(
      context: context,
      container: container,
      l10n: l10n,
      args: widget.args,
      sourceKey: sourceKey,
      result: result,
      continueDiaryBatch: _selectionState.selections.isNotEmpty,
    );
    if (!context.mounted) {
      return;
    }
    final shouldContinueBatch =
        completion.shouldCloseHub && _selectionState.selections.isNotEmpty;
    setState(() {
      _isMutatingSelection = false;
      final selection = completion.selection;
      if (selection != null &&
          (!completion.shouldCloseHub || shouldContinueBatch)) {
        _selectionState = _selectionState.add(selection);
      }
    });
    if (completion.shouldCloseHub && !shouldContinueBatch) {
      _closeHub(true);
    }
  }

  Future<void> _removeSavedSelection(
    ProductSearchHubSavedSelection selection,
  ) async {
    if (_isMutatingSelection) {
      return;
    }
    setState(() => _isMutatingSelection = true);
    final container = ProviderScope.containerOf(context, listen: false);
    final deleted = await removeProductSearchHubSelection(
      container: container,
      selection: selection,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isMutatingSelection = false;
      if (deleted) {
        _selectionState = _selectionState.removeItemId(selection.item.id);
      }
    });
    if (!deleted) {
      showProductSearchHubSnackBar(
        context,
        AppLocalizations.of(context)!.inventoryItemActionFailed,
      );
    }
  }

  void _openSelectedProductsSheet() => unawaited(
    showProductSearchHubSelectionSheet(
      context: context,
      selections: () => _selectionState.selections,
      isSaving: () => _isMutatingSelection,
      onRemoveSelection: _removeSavedSelection,
    ),
  );

  void _closeHub([Object? result]) {
    popProductSearchHubRoute(
      context: context,
      isBlocked: _isMutatingSelection,
      result: result,
    );
  }
}
