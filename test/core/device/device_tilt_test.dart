import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/device_tilt.dart';

import '../../helpers/fake_accelerometer.dart';

const _gravity = 9.81;

double _deg(double radians) => radians * 180 / math.pi;

void main() {
  testWidgets('a phone held at 45 degrees and a flat one both rest at zero', (
    tester,
  ) async {
    final sensor = FakeAccelerometer();
    final tilts = <Offset>[];
    final subscription = deviceTiltStream(
      interval: const Duration(milliseconds: 20),
    ).listen(tilts.add);
    await tester.pump();

    final s = math.sin(math.pi / 4) * _gravity;
    sensor
      ..send(0, s, s)
      ..send(0, 0, _gravity);
    await tester.pump();
    unawaited(subscription.cancel());
    await tester.pump();

    expect(tilts, hasLength(2));
    expect(tilts[0].dx, closeTo(0, 1e-9));
    expect(tilts[0].dy, closeTo(0, 1e-9));
    expect(tilts[1].dx, closeTo(0, 1e-9));
    expect(tilts[1].dy, closeTo(0, 1e-9));
  });

  testWidgets('tilting to the right and toward the user is positive', (
    tester,
  ) async {
    final sensor = FakeAccelerometer();
    final tilts = <Offset>[];
    final subscription = deviceTiltStream(
      interval: const Duration(milliseconds: 20),
    ).listen(tilts.add);
    await tester.pump();

    // Flat on the table, right edge down by 10 degrees.
    const a = 10 * math.pi / 180;
    sensor.send(-math.sin(a) * _gravity, 0, math.cos(a) * _gravity);
    // Raised to 70 degrees: 25 degrees above the hand pose.
    const p = 70 * math.pi / 180;
    sensor.send(0, math.sin(p) * _gravity, math.cos(p) * _gravity);
    await tester.pump();
    unawaited(subscription.cancel());
    await tester.pump();

    expect(_deg(tilts[0].dx), closeTo(10, 1e-6));
    expect(tilts[0].dy, closeTo(0, 1e-9));
    expect(_deg(tilts[1].dy), closeTo(25, 1e-6));
  });

  testWidgets('a phone between the two thresholds keeps its pose', (
    tester,
  ) async {
    final sensor = FakeAccelerometer();
    final tilts = <Offset>[];
    final subscription = deviceTiltStream(
      interval: const Duration(milliseconds: 20),
    ).listen(tilts.add);
    await tester.pump();

    double pitchY(double degrees) =>
        math.sin(degrees * math.pi / 180) * _gravity;
    double pitchZ(double degrees) =>
        math.cos(degrees * math.pi / 180) * _gravity;
    // 16 degrees from the hand: hand pose until it drops below 12.
    sensor
      ..send(0, pitchY(16), pitchZ(16))
      ..send(0, pitchY(5), pitchZ(5))
      // Now on the table: 16 degrees is below 20, so it stays there.
      ..send(0, pitchY(16), pitchZ(16));
    await tester.pump();
    unawaited(subscription.cancel());
    await tester.pump();

    expect(_deg(tilts[0].dy), closeTo(16 - 45, 1e-6));
    expect(_deg(tilts[1].dy), closeTo(5, 1e-6));
    expect(_deg(tilts[2].dy), closeTo(16, 1e-6));
  });
}
