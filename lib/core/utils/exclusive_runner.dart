/// Runs one action at a time and drops the calls that come while it runs.
///
/// A tap handler that awaits something before it opens a dialog or a page
/// stays tappable while it waits, so a double tap would open it twice
/// (#703). Run the handler through a runner, and the second tap does
/// nothing until the first one is done.
///
/// Keep one runner in the State that owns the handler, never a global one.
/// The runner is free again when the action completes or fails. A dialog
/// that is removed without a pop never completes its future, but the
/// navigator removes it only together with the page below it, so that State
/// and its runner go with it. A page pushed with go_router can be dropped by
/// a later `go` without completing, so run only the wait before such a push,
/// not the push.
class ExclusiveRunner {
  var _isRunning = false;

  /// Runs [action] unless another action of this runner still runs, and
  /// returns whether it ran.
  Future<bool> run(Future<void> Function() action) async {
    if (_isRunning) {
      return false;
    }
    _isRunning = true;
    try {
      await action();
      return true;
    } finally {
      _isRunning = false;
    }
  }
}
