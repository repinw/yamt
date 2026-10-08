import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/screen_wake_lock.dart';

void main() {
  test('stays on until the last holder releases it', () {
    final switches = <bool>[];
    final lock =
        ScreenWakeLock(toggle: ({required on}) async => switches.add(on))
          ..acquire()
          ..acquire()
          ..release();
    expect(switches, [true]);

    lock.release();
    expect(switches, [true, false]);
  });

  test('ignores a release without a hold', () {
    final switches = <bool>[];
    ScreenWakeLock(toggle: ({required on}) async => switches.add(on))
      ..release()
      ..acquire();

    expect(switches, [true]);
  });

  test('a failed switch does not throw', () async {
    // The test fails if the error escapes as an uncaught async error.
    ScreenWakeLock(toggle: ({required on}) async => throw StateError('no'))
        .acquire();
    await pumpEventQueue();
  });
}
