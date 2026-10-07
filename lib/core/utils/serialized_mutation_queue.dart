import 'dart:async';

/// Serializes asynchronous mutations so that only one operation runs at a
/// time and subsequent operations wait for earlier ones to finish.
class SerializedMutationQueue {
  Future<void> _queue = Future<void>.value();

  /// Runs one mutation after all previously queued mutations complete.
  Future<T> run<T>({
    required Future<T> Function() operation,
    required T fallbackValue,
    required void Function(Object error, StackTrace stackTrace) onError,
  }) {
    final result = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        final value = await operation();
        result.complete(value);
      } on Object catch (error, stackTrace) {
        onError(error, stackTrace);
        result.complete(fallbackValue);
      }
    });
    return result.future;
  }

  /// Runs [operation] after all previously queued mutations complete and
  /// passes its result or error on; a failed mutation does not stop the
  /// ones after it.
  Future<T> enqueue<T>(Future<T> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
