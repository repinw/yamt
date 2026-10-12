import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lets the view report an open keyboard, as a device does while a text
/// field has focus, until [closeTestKeyboard] or the end of the test.
Future<void> openTestKeyboard(WidgetTester tester) async {
  tester.view.viewInsets = const FakeViewPadding(bottom: 900);
  addTearDown(tester.view.resetViewInsets);
  await tester.pump();
}

/// Lets the view report a closed keyboard again.
Future<void> closeTestKeyboard(WidgetTester tester) async {
  tester.view.resetViewInsets();
  await tester.pump();
}

/// The Android back button, or a back gesture that no page took.
Future<void> pressSystemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

/// A whole Android predictive back gesture from the left edge.
Future<void> swipeSystemBack(WidgetTester tester) async {
  await startSystemBackGesture(tester);
  await updateSystemBackGesture(tester, 0.5);
  await endSystemBackGesture(tester);
}

/// Starts an Android predictive back gesture at the left edge.
Future<void> startSystemBackGesture(WidgetTester tester) async {
  await _send(tester, 'startBackGesture', _backEvent(0));
  await tester.pump();
}

/// Moves the running back gesture to [progress], from 0 to 1.
Future<void> updateSystemBackGesture(
  WidgetTester tester,
  double progress,
) async {
  await _send(tester, 'updateBackGestureProgress', _backEvent(progress));
  await tester.pump();
}

/// Lifts the finger, which commits the back gesture, or cancels it when
/// [cancel] is set.
Future<void> endSystemBackGesture(
  WidgetTester tester, {
  bool cancel = false,
}) async {
  await _send(tester, cancel ? 'cancelBackGesture' : 'commitBackGesture');
  await tester.pumpAndSettle();
}

Map<String, Object?> _backEvent(double progress) => {
  'touchOffset': [5.0, 300.0],
  'progress': progress,
  'swipeEdge': 0,
};

Future<void> _send(
  WidgetTester tester,
  String method, [
  Map<String, Object?>? arguments,
]) {
  return tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.backGesture.name,
    SystemChannels.backGesture.codec.encodeMethodCall(
      MethodCall(method, arguments),
    ),
    (_) {},
  );
}
