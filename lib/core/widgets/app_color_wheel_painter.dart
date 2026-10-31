import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_sizes.dart';

/// Steps of the hue ring, enough for a smooth rainbow.
const _hueStops = 12;

/// The wheel of `AppColorPicker`: hue around, saturation out from the
/// middle, at the brightness of [hsv], with a ring on the picked color.
class AppColorWheelPainter extends CustomPainter {
  /// Creates the painter for [hsv].
  const new(this.hsv);

  /// The picked color; its brightness darkens the whole wheel.
  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas
      ..drawCircle(
        center,
        radius,
        Paint()
          ..shader = SweepGradient(
            colors: [
              for (var stop = 0; stop <= _hueStops; stop++)
                HSVColor.fromAHSV(
                  1,
                  stop * 360 / _hueStops % 360,
                  1,
                  1,
                ).toColor(),
            ],
          ).createShader(rect),
      )
      ..drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [_white, _white.withValues(alpha: 0)],
          ).createShader(rect),
      )
      ..drawCircle(
        center,
        radius,
        Paint()..color = _black.withValues(alpha: 1 - hsv.value),
      );
    final angle = hsv.hue * math.pi / 180;
    final mark =
        center +
        Offset(math.cos(angle), math.sin(angle)) * hsv.saturation * radius;
    const markRadius = AppSizes.colorWheelMarker / 2;
    canvas
      ..drawCircle(mark, markRadius, Paint()..color = hsv.toColor())
      ..drawCircle(
        mark,
        markRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppSizes.colorWheelMarkerRing
          ..color = _white,
      )
      ..drawCircle(
        mark,
        markRadius + AppSizes.colorWheelMarkerRing / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = _black.withValues(alpha: _markerEdge),
      );
  }

  @override
  bool shouldRepaint(AppColorWheelPainter oldDelegate) =>
      oldDelegate.hsv != hsv;
}

// The wheel shows the colors themselves, whatever the theme is.
const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF000000);

/// How dark the thin edge around the marker is, so it shows on white.
const _markerEdge = 0.35;
