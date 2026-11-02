import 'package:flutter_test/flutter_test.dart';

/// Waits until the soft keyboard that `enterText` opened is gone again.
///
/// The emulator keyboard can show up seconds after the key or the tap that
/// closes it, so this waits up to [showTimeout] for it to open and then for
/// it to close, at most [timeout] in all. Both are measured on the clock,
/// because each pump on the emulator also waits for a frame. Without a
/// keyboard, as on flutter-tester or on an emulator whose keyboard never
/// comes up, it returns after [showTimeout].
Future<void> waitForKeyboardClosed(
  WidgetTester tester, {
  Duration showTimeout = const Duration(seconds: 8),
  Duration timeout = const Duration(seconds: 20),
}) async {
  const step = Duration(milliseconds: 100);
  final clock = tester.binding.clock;
  final showEnd = clock.fromNowBy(showTimeout);
  final end = clock.fromNowBy(timeout);
  var seenOpen = false;
  while (clock.now().isBefore(end)) {
    if (tester.view.viewInsets.bottom > 0) {
      seenOpen = true;
    } else if (seenOpen || clock.now().isAfter(showEnd)) {
      break;
    }
    await tester.pump(step);
  }
  expect(
    tester.view.viewInsets.bottom,
    0,
    reason: 'The keyboard is still open after $timeout.',
  );
}
