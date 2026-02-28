import 'dart:async';

/// Serializes asynchronous mutations so that only one operation runs at a
/// time and subsequent operations wait for earlier ones to finish.
class SerializedMutationQueue {
  Future<void> _queue = Future<void>.value();

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
      } catch (error, stackTrace) {
        onError(error, stackTrace);
        result.complete(fallbackValue);
      }
    });
    return result.future;
  }
}
