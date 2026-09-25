import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/data/composite_product_search_adapter.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_barcode_scanner.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_entry_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_config.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_context.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_coordinator.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_entry_launcher.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_lookup.dart';
import 'package:yamt/features/product_search_hub/presentation/widgets/'
    'product_search_hub_search_page_content/'
    'product_search_hub_search_page_content.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Search screen of the product search hub.
///
/// It owns the search field, the keyboard, and the initial barcode or AI
/// intent. Picked products go to the hub page through the callbacks.
class ProductSearchHubSearchView extends ConsumerStatefulWidget {
  /// Creates the product search view.
  const new({
    required this.args,
    required this.isBusy,
    required this.selectedProductKeys,
    required this.onBackPressed,
    required this.onProductSelected,
    required this.onRecentItemPressed,
    required this.onEntryResult,
    required this.onInitialIntentCancelled,
    this.bottomOverlay,
    this.lookupProducts,
    super.key,
  });

  /// Route args.
  final ProductSearchHubRouteArgs args;

  /// Whether a picked product is still being saved.
  final bool isBusy;

  /// Source keys of the products selected so far.
  final Set<String> selectedProductKeys;

  /// Back callback.
  final VoidCallback onBackPressed;

  /// Called when a search result is selected.
  final ValueChanged<OffProductSearchResult> onProductSelected;

  /// Called when a recent product is selected.
  final ValueChanged<InventoryItem> onRecentItemPressed;

  /// Called when the AI or custom product editor returns a product.
  final ValueChanged<ProductSearchHubEditedResult> onEntryResult;

  /// Called when the initial barcode scan or AI entry is cancelled.
  final VoidCallback onInitialIntentCancelled;

  /// Selection overlay shown above the bottom edge.
  final Widget? bottomOverlay;

  /// Optional lookup override for widget tests.
  final ProductSearchHubSearchLookup? lookupProducts;

  @override
  ConsumerState<ProductSearchHubSearchView> createState() =>
      _ProductSearchHubSearchViewState();
}

class _ProductSearchHubSearchViewState
    extends ConsumerState<ProductSearchHubSearchView> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final VoiceSearchService _voiceSearchService;
  late final ProductSearchHubSearchCoordinator _searchCoordinator;
  final _voiceSearchController = TextVoiceSearchController();
  final _keyboardDelay = ProductSearchHubSearchDelay();
  var _isOpeningEntry = false;
  var _isDisposed = false;

  @override
  void initState() {
    super.initState();
    final initialQuery = productSearchHubInitialSearchQuery(widget.args) ?? '';
    _searchController = TextEditingController(text: initialQuery);
    _voiceSearchService = ref.read(voiceSearchServiceProvider);
    _searchFocusNode = FocusNode();

    _searchCoordinator = ProductSearchHubSearchCoordinator(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
      searchLookup: ({required query, required limit, store, brand, weight}) {
        return lookupProductSearchHubRouteProducts(
          gateway: ref.read(productSearchGatewayProvider),
          lookupProducts: widget.lookupProducts,
          args: widget.args,
          query: query,
          limit: limit,
        );
      },
    );

    _searchCoordinator.startInitialSearch(initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startInitialIntent());
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchCoordinator.dispose();
    _keyboardDelay.dispose();
    _voiceSearchController.dispose();
    _hideSearchKeyboard();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _startInitialIntent() async {
    switch (widget.args.initialIntent) {
      case ProductSearchHubInitialIntent.launcher:
        return;
      case ProductSearchHubInitialIntent.search:
        if (widget.args.autofocusSearchField) await _showKeyboardAfterRoute();
      case ProductSearchHubInitialIntent.barcode:
        await _scanBarcodeIntoSearch(cancelClosesPage: true);
      case ProductSearchHubInitialIntent.ai:
        _openEditedEntry(_openAiEntry, cancelClosesPage: true);
    }
  }

  // The keyboard request fails while the route transition still runs.
  Future<void> _showKeyboardAfterRoute() async {
    await _keyboardDelay.wait(productSearchHubSearchKeyboardRetryDelay);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _requestSearchKeyboard(),
    );
    await _keyboardDelay.wait(const Duration(milliseconds: 100));
    _requestSearchKeyboard();
  }

  void _requestSearchKeyboard() {
    if (!mounted || _isDisposed) return;
    FocusScope.of(context).requestFocus(_searchFocusNode);
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.show'));
  }

  void _hideSearchKeyboard() {
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
  }

  void _clearSearch() {
    _searchController.clear();
    _searchCoordinator.clear();
    _requestSearchKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ProductSearchHubSearchPageContent(
      title: widget.args.title(l10n),
      searchController: _searchController,
      searchFocusNode: _searchFocusNode,
      isSearching: _searchCoordinator.isSearching,
      voiceSearchService: _voiceSearchService,
      voiceSearchController: _voiceSearchController,
      hasSearchQuery: _searchCoordinator.hasSearchQuery,
      searchResults: _searchCoordinator.results,
      hasSearchFailed: _searchCoordinator.hasFailed,
      selectedProductKeys: widget.selectedProductKeys,
      bottomOverlay: widget.bottomOverlay,
      onBackPressed: widget.onBackPressed,
      onSearchChanged: _searchCoordinator.handleSearchChanged,
      onClear: _clearSearch,
      onBarcodePressed: () => unawaited(_scanBarcodeIntoSearch()),
      onAiPressed: () => _openEditedEntry(_openAiEntry),
      onCreateOwnPressed: () => _openEditedEntry(_openCustomEntry),
      onRetry: _searchCoordinator.retrySearch,
      onResultSelected: widget.onProductSelected,
      onRecentItemPressed: widget.onRecentItemPressed,
    );
  }

  Future<void> _scanBarcodeIntoSearch({bool cancelClosesPage = false}) async {
    if (widget.isBusy) return;
    _hideSearchKeyboard();
    final scannedBarcode = await openProductSearchHubBarcodeScanner(
      context: context,
    );
    if (!mounted) return;
    if (scannedBarcode == null || scannedBarcode.trim().isEmpty) {
      if (cancelClosesPage) {
        widget.onInitialIntentCancelled();
      } else {
        _requestSearchKeyboard();
      }
      return;
    }
    final barcode = scannedBarcode.trim();
    _searchController.text = barcode;
    _searchCoordinator.handleSearchChanged(barcode);
  }

  Future<ProductSearchHubEditedResult?> _openAiEntry(AppLocalizations l10n) {
    return openProductSearchHubAiEntry(
      context: context,
      l10n: l10n,
      args: widget.args,
      initialPrompt: _searchController.text,
    );
  }

  Future<ProductSearchHubEditedResult?> _openCustomEntry(
    AppLocalizations l10n,
  ) {
    return openProductSearchHubCustomEntry(
      context: context,
      l10n: l10n,
      args: widget.args,
      initialName: _searchController.text,
    );
  }

  void _openEditedEntry(
    ProductSearchHubSearchEditedEntryOpener openEntry, {
    bool cancelClosesPage = false,
  }) {
    if (widget.isBusy) return;
    unawaited(
      openProductSearchHubSearchEditedEntry(
        context: context,
        isOpeningEntry: _isOpeningEntry,
        setOpeningEntry: (value) => setState(() => _isOpeningEntry = value),
        hideKeyboard: _hideSearchKeyboard,
        onCancelled: cancelClosesPage
            ? widget.onInitialIntentCancelled
            : _requestSearchKeyboard,
        onResult: widget.onEntryResult,
        openEntry: openEntry,
      ),
    );
  }
}
