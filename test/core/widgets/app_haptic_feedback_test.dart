import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/theme/app_theme.dart';
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

  testWidgets('does not send haptic feedback for canceled touch taps', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject());

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_surfaceKey)),
    );
    await gesture.cancel();
    await tester.pump();

    expect(_hapticCalls(platformCalls), isEmpty);
  });

  testWidgets('does not send haptic feedback for drag gestures', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSubject());

    await tester.drag(find.byKey(_surfaceKey), const Offset(80, 0));
    await tester.pump();

    expect(_hapticCalls(platformCalls), isEmpty);
  });

  testWidgets('sends light haptic feedback for stylus taps', (tester) async {
    await tester.pumpWidget(_buildSubject());

    await _tapWithKind(tester, PointerDeviceKind.stylus);
    await _tapWithKind(tester, PointerDeviceKind.invertedStylus);

    expect(_hapticCalls(platformCalls), hasLength(2));
  });

  testWidgets('tracks simultaneous touch taps independently', (tester) async {
    await tester.pumpWidget(_buildSubject());
    final center = tester.getCenter(find.byKey(_surfaceKey));

    final first = await tester.startGesture(center.translate(-12, 0));
    final second = await tester.startGesture(center.translate(12, 0));
    await first.up();
    await second.up();
    await tester.pump();

    expect(_hapticCalls(platformCalls), hasLength(2));
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

  testWidgets('Material buttons do not add a second feedback call', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(seedColor: Colors.green),
          home: Scaffold(
            body: AppHapticFeedback(
              child: Center(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Save'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(_hapticCalls(platformCalls), hasLength(1));
      expect(_systemSoundCalls(platformCalls), isEmpty);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
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

Iterable<MethodCall> _systemSoundCalls(List<MethodCall> calls) {
  return calls.where((call) => call.method == 'SystemSound.play');
}

Future<void> _tapWithKind(
  WidgetTester tester,
  PointerDeviceKind kind,
) async {
  final gesture = await tester.createGesture(kind: kind);
  final location = tester.getCenter(find.byKey(_surfaceKey));
  await gesture.addPointer(location: location);
  await gesture.down(location);
  await gesture.up();
  await tester.pump();
}
