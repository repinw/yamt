import 'dart:math' as math;

/// Tilt, glitter and sheen of the gold foil a card wears as a trophy.
abstract final class AppHoloFoil {
  /// Largest turn of the card, in radians (5°).
  static const double maxCardTilt = 5 * math.pi / 180;

  /// Phone tilt, in radians, that turns the card all the way (25°).
  static const double fullPhoneTilt = 25 * math.pi / 180;

  /// Perspective of the turned card.
  static const double perspective = 0.0012;

  /// Share of the new phone tilt the card follows each frame.
  static const double follow = 0.08;

  /// Gap between card and phone tilt, from -1 to 1, that wakes the frames.
  static const double wakeDistance = 0.01;

  /// Card movement per frame, from -1 to 1, below which the card is still.
  static const double restDistance = 0.001;

  /// Time between two frames of a still card.
  static const Duration idleFrame = Duration(milliseconds: 50);

  /// Speed of the glitter on a still card, in radians per second.
  static const double sparkleIdleSpeed = 0.8;

  /// Extra glitter speed per unit of card movement per frame.
  static const double sparkleMoveBoost = 300;

  /// Time between two tilt readings (30 per second).
  static const Duration tiltInterval = Duration(milliseconds: 33);

  /// Size of the sheen gradient relative to the card.
  static const double sheenScale = 2.6;

  /// Strength of the gold sheen.
  static const double sheenOpacity = 0.35;

  /// Number of glitter dots.
  static const int glitterCount = 70;

  /// Largest radius of a glitter dot.
  static const double glitterRadius = 2.2;

  /// Radius of the glow around a glitter dot relative to the dot.
  static const double glitterGlow = 2.4;

  /// Strength of the glow around a glitter dot.
  static const double glitterGlowOpacity = 0.35;

  /// Turns of a glitter dot's flash angle across the whole tilt range.
  static const double glitterTiltTurns = 10;

  /// Flash below which a glitter dot is not drawn.
  static const double glitterCutoff = 0.02;

  /// How sharply a glitter dot flashes at its angle; higher is shorter.
  static const double glitterSharpness = 6;
}
