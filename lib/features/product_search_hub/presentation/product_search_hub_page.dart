import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart'
    as inventory_models;
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_completion_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_entry_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_navigation.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_result_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_lookup.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_selection_state.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_view/product_search_hub_search_view.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_selection_overlay/'
    'product_search_hub_selection_overlay.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_selection_overlay/'
    'product_search_hub_selection_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Product search page shared by inventory, diary, and product pickers.
///
/// The search view handles input. This page completes picked products for the
/// route mode and keeps the products saved so far.
class ProductSearchHubPage extends StatefulWidget {
  /// Creates a product search hub page.
  const new({
    super.key,
    this.args = const ProductSearchHubRouteArgs.inventory(),
    this.lookupProducts,
  });

  /// Route args.
  final ProductSearchHubRouteArgs args;

  /// Optional lookup override for widget tests.
  final ProductSearchHubSearchLookup? lookupProducts;

  @override
  State<ProductSearchHubPage> createState() => _ProductSearchHubPageState();
}

class _ProductSearchHubPageState extends State<ProductSearchHubPage> {
  var _selectionState = const ProductSearchHubSelectionState.empty();
  var _isMutatingSelection = false;

  @override
  Widget build(BuildContext context) {
    final selections = _selectionState.selections;

    return ProductSearchHubSearchView(
      args: widget.args,
      isBusy: _isMutatingSelection,
      lookupProducts: widget.lookupProducts,
      selectedProductKeys: _selectionState.sourceKeys,
      bottomOverlay: selections.isEmpty
          ? null
          : ProductSearchHubSelectionOverlay(
              productCount: selections.length,
              isSaving: _isMutatingSelection,
              onCountPressed: _openSelectedProductsSheet,
              onSubmitPressed: _closeHub,
            ),
      // Back never waits for a save: an offline write may not finish.
      onBackPressed: () =>
          popProductSearchHubRoute(context: context, isBlocked: false),
      onProductSelected: _openProduct,
      onRecentItemPressed: _openRecentItem,
      onEntryResult: (entry) =>
          _runWhenIdle(() => _completeCreatedEntry(entry)),
      onInitialIntentCancelled: _closeHub,
    );
  }

  void _runWhenIdle(Future<void> Function() action) {
    if (!_isMutatingSelection) {
      unawaited(action());
    }
  }

  void _openProduct(OffProductSearchResult product) => _runWhenIdle(
    () => editAndSaveProductSearchHubProduct(
      context: context,
      args: widget.args,
      product: product,
      isSourceBlocked: _isSourceBlocked,
      completeResult: _completeEditedResult,
    ),
  );

  void _openRecentItem(InventoryItem item) => _runWhenIdle(
    () => editAndSaveProductSearchHubRecentItem(
      context: context,
      args: widget.args,
      item: item,
      isSourceBlocked: _isSourceBlocked,
      completeResult: _completeEditedResult,
    ),
  );

  bool _isSourceBlocked(String sourceKey) {
    return _selectionState.containsSourceKey(sourceKey) || _isMutatingSelection;
  }

  /// Completes a created product. Canceling the eat or save dialog that
  /// follows reopens the editor with the entered values.
  Future<void> _completeCreatedEntry(ProductSearchHubEditedResult entry) async {
    ProductSearchHubEditedResult? current = entry;
    while (current != null) {
      final wasCanceled = await _completeEditedResult(
        sourceKey: current.sourceKey,
        result: current.result,
      );
      if (!wasCanceled || !mounted) {
        return;
      }
      current = await reopenProductSearchHubCreatedEntry(
        context: context,
        args: widget.args,
        result: current.result,
      );
    }
  }

  /// Completes [result] for the route mode. Returns whether the user canceled
  /// the follow-up dialog.
  Future<bool> _completeEditedResult({
    required String sourceKey,
    required inventory_models.InventoryReceiptManualProductResult result,
  }) async {
    if (_isSourceBlocked(sourceKey)) {
      log(
        'Ignoring product search hub result $sourceKey: already selected '
        'or a save is running (saving=$_isMutatingSelection).',
        name: 'ProductSearchHubPage',
      );
      return false;
    }
    if (widget.args.mode == ProductSearchHubMode.selection) {
      _closeHub(result);
      return false;
    }

    setState(() => _isMutatingSelection = true);

    final completion = await completeProductSearchHubResult(
      context: context,
      args: widget.args,
      sourceKey: sourceKey,
      result: result,
      continueDiaryBatch: _selectionState.selections.isNotEmpty,
    );
    if (!context.mounted) {
      return false;
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
    return completion.wasCanceled;
  }

  Future<void> _removeSavedSelection(
    ProductSearchHubSavedSelection selection,
  ) async {
    if (_isMutatingSelection) {
      return;
    }
    setState(() => _isMutatingSelection = true);
    final deleted = await removeProductSearchHubSelection(
      container: ProviderScope.containerOf(context, listen: false),
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
