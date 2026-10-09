import 'dart:async';
import 'dart:developer' show log;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/'
    'inventory_receipt_manual_product_models.dart'
    as inventory_models;
import 'package:yamt/features/product_search_hub/presentation/models/'
    'manual_product_ai_search_result.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_ai_search_page.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_editor_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_entry_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/product_search_hub_navigation.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_pick_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_quick_eat_config.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_result_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_lookup.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_view/product_search_hub_search_view.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Product search page shared by inventory, diary, and product pickers.
///
/// The search view handles input. This page completes a picked product for
/// the route mode and closes; one product per visit (#519, #532).
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
  var _isSaving = false;

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
    return ProductSearchHubSearchView(
      args: widget.args,
      isBusy: _isSaving,
      lookupProducts: widget.lookupProducts,
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
    if (!_isSaving) {
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

  // A save in progress blocks the next pick.
  bool _isSourceBlocked(String _) => _isSaving;

  /// Completes the food from the AI page. When the page stays open, for
  /// example after a canceled save, it continues with the search.
  Future<void> _completeAiResult(ManualProductAiSearchResult result) async {
    await _completeCreatedEntry(productSearchHubAiEntryResult(result));
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    setState(() => _showsAiPage = false);
  }

  /// Completes a created product. Canceling the eat or save dialog that
  /// follows reopens the editor with the entered values.
  Future<void> _completeCreatedEntry(ProductSearchHubEditedResult entry) {
    return completeProductSearchHubCreatedEntry(
      context: context,
      args: widget.args,
      entry: entry,
      complete: _completeEditedResult,
    );
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
        'Ignoring product search hub result $sourceKey: a save is running.',
        name: 'ProductSearchHubPage',
      );
      return null;
    }
    return await completeProductSearchHubPick(
      context: context,
      args: widget.args,
      sourceKey: sourceKey,
      result: result,
      setSaving: (isSaving) => setState(() => _isSaving = isSaving),
      close: _closeHub,
    );
  }

  void _closeHub([Object? result]) {
    popProductSearchHubRoute(
      context: context,
      isBlocked: _isSaving,
      result: result,
    );
  }
}
