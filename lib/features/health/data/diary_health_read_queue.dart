/// Serializes Health platform reads to avoid overlapping native work.
class DiaryHealthReadQueue {
  Future<void> _tail = Future<void>.value();

  /// Runs [action] after previously queued work completes.
  Future<T> run<T>(Future<T> Function() action) {
    final queuedAction = _tail.then((_) => action());
    _tail = queuedAction.then<void>(
      (_) {},
      onError: (_, _) {},
    );
    return queuedAction;
  }
}
