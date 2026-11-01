import 'dart:ui' show AccessibilityFeatures;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/holo_foil_card.dart';
import 'package:yamt/core/widgets/holo_foil_painter.dart';

import '../../helpers/fake_accelerometer.dart';

const _childKey = ValueKey<String>('foil-child');

Widget _app({
  required bool enabled,
  VoidCallback? onTap,
  bool tickers = true,
}) => MaterialApp(
  home: Scaffold(
    body: TickerMode(
      enabled: tickers,
      child: Center(
        child: HoloFoilCard(
          enabled: enabled,
          borderRadius: BorderRadius.circular(16),
          surface: Colors.white,
          child: SizedBox(
            width: 200,
            height: 100,
            child: GestureDetector(
              key: _childKey,
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
            ),
          ),
        ),
      ),
    ),
  ),
);

Finder get _foilPaint => find.descendant(
  of: find.byType(HoloFoilCard),
  matching: find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is HoloFoilPainter,
  ),
);

HoloFoilPainter get _painter => _painterOf(_foilPaint);

HoloFoilPainter _painterOf(Finder finder) =>
    (finder.evaluate().single.widget as CustomPaint).painter!
        as HoloFoilPainter;

/// Removes the card, which ends its sensor and timers.
Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  testWidgets('off, there is no foil and the sensor stays unused', (
    tester,
  ) async {
    final sensor = FakeAccelerometer();
    await tester.pumpWidget(_app(enabled: false));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(_childKey), findsOneWidget);
    expect(_foilPaint, findsNothing);
    expect(sensor.listens, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('on, the foil sits over the child, which stays tappable', (
    tester,
  ) async {
    final sensor = FakeAccelerometer();
    var taps = 0;
    await tester.pumpWidget(_app(enabled: true, onTap: () => taps++));
    await tester.pump(const Duration(milliseconds: 200));

    expect(_foilPaint, findsOneWidget);
    expect(sensor.isListening, isTrue);

    await tester.tap(find.byKey(_childKey));
    expect(taps, 1);
    await _dispose(tester);
  });

  testWidgets('a still card sparkles on its own', (tester) async {
    FakeAccelerometer();
    await tester.pumpWidget(_app(enabled: true));
    await tester.pump();
    final before = _painter.sparkle;

    await tester.pump(const Duration(milliseconds: 500));

    expect(_painter.sparkle, greaterThan(before));
    await _dispose(tester);
  });

  testWidgets('the light follows the phone', (tester) async {
    final sensor = FakeAccelerometer();
    await tester.pumpWidget(_app(enabled: true));
    await tester.pump();
    final before = _painter.light;

    // Rolled far to the right of the hand pose.
    sensor.send(-6, 5, 5);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(_painter.light, isNot(before));
    await _dispose(tester);
  });

  testWidgets('switching off stops the sensor and leaves no timer', (
    tester,
  ) async {
    final sensor = FakeAccelerometer();
    await tester.pumpWidget(_app(enabled: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(sensor.isListening, isTrue);

    await tester.pumpWidget(_app(enabled: false));
    await tester.pump();

    expect(sensor.isListening, isFalse);
    expect(sensor.cancels, 1);
    expect(_foilPaint, findsNothing);
    expect(find.byKey(_childKey), findsOneWidget);
    // The test fails on a timer left pending.
  });

  testWidgets('switching on again listens again', (tester) async {
    final sensor = FakeAccelerometer();
    await tester.pumpWidget(_app(enabled: false));
    await tester.pumpWidget(_app(enabled: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(sensor.listens, 1);

    await _dispose(tester);
    expect(sensor.isListening, isFalse);
  });

  testWidgets('an offstage card does not listen to the sensor', (tester) async {
    final sensor = FakeAccelerometer();
    await tester.pumpWidget(_app(enabled: true, tickers: false));
    await tester.pump(const Duration(milliseconds: 200));

    expect(sensor.listens, 0);
    expect(_foilPaint, findsOneWidget);

    await tester.pumpWidget(_app(enabled: true));
    await tester.pump();
    expect(sensor.isListening, isTrue);
    await _dispose(tester);
  });

  testWidgets('with Reduce Motion the foil shows but nothing moves', (
    tester,
  ) async {
    final sensor = FakeAccelerometer();
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const _ReducedMotion();
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(_app(enabled: true));
    await tester.pump(const Duration(milliseconds: 200));

    expect(_foilPaint, findsOneWidget);
    expect(sensor.listens, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  test('the painter repaints for a new light, sparkle or card color', () {
    HoloFoilPainter painter({
      Offset light = const Offset(0.5, 0.5),
      double sparkle = 0,
      bool isDark = false,
    }) => HoloFoilPainter(light: light, sparkle: sparkle, isDark: isDark);

    final base = painter();
    expect(base.shouldRepaint(painter()), isFalse);
    expect(base.shouldRepaint(painter(light: const Offset(0.6, 0.5))), isTrue);
    expect(base.shouldRepaint(painter(sparkle: 0.1)), isTrue);
    expect(base.shouldRepaint(painter(isDark: true)), isTrue);
  });
}

class _ReducedMotion implements AccessibilityFeatures {
  const new();

  @override
  bool get disableAnimations => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => false;
}
