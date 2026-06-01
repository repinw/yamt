import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/widgets/text_voice_search_bar.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_config.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_context.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_entry_flow.dart';
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
  final _voiceSearchController = TextVoiceSearchController();
  final _keyboardDelay = ProductSearchHubSearchDelay();
  Timer? _searchDebounce;
  var _searchQuery = '';
  var _searchResults = const <OffProductSearchResult>[];
  var _isSearching = false;
  var _hasSearchFailed = false;
  var _activeSearchRequestId = 0;
  var _showFocusedSearchField = false;
  var _isOpeningEntry = false;
  var _isClosing = false;

  @override
  void initState() {
    super.initState();
    final initialQuery = productSearchHubInitialSearchQuery(widget.args) ?? '';
    _searchController = TextEditingController(text: initialQuery);
    _searchQuery = initialQuery;
    _voiceSearchService = ref.read(voiceSearchServiceProvider);
    _searchFocusNode = FocusNode()..addListener(_handleSearchFocusChanged);
    _startInitialSearch(initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_showSearchFieldAfterTransition());
    });
  }

  @override
  void dispose() {
    _isClosing = true;
    _searchDebounce?.cancel();
    _keyboardDelay.dispose();
    _voiceSearchController.dispose();
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _hideSearchKeyboard();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchFocusChanged() {
    if (_searchFocusNode.hasFocus ||
        _isOpeningEntry ||
        _isClosing ||
        !mounted ||
        !_showFocusedSearchField) {
      return;
    }
    if (_searchController.text.trim().isEmpty) {
      _closeSearchPage();
      return;
    }
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
  }

  Future<void> _showSearchFieldAfterTransition() async {
    await _keyboardDelay.wait(productSearchHubSearchKeyboardRetryDelay);
    if (!mounted || _isClosing) {
      return;
    }
    setState(() {
      _showFocusedSearchField = true;
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _requestSearchKeyboard(),
    );
    await _keyboardDelay.wait(const Duration(milliseconds: 100));
    _requestSearchKeyboard();
  }

  void _requestSearchKeyboard() {
    if (!mounted || _isClosing || !_showFocusedSearchField) {
      return;
    }
    FocusScope.of(context).requestFocus(_searchFocusNode);
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.show'));
  }

  void _hideSearchKeyboard() {
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
  }

  void _closeSearchPage([Object? result]) {
    final router = GoRouter.maybeOf(context);
    if (_isClosing || router == null || !router.canPop()) {
      return;
    }
    _isClosing = true;
    _hideSearchKeyboard();
    setState(() => _showFocusedSearchField = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && router.canPop()) {
        router.pop<Object?>(result);
      }
    });
  }

  void _handleSearchChanged(String value) {
    _searchQuery = value;
    _searchDebounce?.cancel();
    final query = normalizeManualProductText(value);
    if (query == null || query.length < productSearchHubSearchMinQueryLength) {
      _activeSearchRequestId++;
      setState(() {
        _isSearching = false;
        _hasSearchFailed = false;
        _searchResults = const <OffProductSearchResult>[];
      });
      return;
    }

    final requestId = ++_activeSearchRequestId;
    setState(() {
      _isSearching = true;
      _hasSearchFailed = false;
    });
    _searchDebounce = Timer(productSearchHubSearchDebounceDuration, () {
      unawaited(_runProductSearch(query, requestId));
    });
  }

  void _clearSearch() {
    final shouldClose = !_searchFocusNode.hasFocus;
    _searchController.clear();
    _handleSearchChanged('');
    if (shouldClose) {
      _closeSearchPage();
      return;
    }
    _requestSearchKeyboard();
  }

  void _retrySearch() {
    final query = normalizeManualProductText(_searchController.text);
    if (query == null || query.length < productSearchHubSearchMinQueryLength) {
      return;
    }
    final requestId = ++_activeSearchRequestId;
    unawaited(_runProductSearch(query, requestId));
  }

  void _startInitialSearch(String value) {
    final query = normalizeManualProductText(value);
    if (query == null || query.length < productSearchHubSearchMinQueryLength) {
      return;
    }
    _isSearching = true;
    final requestId = ++_activeSearchRequestId;
    _searchDebounce = Timer(productSearchHubSearchDebounceDuration, () {
      unawaited(_runProductSearch(query, requestId));
    });
  }

  Future<void> _runProductSearch(String query, int requestId) async {
    setState(() {
      _isSearching = true;
      _hasSearchFailed = false;
    });

    final lookupResult = await lookupProductSearchHubRouteProducts(
      repository: ref.read(offProductSearchRepositoryProvider),
      lookupProducts: widget.lookupProducts,
      args: widget.args,
      query: query,
      limit: productSearchHubSearchResultLimit,
    );
    if (!mounted || requestId != _activeSearchRequestId) {
      return;
    }
    setState(() {
      _isSearching = false;
      _hasSearchFailed = lookupResult.hasFailed;
      _searchResults = lookupResult.results;
    });
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
        isSearching: _isSearching,
        voiceSearchService: _voiceSearchService,
        voiceSearchController: _voiceSearchController,
        startVoiceSearchOnMount: widget.args.startVoiceSearchOnMount,
        showFocusedSearchField: _showFocusedSearchField,
        isClosing: _isClosing,
        hasSearchQuery:
            _searchQuery.trim().length >= productSearchHubSearchMinQueryLength,
        searchResults: _searchResults,
        hasSearchFailed: _hasSearchFailed,
        onBackPressed: _closeSearchPage,
        onSearchChanged: _handleSearchChanged,
        onClear: _clearSearch,
        onAiPressed: _handleAiPressed,
        onCreateOwnPressed: _handleCreateOwnPressed,
        onBlankTap: _searchFocusNode.unfocus,
        onRetry: _retrySearch,
        onResultSelected: _closeSearchPage,
      ),
    );
  }

  void _handleAiPressed() => unawaited(
    _openEditedEntry(
      (l10n) => openProductSearchHubSearchAiEntry(
        context: context,
        l10n: l10n,
        args: widget.args,
        initialPrompt: _searchController.text,
      ),
    ),
  );

  void _handleCreateOwnPressed() => unawaited(
    _openEditedEntry(
      (l10n) => openProductSearchHubSearchCustomEntry(
        context: context,
        l10n: l10n,
        args: widget.args,
        initialName: _searchController.text,
      ),
    ),
  );

  Future<void> _openEditedEntry(
    ProductSearchHubSearchEditedEntryOpener openEntry,
  ) {
    return openProductSearchHubSearchEditedEntry(
      context: context,
      isOpeningEntry: _isOpeningEntry,
      isClosing: _isClosing,
      setOpeningEntry: _setOpeningEntry,
      hideKeyboard: _hideSearchKeyboard,
      requestKeyboard: _requestSearchKeyboard,
      closeSearchPage: _closeSearchPage,
      openEntry: openEntry,
    );
  }

  void _setOpeningEntry(bool value) {
    setState(() => _isOpeningEntry = value);
  }
}
