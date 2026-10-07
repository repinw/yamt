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
import 'package:yamt/features/product_search_hub/domain/product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_saved_selection.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_ai_search_result.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_ai_search_page.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_completion_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_editor_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_entry_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/product_search_hub_meal_food_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/product_search_hub_navigation.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_quick_eat_config.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_result_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_save_review_flow.dart';
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

  // Opened for AI, the page shows the AI page itself, so back leaves straight
  // to the caller instead of passing the search page.
  late var _showsAiPage =
      widget.args.initialIntent == ProductSearchHubInitialIntent.ai;
  InventoryItem? _aiDraftItem;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_showsAiPage) {
      _aiDraftItem ??= buildProductSearchHubDraftItem(
        l10n: AppLocalizations.of(context)!,
        sourceItem: widget.args.item,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiDraftItem = _aiDraftItem;
    if (_showsAiPage && aiDraftItem != null) {
      return ManualProductAiSearchPage(
        item: aiDraftItem,
        quickEatConfig: productSearchHubQuickEatConfig(widget.args),
        initialAction: widget.args.initialManualProductAction,
        offersEatInstead: widget.args.offersEatInstead,
        onResult: (result) => _runWhenIdle(() => _completeAiResult(result)),
      );
    }
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

  /// Completes the food from the AI page. When the page stays open, for
  /// example after a canceled save, it continues with the search.
  Future<void> _completeAiResult(ManualProductAiSearchResult result) async {
    await _completeCreatedEntry(productSearchHubAiEntryResult(result));
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    setState(() => _showsAiPage = false);
  }

  /// Completes a created product. Canceling the eat or save dialog that
  /// follows reopens the editor with the entered values.
  Future<void> _completeCreatedEntry(ProductSearchHubEditedResult entry) async {
    ProductSearchHubEditedResult? current = entry;
    while (current != null) {
      final canceled = await _completeEditedResult(
        sourceKey: current.sourceKey,
        result: current.result,
      );
      if (canceled == null || !mounted) {
        return;
      }
      current = await reopenProductSearchHubCreatedEntry(
        context: context,
        args: widget.args,
        result: canceled,
      );
    }
  }

  /// Completes [result] for the route mode. When the user cancels the
  /// follow-up dialog, returns the food with the edits made there.
  Future<inventory_models.InventoryReceiptManualProductResult?>
  _completeEditedResult({
    required String sourceKey,
    required inventory_models.InventoryReceiptManualProductResult result,
  }) async {
    if (_isSourceBlocked(sourceKey)) {
      log(
        'Ignoring product search hub result $sourceKey: already selected '
        'or a save is running (saving=$_isMutatingSelection).',
        name: 'ProductSearchHubPage',
      );
      return null;
    }
    if (widget.args.mode == ProductSearchHubMode.selection) {
      _closeHub(result);
      return null;
    }
    if (widget.args.mode == ProductSearchHubMode.mealFood) {
      final picked = await pickProductSearchHubMealFood(
        context: context,
        args: widget.args,
        result: result,
      );
      final pick = picked.pick;
      if (pick != null && mounted) _closeHub(pick);
      return pick == null ? picked.result : null;
    }
    final reviewed = await reviewProductSearchHubResultBeforeSave(
      context: context,
      args: widget.args,
      result: result,
    );
    if (reviewed.closed || !mounted) return reviewed.result;

    setState(() => _isMutatingSelection = true);

    final completion = await completeProductSearchHubResult(
      context: context,
      args: widget.args,
      sourceKey: sourceKey,
      result: reviewed.result,
      mode: reviewed.mode,
    );
    if (!context.mounted) {
      return null;
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
    return completion.wasCanceled ? reviewed.result : null;
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
