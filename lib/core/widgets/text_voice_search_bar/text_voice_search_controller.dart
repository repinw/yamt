import 'dart:async';

/// Controller for interacting with a `TextVoiceSearchBar` without a global
/// key.
class TextVoiceSearchController {
  /// Callback the bar attaches to stop an active voice search session.
  Future<void> Function()? stopVoiceSearchIfNeededCallback;

  /// Callback the bar attaches to cancel an active voice search session.
  Future<void> Function()? cancelVoiceSearchCallback;

  /// Stops voice search if a session is active.
  Future<void> stopVoiceSearchIfNeeded() {
    return stopVoiceSearchIfNeededCallback?.call() ?? Future<void>.value();
  }

  /// Cancels any active voice search session.
  Future<void> cancelVoiceSearch() {
    return cancelVoiceSearchCallback?.call() ?? Future<void>.value();
  }

  /// Releases callbacks and cancels any active voice search.
  void dispose() {
    unawaited(cancelVoiceSearch());
    stopVoiceSearchIfNeededCallback = null;
    cancelVoiceSearchCallback = null;
  }

  /// Wires the controller's callbacks to a mounted `TextVoiceSearchBar`.
  void attach({
    required Future<void> Function() stopVoiceSearchIfNeeded,
    required Future<void> Function() cancelVoiceSearch,
  }) {
    stopVoiceSearchIfNeededCallback = stopVoiceSearchIfNeeded;
    cancelVoiceSearchCallback = cancelVoiceSearch;
  }

  /// Clears the callbacks, e.g. when the bar unmounts.
  void detach() {
    stopVoiceSearchIfNeededCallback = null;
    cancelVoiceSearchCallback = null;
  }
}
