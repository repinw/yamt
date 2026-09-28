import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_sizes.dart';

/// Small barcode: vertical bars of different widths, sized and colored like
/// an icon.
class BarcodeIcon extends StatelessWidget {
  /// Creates the icon.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = iconTheme.size ?? AppSizes.barcodeIcon;
    // A square box like an icon's, so the word under it lines up with the
    // words of the other tools.
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: CustomPaint(
          size: Size(size, size * AppSizes.barcodeIconAspect),
          painter: _BarcodePainter(
            iconTheme.color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  const new(this.color);

  final Color color;

  /// Left edge and width of each bar, in 24ths of the icon width.
  static const _bars = [
    (2.0, 2.0),
    (5.5, 1.0),
    (8.0, 2.5),
    (12.5, 1.0),
    (15.0, 2.0),
    (18.5, 1.0),
    (20.5, 1.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 24;
    final paint = Paint()..color = color;
    for (final (left, width) in _bars) {
      canvas.drawRect(
        Rect.fromLTWH(left * unit, 0, width * unit, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter oldDelegate) => oldDelegate.color != color;
}
