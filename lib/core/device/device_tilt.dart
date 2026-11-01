import 'dart:math' as math;
import 'dart:ui';

import 'package:sensors_plus/sensors_plus.dart';

/// How far the top edge of a phone in the hand is usually raised.
const double _handPitch = 45 * math.pi / 180;

/// Below this the phone counts as lying on the table again.
const double _tablePitch = 12 * math.pi / 180;

/// Above this the phone counts as picked up again.
const double _pickedUpPitch = 20 * math.pi / 180;

/// How far the phone is tilted from its rest pose, from the direction of
/// gravity, read every [interval]. A phone rests either in the hand, top
/// edge raised about 45°, or flat on the table; the nearer of the two is
/// the rest pose. dx is the tilt to the right (right edge down), dy the
/// tilt toward the user (top edge up), both in radians. A phone held still
/// reads the same tilt.
Stream<Offset> deviceTiltStream({required Duration interval}) {
  var onTable = false;
  return accelerometerEventStream(samplingPeriod: interval).map((event) {
    // The sideways tilt is measured against the whole rest of gravity, so
    // it stays steady when the phone is held upright and z is near zero.
    final roll = -math.atan2(
      event.x,
      math.sqrt(event.y * event.y + event.z * event.z),
    );
    final pitch = math.atan2(event.y, event.z);
    // Two thresholds, so a phone between them does not flip back and forth.
    onTable = onTable ? pitch < _pickedUpPitch : pitch < _tablePitch;
    return Offset(roll, pitch - (onTable ? 0 : _handPitch));
  });
}
