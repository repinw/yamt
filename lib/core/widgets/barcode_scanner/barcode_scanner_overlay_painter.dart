import 'package:flutter/material.dart';

/// Custom painter for the darkened backdrop, cutout window, corner brackets,
/// and animated laser sweep beam.
class BarcodeScannerOverlayPainter extends CustomPainter {
  /// Creates a barcode scanner overlay painter.
  const BarcodeScannerOverlayPainter({
    required this.windowSize,
    required this.laserProgress,
    required this.isLocked,
    required this.accentColor,
    required this.scale,
  });

  /// Size of the rectangular barcode scanning window.
  final Size windowSize;

  /// Progress (0.0 to 1.0) of the laser sweep within the window.
  final double laserProgress;

  /// Whether a barcode was locked on.
  final bool isLocked;

  /// Active accent color (theme primary or lock-on green).
  final Color accentColor;

  /// Scale factor for lock-on pulse.
  final double scale;

  static const double _cornerRadius = 16;
  static const double _bracketLength = 26;
  static const double _bracketThickness = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    // Cutout center (slightly above middle for natural hand ergonomics)
    final center = Offset(size.width / 2, size.height * 0.40);
    final scaledWidth = windowSize.width * scale;
    final scaledHeight = windowSize.height * scale;
    final windowRect = Rect.fromCenter(
      center: center,
      width: scaledWidth,
      height: scaledHeight,
    );
    final windowRRect = RRect.fromRectAndRadius(
      windowRect,
      const Radius.circular(_cornerRadius),
    );

    // 1. Draw darkened scrim outside the window
    final scrimPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(windowRRect);
    final backgroundPath = Path.combine(
      PathOperation.difference,
      scrimPath,
      cutoutPath,
    );

    final scrimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawPath(backgroundPath, scrimPaint);

    // 2. Draw subtle border around cutout
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: isLocked ? 0.8 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(windowRRect, borderPaint);

    // 3. Draw 4 Corner Brackets
    _drawCornerBrackets(canvas, windowRect, accentColor);

    // 4. Draw Animated Laser Line (only when not locked)
    if (!isLocked) {
      _drawLaserLine(canvas, windowRect, accentColor);
    }
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect, Color color) {
    final bracketPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _bracketThickness
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _bracketThickness + 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (final paint in [shadowPaint, bracketPaint]) {
      // Top-Left
      final tlPath = Path()
        ..moveTo(rect.left, rect.top + _bracketLength)
        ..lineTo(rect.left, rect.top + _cornerRadius)
        ..arcToPoint(
          Offset(rect.left + _cornerRadius, rect.top),
          radius: const Radius.circular(_cornerRadius),
        )
        ..lineTo(rect.left + _bracketLength, rect.top);
      canvas.drawPath(tlPath, paint);

      // Top-Right
      final trPath = Path()
        ..moveTo(rect.right - _bracketLength, rect.top)
        ..lineTo(rect.right - _cornerRadius, rect.top)
        ..arcToPoint(
          Offset(rect.right, rect.top + _cornerRadius),
          radius: const Radius.circular(_cornerRadius),
        )
        ..lineTo(rect.right, rect.top + _bracketLength);
      canvas.drawPath(trPath, paint);

      // Bottom-Left
      final blPath = Path()
        ..moveTo(rect.left, rect.bottom - _bracketLength)
        ..lineTo(rect.left, rect.bottom - _cornerRadius)
        ..arcToPoint(
          Offset(rect.left + _cornerRadius, rect.bottom),
          radius: const Radius.circular(_cornerRadius),
        )
        ..lineTo(rect.left + _bracketLength, rect.bottom);
      canvas.drawPath(blPath, paint);

      // Bottom-Right
      final brPath = Path()
        ..moveTo(rect.right - _bracketLength, rect.bottom)
        ..lineTo(rect.right - _cornerRadius, rect.bottom)
        ..arcToPoint(
          Offset(rect.right, rect.bottom - _cornerRadius),
          radius: const Radius.circular(_cornerRadius),
        )
        ..lineTo(rect.right, rect.bottom - _bracketLength);
      canvas.drawPath(brPath, paint);
    }
  }

  void _drawLaserLine(Canvas canvas, Rect rect, Color color) {
    const verticalMargin = 12.0;
    final usableHeight = rect.height - (verticalMargin * 2);
    final yPos = rect.top + verticalMargin + (usableHeight * laserProgress);

    // Laser glow aura / tail
    const auraHeight = 18.0;
    final auraRect = Rect.fromLTRB(
      rect.left + 8,
      yPos - auraHeight,
      rect.right - 8,
      yPos,
    );
    final auraPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.18),
        ],
      ).createShader(auraRect);
    canvas.drawRect(auraRect, auraPaint);

    // Core laser beam
    final beamRect = Rect.fromLTRB(
      rect.left + 6,
      yPos - 1.5,
      rect.right - 6,
      yPos + 1.5,
    );
    final beamShader = LinearGradient(
      colors: [
        color.withValues(alpha: 0),
        color.withValues(alpha: 0.7),
        Colors.white,
        color.withValues(alpha: 0.7),
        color.withValues(alpha: 0),
      ],
      stops: const [0, 0.25, 0.5, 0.75, 1],
    ).createShader(beamRect);

    final beamPaint = Paint()..shader = beamShader;
    canvas.drawRRect(
      RRect.fromRectAndRadius(beamRect, const Radius.circular(2)),
      beamPaint,
    );

    // Outer glow for the beam
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawLine(
      Offset(rect.left + 16, yPos),
      Offset(rect.right - 16, yPos),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BarcodeScannerOverlayPainter oldDelegate) {
    return oldDelegate.laserProgress != laserProgress ||
        oldDelegate.isLocked != isLocked ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.scale != scale ||
        oldDelegate.windowSize != windowSize;
  }
}
