import 'dart:async';

/// Counts the running watches of a repository that have delivered a value.
///
/// While one runs, the local Firestore cache holds the watched data and
/// follows the server, so a change can start from a cache read.
class DeliveredWatches {
  var _count = 0;

  /// Whether a watch runs that has delivered a value.
  bool get any => _count > 0;

  /// [source], counted from its first value until it ends or its listener
  /// cancels.
  Stream<T> track<T>(Stream<T> source) {
    return Stream<T>.multi((controller) {
      var counted = false;
      void release() {
        if (counted) {
          counted = false;
          _count -= 1;
        }
      }

      final subscription = source.listen(
        (value) {
          if (!counted) {
            counted = true;
            _count += 1;
          }
          controller.add(value);
        },
        onError: controller.addError,
        onDone: () {
          release();
          unawaited(controller.close());
        },
      );
      controller
        ..onPause = subscription.pause
        ..onResume = subscription.resume
        ..onCancel = () {
          release();
          return subscription.cancel();
        };
    });
  }
}
