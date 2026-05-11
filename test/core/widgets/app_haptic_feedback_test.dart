import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/widgets/app_haptic_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> platformCalls;

  setUp(() {
    platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('sends light haptic feedback for touch taps', (tester) async {
    await tester.pumpWidget(_buildSubject());

    await tester.tap(find.byKey(_surfaceKey));
    await tester.pump();

    expect(_hapticCalls(platformCalls), hasLength(1));
  });

  testWidgets('does not send haptic feedback for drag gestures', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject());

    await tester.drag(find.byKey(_surfaceKey), const Offset(80, 0));
    await tester.pump();

    expect(_hapticCalls(platformCalls), isEmpty);
  });

  testWidgets('does not send haptic feedback for mouse clicks', (tester) async {
    await tester.pumpWidget(_buildSubject());

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(
      location: tester.getCenter(find.byKey(_surfaceKey)),
    );
    await gesture.down(tester.getCenter(find.byKey(_surfaceKey)));
    await gesture.up();
    await tester.pump();

    expect(_hapticCalls(platformCalls), isEmpty);
  });
}

const _surfaceKey = Key('app-haptic-feedback-surface');

Widget _buildSubject() {
  return const MaterialApp(
    home: Scaffold(
      body: AppHapticFeedback(
        child: ColoredBox(
          key: _surfaceKey,
          color: Colors.white,
          child: SizedBox.expand(),
        ),
      ),
    ),
  );
}

Iterable<MethodCall> _hapticCalls(List<MethodCall> calls) {
  return calls.where(
    (call) =>
        call.method == 'HapticFeedback.vibrate' &&
        call.arguments == 'HapticFeedbackType.lightImpact',
  );
}
