import 'dart:async';

/// Emits [combine] of the latest values of [first] and [second] once both
/// have emitted, and again whenever either emits. Errors of either pass
/// through; the stream ends when both have ended. Stopping does not wait for
/// the two to stop.
Stream<R> combineLatestPair<A, B, R>(
  Stream<A> first,
  Stream<B> second,
  R Function(A first, B second) combine,
) {
  (A,)? a;
  (B,)? b;
  final subscriptions = <StreamSubscription<Object?>>[];
  late final StreamController<R> controller;
  void emit() {
    if ((a, b) case ((final x,)?, (final y,)?)) controller.add(combine(x, y));
  }

  var open = 2;
  void done() {
    if (--open == 0) unawaited(controller.close());
  }

  controller = StreamController<R>(
    onListen: () => subscriptions.addAll([
      first.listen(
        (value) {
          a = (value,);
          emit();
        },
        onError: controller.addError,
        onDone: done,
      ),
      second.listen(
        (value) {
          b = (value,);
          emit();
        },
        onError: controller.addError,
        onDone: done,
      ),
    ]),
    onCancel: () {
      for (final subscription in subscriptions) {
        unawaited(subscription.cancel());
      }
    },
  );
  return controller.stream;
}
