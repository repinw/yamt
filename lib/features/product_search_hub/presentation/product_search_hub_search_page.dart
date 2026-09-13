import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_barcode_scanner.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_entry_flow.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_navigation.dart';
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

/// Focused product search route for the product search hub.
class ProductSearchHubSearchPage extends ConsumerStatefulWidget {
  /// Creates a focused product search page.
  const ProductSearchHubSearchPage({
    super.key,
    this.args = const ProductSearchHubRouteArgs.inventory(),
    this.lookupProducts,
  });

  /// Route args.
  final ProductSearchHubRouteArgs args;

  /// Optional lookup override for focused widget tests.
  final ProductSearchHubSearchLookup? lookupProducts;

  @override
  ConsumerState<ProductSearchHubSearchPage> createState() =>
      _ProductSearchHubSearchPageState();
}

class _ProductSearchHubSearchPageState
    extends ConsumerState<ProductSearchHubSearchPage> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final VoiceSearchService _voiceSearchService;
  late final ProductSearchHubSearchCoordinator _searchCoordinator;
  final _voiceSearchController = TextVoiceSearchController();
  final _keyboardDelay = ProductSearchHubSearchDelay();
  var _showFocusedSearchField = false;
  var _isOpeningEntry = false;
  var _isClosing = false;

  @override
  void initState() {
    super.initState();
    final initialQuery = productSearchHubInitialSearchQuery(widget.args) ?? '';
    _searchController = TextEditingController(text: initialQuery);
    _voiceSearchService = ref.read(voiceSearchServiceProvider);
    _searchFocusNode = FocusNode()..addListener(_handleSearchFocusChanged);

    _searchCoordinator = ProductSearchHubSearchCoordinator(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
      searchLookup: ({required query, required limit, store, weight}) {
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
      if (mounted) unawaited(_showSearchFieldAfterTransition());
    });
  }

  @override
  void dispose() {
    _isClosing = true;
    _searchCoordinator.dispose();
    _keyboardDelay.dispose();
    _voiceSearchController.dispose();
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _hideSearchKeyboard();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchFocusChanged() {
    final shouldIgnoreFocusChange =
        _searchFocusNode.hasFocus ||
        _isOpeningEntry ||
        _isClosing ||
        !mounted ||
        !_showFocusedSearchField;
    if (shouldIgnoreFocusChange) return;
    if (_searchController.text.trim().isEmpty) {
      _closeSearchPage();
      return;
    }
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
  }

  Future<void> _showSearchFieldAfterTransition() async {
    await _keyboardDelay.wait(productSearchHubSearchKeyboardRetryDelay);
    if (!mounted || _isClosing) return;
    setState(() => _showFocusedSearchField = true);
    if (!widget.args.autofocusSearchField) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _requestSearchKeyboard(),
    );
    await _keyboardDelay.wait(const Duration(milliseconds: 100));
    _requestSearchKeyboard();
  }

  void _requestSearchKeyboard() {
    if (!mounted || _isClosing || !_showFocusedSearchField) return;
    FocusScope.of(context).requestFocus(_searchFocusNode);
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.show'));
  }

  void _hideSearchKeyboard() {
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
  }

  void _closeSearchPage([Object? result]) {
    popProductSearchHubDeferredRoute(
      context: context,
      isBlocked: _isClosing,
      result: result,
      prepareClose: () {
        _isClosing = true;
        _hideSearchKeyboard();
        setState(() => _showFocusedSearchField = false);
      },
    );
  }

  void _handleSearchChanged(String value) {
    _searchCoordinator.handleSearchChanged(value);
  }

  void _clearSearch() {
    final shouldClose = !_searchFocusNode.hasFocus;
    _searchController.clear();
    _searchCoordinator.clear();
    if (shouldClose) {
      _closeSearchPage();
      return;
    }
    _requestSearchKeyboard();
  }

  void _retrySearch() {
    _searchCoordinator.retrySearch();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _isClosing = true;
          _hideSearchKeyboard();
        }
      },
      child: ProductSearchHubSearchPageContent(
        title: widget.args.title(l10n),
        searchController: _searchController,
        searchFocusNode: _searchFocusNode,
        isSearching: _searchCoordinator.isSearching,
        voiceSearchService: _voiceSearchService,
        voiceSearchController: _voiceSearchController,
        startVoiceSearchOnMount: widget.args.startVoiceSearchOnMount,
        showFocusedSearchField: _showFocusedSearchField,
        autofocusSearchField: widget.args.autofocusSearchField,
        isClosing: _isClosing,
        hasSearchQuery: _searchCoordinator.hasSearchQuery,
        searchResults: _searchCoordinator.results,
        hasSearchFailed: _searchCoordinator.hasFailed,
        onBackPressed: _closeSearchPage,
        onSearchChanged: _handleSearchChanged,
        onClear: _clearSearch,
        onBarcodePressed: _handleBarcodePressed,
        onAiPressed: _handleAiPressed,
        onCreateOwnPressed: _handleCreateOwnPressed,
        onBlankTap: _searchFocusNode.unfocus,
        onRetry: _retrySearch,
        onResultSelected: _closeSearchPage,
        onResultCopied: _handleResultCopied,
      ),
    );
  }

  void _handleResultCopied(OffProductSearchResult product) {
    _closeSearchPage(ProductSearchHubCopyResult(product));
  }

  void _handleBarcodePressed() {
    unawaited(_scanBarcodeIntoSearch());
  }

  Future<void> _scanBarcodeIntoSearch() async {
    _hideSearchKeyboard();
    final scannedBarcode = await openProductSearchHubBarcodeScanner(
      context: context,
    );
    if (!mounted || _isClosing) return;
    if (scannedBarcode == null || scannedBarcode.trim().isEmpty) {
      _requestSearchKeyboard();
      return;
    }
    final barcode = scannedBarcode.trim();
    _searchController.text = barcode;
    _handleSearchChanged(barcode);
  }

  void _handleAiPressed() => _openEditedEntry(
    (l10n) => openProductSearchHubAiEntry(
      context: context,
      l10n: l10n,
      args: widget.args,
      initialPrompt: _searchController.text,
    ),
  );

  void _handleCreateOwnPressed() => _openEditedEntry(
    (l10n) => openProductSearchHubCustomEntry(
      context: context,
      l10n: l10n,
      args: widget.args,
      initialName: _searchController.text,
    ),
  );

  void _openEditedEntry(ProductSearchHubSearchEditedEntryOpener openEntry) {
    unawaited(
      openProductSearchHubSearchEditedEntry(
        context: context,
        isOpeningEntry: _isOpeningEntry,
        isClosing: _isClosing,
        setOpeningEntry: _setOpeningEntry,
        hideKeyboard: _hideSearchKeyboard,
        requestKeyboard: _requestSearchKeyboard,
        closeSearchPage: _closeSearchPage,
        openEntry: openEntry,
      ),
    );
  }

  void _setOpeningEntry(bool value) => setState(() => _isOpeningEntry = value);
}
