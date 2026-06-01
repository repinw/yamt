import 'dart:async';

/// Debounce for focused product search typing.
const productSearchHubSearchDebounceDuration = Duration(milliseconds: 300);

/// Delay before the focused search keyboard is requested.
const productSearchHubSearchKeyboardRetryDelay = Duration(milliseconds: 300);

/// Maximum number of product results shown in focused search.
const productSearchHubSearchResultLimit = 20;

/// Minimum normalized query length before focused search runs.
const productSearchHubSearchMinQueryLength = 2;

/// Small timer helper for focused search keyboard requests.
class ProductSearchHubSearchDelay {
  Timer? _timer;

  /// Waits for [duration], canceling any previous pending wait.
  Future<void> wait(Duration duration) {
    _timer?.cancel();
    final completer = Completer<void>();
    _timer = Timer(duration, completer.complete);
    return completer.future;
  }

  /// Cancels the pending wait.
  void dispose() {
    _timer?.cancel();
  }
}
