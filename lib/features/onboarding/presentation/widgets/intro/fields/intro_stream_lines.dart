import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';

/// Dashed energy lines that drift across the backdrop.
///
/// They are the moving part of the chapter scenery: dashes march along two
/// sweeping curves, one in the chapter accent, one in its counter accent.
class IntroStreamLines extends StatelessWidget {
  /// Creates the stream lines.
  const new({
    required this.progress,
    required this.accent,
    required this.counterAccent,
    super.key,
  });

  /// Marching phase between 0 and 1.
  final double progress;

  /// Accent color of the current chapter.
  final Color accent;

  /// Secondary color of the current chapter.
  final Color counterAccent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StreamLinesPainter(
        progress: progress,
        accent: accent,
        counterAccent: counterAccent,
      ),
      isComplex: true,
    );
  }
}

class _StreamLinesPainter extends CustomPainter {
  const new({
    required this.progress,
    required this.accent,
    required this.counterAccent,
  });

  final double progress;
  final Color accent;
  final Color counterAccent;

  @override
  void paint(Canvas canvas, Size size) {
    _paintCurve(
      canvas,
      size,
      color: accent,
      startY: 0.26,
      controlY: 0.08,
      endY: 0.44,
      strokeWidth: AppIntroLayout.streamStrokeWide,
    );
    _paintCurve(
      canvas,
      size,
      color: counterAccent,
      startY: 0.62,
      controlY: 0.88,
      endY: 0.5,
      strokeWidth: AppIntroLayout.streamStrokeThin,
    );
  }

  void _paintCurve(
    Canvas canvas,
    Size size, {
    required Color color,
    required double startY,
    required double controlY,
    required double endY,
    required double strokeWidth,
  }) {
    final path = Path()
      ..moveTo(-size.width * 0.1, size.height * startY)
      ..cubicTo(
        size.width * 0.3,
        size.height * controlY,
        size.width * 0.7,
        size.height * (controlY + endY) / 2,
        size.width * 1.1,
        size.height * endY,
      );

    final paint = Paint()
      ..color = color.withValues(alpha: AppIntroLayout.streamOpacity)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const dash = AppIntroLayout.streamDash;
    const gap = AppIntroLayout.streamGap;
    const period = dash + gap;
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      var distance = -period * progress;
      while (distance < metric.length) {
        final start = distance.clamp(0.0, metric.length);
        final end = (distance + dash).clamp(0.0, metric.length);
        if (end > start) {
          canvas.drawPath(metric.extractPath(start, end), paint);
        }
        distance += period;
      }
    }
  }

  @override
  bool shouldRepaint(_StreamLinesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.counterAccent != counterAccent;
  }
}
