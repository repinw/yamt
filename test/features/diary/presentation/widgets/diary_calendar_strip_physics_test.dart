import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_calendar_strip.dart';

void main() {
  test('snaps slow movement to nearest day boundary', () {
    const itemExtent = 52.0;
    const physics = DiaryDaySnapScrollPhysics(itemExtent: itemExtent);

    final simulation = physics.createBallisticSimulation(
      _metrics(pixels: 75, maxScrollExtent: itemExtent * 20),
      0,
    );

    expect(simulation, isNotNull);
    expect(simulation!.x(1), itemExtent);
    expect(simulation.dx(1), 0);
  });

  test('keeps high velocity fling finite and bounded', () {
    const itemExtent = 52.0;
    final simulation = DiaryDayCoastThenSnapSimulation(
      start: 123,
      velocity: 50000,
      itemExtent: itemExtent,
      minScrollExtent: 0,
      maxScrollExtent: itemExtent * 20,
      tolerance: const Tolerance(distance: 0.01, time: 0.01, velocity: 0.01),
    );

    for (final time in const <double>[0, 0.016, 0.5, 1, 4, 5]) {
      expect(simulation.x(time).isFinite, isTrue);
      expect(simulation.dx(time).isFinite, isTrue);
      expect(simulation.x(time), inInclusiveRange(0, itemExtent * 20));
    }
    expect(simulation.isDone(5), isTrue);
    expect(simulation.x(5) % itemExtent, closeTo(0, 0.0001));
  });

  test('invalid item extents fall back without throwing', () {
    const physics = DiaryDaySnapScrollPhysics(itemExtent: 0);

    final simulation = physics.createBallisticSimulation(
      _metrics(pixels: 75, maxScrollExtent: 1000),
      1200,
    );

    if (simulation != null) {
      expect(simulation.x(0.5).isFinite, isTrue);
      expect(simulation.dx(0.5).isFinite, isTrue);
    }
  });
}

FixedScrollMetrics _metrics({
  required double pixels,
  required double maxScrollExtent,
}) {
  return FixedScrollMetrics(
    minScrollExtent: 0,
    maxScrollExtent: maxScrollExtent,
    pixels: pixels,
    viewportDimension: 390,
    axisDirection: AxisDirection.right,
    devicePixelRatio: 1,
  );
}
