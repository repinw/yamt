import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_shutdown_controller.g.dart';

final SessionShutdownSignal sessionShutdownSignal = SessionShutdownSignal();

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
void resetSessionShutdownSignal() {
  sessionShutdownSignal._epoch = 0;
  sessionShutdownSignal.finish();
}

@Riverpod(keepAlive: true)
class SessionShutdownController extends _$SessionShutdownController {
  @override
  bool build() {
    return false;
  }

  void begin() {
    sessionShutdownSignal.begin();
    state = true;
  }

  void finish() {
    sessionShutdownSignal.finish();
    state = false;
  }
}
