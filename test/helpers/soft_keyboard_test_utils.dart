import 'package:flutter_test/flutter_test.dart';

/// Waits until the soft keyboard that `enterText` opened is gone again.
///
/// The emulator keyboard can show up seconds after the key or the tap that
/// closes it, so this waits for it to open and then to close, at most
/// [timeout]. Without a keyboard, as on flutter-tester, it returns after the
/// timeout.
Future<void> waitForKeyboardClosed(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  const step = Duration(milliseconds: 100);
  var seenOpen = false;
  for (var waited = Duration.zero; waited < timeout; waited += step) {
    await tester.pump();
    final isOpen = tester.view.viewInsets.bottom > 0;
    if (isOpen) {
      seenOpen = true;
    } else if (seenOpen) {
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
