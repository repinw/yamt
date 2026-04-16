import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_shutdown_controller.g.dart';

/// Tracks whether a global session shutdown is currently in progress.
class SessionShutdownSignal {
  bool _isInProgress = false;
  int _epoch = 0;

  /// Whether shutdown is currently active.
  bool get isInProgress => _isInProgress;

  /// Monotonic shutdown epoch used to detect restarts.
  int get epoch => _epoch;

  /// Returns whether a shutdown happened after `observedEpoch`.
  bool hasShutdownSince(int observedEpoch) {
    return _epoch != observedEpoch;
  }

  /// Marks shutdown as started.
  void begin() {
    _epoch += 1;
    _isInProgress = true;
  }

  /// Marks shutdown as finished.
  void finish() {
    _isInProgress = false;
  }

  /// Resets shutdown state for tests.
  void reset() {
    _epoch = 0;
    finish();
  }
}

/// Resets shutdown signal for tests.
@visibleForTesting
void resetSessionShutdownSignal(SessionShutdownSignal signal) {
  signal.reset();
}

/// Provides global shutdown signal object.
@Riverpod(keepAlive: true)
SessionShutdownSignal sessionShutdownSignal(Ref ref) {
  return SessionShutdownSignal();
}

/// Exposes shutdown state to the app.
@Riverpod(keepAlive: true)
class SessionShutdownController extends _$SessionShutdownController {
  @override
  bool build() {
    return false;
  }

  /// Begins shutdown and flips provider state to `true`.
  void begin() {
    ref.read(sessionShutdownSignalProvider).begin();
    state = true;
  }

  /// Finishes shutdown and flips provider state to `false`.
  void finish() {
    ref.read(sessionShutdownSignalProvider).finish();
    state = false;
  }
}
