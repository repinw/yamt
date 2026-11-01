import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_holo_foil_constants.dart';
import 'package:yamt/core/theme/holo_foil_colors.dart';

/// Paints the gold foil over a card: fine gold glitter that flashes at its
/// angle and a soft gold sheen. Both move only with [light].
class HoloFoilPainter extends CustomPainter {
  /// Creates the painter.
  new({required this.light, required this.sparkle, required this.isDark});

  /// Where the light falls, from 0 to 1 across the card.
  final Offset light;

  /// How far the glitter has sparkled on its own, in radians.
  final double sparkle;

  /// Whether the card is dark: bright gold shines on it; a light card gets
  /// deep gold that does not vanish into it.
  final bool isDark;

  /// Glitter dots: place, the two angles at which each flashes, size, and
  /// own sparkle speed.
  static final List<(Offset, double, double, double, double)> _glitter = () {
    final random = math.Random(7);
    return [
      for (var i = 0; i < AppHoloFoil.glitterCount; i++)
        (
          Offset(random.nextDouble(), random.nextDouble()),
          random.nextDouble() * 2 * math.pi,
          random.nextDouble() * 2 * math.pi,
          0.4 + random.nextDouble() * 0.6,
          0.5 + random.nextDouble(),
        ),
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    _paintGlitter(canvas, size);
    _paintSheen(canvas, Offset.zero & size);
  }

  void _paintGlitter(Canvas canvas, Size size) {
    final tilt =
        (light - const Offset(0.5, 0.5)) * AppHoloFoil.glitterTiltTurns;
    final paint = Paint();
    final glitter = isDark
        ? HoloFoilColors.glitter
        : HoloFoilColors.glitterOnLight;
    for (final (at, a, b, r, speed) in _glitter) {
      final turn = sparkle * speed;
      final shine = math.max<double>(
        0,
        math.cos(tilt.dx + a + turn) * math.cos(tilt.dy + b - turn),
      );
      final flash = math.pow(shine, AppHoloFoil.glitterSharpness).toDouble();
      if (flash < AppHoloFoil.glitterCutoff) continue;
      final center = Offset(at.dx * size.width, at.dy * size.height);
      final radius = r * AppHoloFoil.glitterRadius;
      canvas
        ..drawCircle(
          center,
          radius * AppHoloFoil.glitterGlow,
          paint
            ..color = glitter.withValues(
              alpha: flash * AppHoloFoil.glitterGlowOpacity,
            ),
        )
        ..drawCircle(
          center,
          radius,
          paint..color = glitter.withValues(alpha: flash),
        );
    }
  }

  void _paintSheen(Canvas canvas, Rect rect) {
    final size = rect.size * AppHoloFoil.sheenScale;
    final sheenRect =
        Offset(
          (rect.width - size.width) * light.dx,
          (rect.height - size.height) * light.dy,
        ) &
        size;
    final bands = isDark ? HoloFoilColors.sheen : HoloFoilColors.sheenOnLight;
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = isDark ? BlendMode.overlay : BlendMode.multiply
        ..shader = LinearGradient(
          begin: const Alignment(-1, -0.6),
          end: const Alignment(1, 0.6),
          colors: [
            bands.first.withValues(alpha: 0),
            for (final band in bands)
              band.withValues(alpha: AppHoloFoil.sheenOpacity),
            bands.last.withValues(alpha: 0),
          ],
          stops: HoloFoilColors.sheenStops,
        ).createShader(sheenRect),
    );
  }

  @override
  bool shouldRepaint(HoloFoilPainter oldDelegate) =>
      light != oldDelegate.light ||
      sparkle != oldDelegate.sparkle ||
      isDark != oldDelegate.isDark;
}
