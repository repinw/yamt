import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_config.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_lookup.dart';

/// Coordinates debounce, request lifecycle, and execution for hub search.
class ProductSearchHubSearchCoordinator {
  /// Creates a search coordinator.
  ProductSearchHubSearchCoordinator({
    required this.onStateChanged,
    required this.searchLookup,
  });

  /// Callback to notify host widget of state changes.
  final VoidCallback onStateChanged;

  /// Underlying search lookup implementation.
  final ProductSearchHubSearchLookup searchLookup;

  Timer? _searchDebounce;
  int _activeRequestId = 0;
  String _query = '';
  List<OffProductSearchResult> _results = const [];
  bool _isSearching = false;
  bool _hasFailed = false;
  bool _isDisposed = false;

  /// Current raw search query.
  String get query => _query;

  /// Visible product search results.
  List<OffProductSearchResult> get results => _results;

  /// Whether a search request is currently running.
  bool get isSearching => _isSearching;

  /// Whether the last search attempt failed.
  bool get hasFailed => _hasFailed;

  /// Whether the query length meets minimum requirement.
  bool get hasSearchQuery =>
      _query.trim().length >= productSearchHubSearchMinQueryLength;

  /// Starts initial search if [initialQuery] is valid.
  void startInitialSearch(String initialQuery) {
    _query = initialQuery;
    final normalized = normalizeManualProductText(initialQuery);
    if (normalized == null ||
        normalized.length < productSearchHubSearchMinQueryLength) {
      return;
    }
    _isSearching = true;
    final requestId = ++_activeRequestId;
    _searchDebounce = Timer(productSearchHubSearchDebounceDuration, () {
      unawaited(_executeSearch(normalized, requestId));
    });
  }

  /// Handles search query change with debounce.
  void handleSearchChanged(String value) {
    _query = value;
    _searchDebounce?.cancel();
    final normalized = normalizeManualProductText(value);
    if (normalized == null ||
        normalized.length < productSearchHubSearchMinQueryLength) {
      _activeRequestId++;
      _isSearching = false;
      _hasFailed = false;
      _results = const [];
      onStateChanged();
      return;
    }

    final requestId = ++_activeRequestId;
    _isSearching = true;
    _hasFailed = false;
    onStateChanged();

    _searchDebounce = Timer(productSearchHubSearchDebounceDuration, () {
      unawaited(_executeSearch(normalized, requestId));
    });
  }

  /// Retries searching for current query.
  void retrySearch() {
    final normalized = normalizeManualProductText(_query);
    if (normalized == null ||
        normalized.length < productSearchHubSearchMinQueryLength) {
      return;
    }
    final requestId = ++_activeRequestId;
    unawaited(_executeSearch(normalized, requestId));
  }

  /// Clears results and cancels pending requests.
  void clear() {
    _query = '';
    _searchDebounce?.cancel();
    _activeRequestId++;
    _isSearching = false;
    _hasFailed = false;
    _results = const [];
    onStateChanged();
  }

  Future<void> _executeSearch(String query, int requestId) async {
    if (!_isCurrentRequest(requestId)) {
      return;
    }
    _isSearching = true;
    _hasFailed = false;
    onStateChanged();

    final lookupResult = await searchLookup(
      query: query,
      limit: productSearchHubSearchResultLimit,
    );

    if (!_isCurrentRequest(requestId)) {
      return;
    }

    _isSearching = false;
    _hasFailed = lookupResult.hasFailed;
    _results = lookupResult.results;
    onStateChanged();
  }

  bool _isCurrentRequest(int requestId) {
    return !_isDisposed && requestId == _activeRequestId;
  }

  /// Disposes timers and active requests.
  void dispose() {
    _isDisposed = true;
    _activeRequestId++;
    _searchDebounce?.cancel();
  }
}
