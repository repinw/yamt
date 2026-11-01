import 'package:flutter_test/flutter_test.dart';

/// Long-presses [finder] when the press opens a route, such as a sheet.
///
/// An opening route makes the navigator cancel the pointer that is down. The
/// live binding of integration tests drops that cancel, unless it passes
/// device pointer events on. The long-press recognizer would then keep the
/// press for good, and the same widget could never be long-pressed again.
Future<void> longPressOpeningRoute(WidgetTester tester, Finder finder) async {
  final binding = tester.binding..shouldPropagateDevicePointerEvents = true;
  try {
    await tester.longPress(finder);
  } finally {
    binding.shouldPropagateDevicePointerEvents = false;
  }
}
