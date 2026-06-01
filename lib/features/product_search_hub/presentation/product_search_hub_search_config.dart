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
  Completer<void>? _completer;

  /// Waits for [duration], completing any previous pending wait.
  Future<void> wait(Duration duration) {
    _completePendingWait();
    final completer = Completer<void>();
    _completer = completer;
    _timer = Timer(duration, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
      if (identical(_completer, completer)) {
        _completer = null;
        _timer = null;
      }
    });
    return completer.future;
  }

  /// Cancels the pending wait.
  void dispose() {
    _completePendingWait();
  }

  void _completePendingWait() {
    _timer?.cancel();
    _timer = null;
    final completer = _completer;
    _completer = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}
