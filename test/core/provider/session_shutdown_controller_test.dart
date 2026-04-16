import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';

void main() {
  test('reset clears epoch and in-progress state', () {
    final signal = SessionShutdownSignal()..begin();

    expect(signal.isInProgress, isTrue);
    expect(signal.epoch, 1);

    signal.reset();

    expect(signal.isInProgress, isFalse);
    expect(signal.epoch, 0);
  });
}
