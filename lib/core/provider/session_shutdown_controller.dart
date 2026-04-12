import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_shutdown_controller.g.dart';

class SessionShutdownSignal {
  bool _isInProgress = false;
  int _epoch = 0;

  bool get isInProgress => _isInProgress;
  int get epoch => _epoch;

  bool hasShutdownSince(int observedEpoch) {
    return _epoch != observedEpoch;
  }

  void begin() {
    _epoch += 1;
    _isInProgress = true;
  }

  void finish() {
    _isInProgress = false;
  }
}

@visibleForTesting
void resetSessionShutdownSignal(SessionShutdownSignal signal) {
  signal._epoch = 0;
  signal.finish();
}

@Riverpod(keepAlive: true)
SessionShutdownSignal sessionShutdownSignal(Ref ref) {
  return SessionShutdownSignal();
}

@Riverpod(keepAlive: true)
class SessionShutdownController extends _$SessionShutdownController {
  @override
  bool build() {
    return false;
  }

  void begin() {
    ref.read(sessionShutdownSignalProvider).begin();
    state = true;
  }

  void finish() {
    ref.read(sessionShutdownSignalProvider).finish();
    state = false;
  }
}
