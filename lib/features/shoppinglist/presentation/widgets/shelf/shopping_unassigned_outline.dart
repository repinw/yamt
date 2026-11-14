import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_shopping_constants.dart';

/// Draws a dashed rounded outline around [child] when [visible]: the mark of
/// an entry that has no shelf yet.
class ShoppingUnassignedOutline extends StatelessWidget {
  /// Creates the outline.
  const new({required this.visible, required this.child, super.key});

  /// Whether the outline shows.
  final bool visible;

  /// The outlined content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;
    return CustomPaint(
      foregroundPainter: _DashedOutlinePainter(
        color: Theme.of(context).colorScheme.outline,
      ),
      child: child,
    );
  }
}

class _DashedOutlinePainter extends CustomPainter {
  const new({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = AppShopping.unassignedOutlineWidth / 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - 2 * inset,
            size.height - 2 * inset,
          ),
          const Radius.circular(AppRadius.md - inset),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppShopping.unassignedOutlineWidth;
    for (final metric in outline.computeMetrics()) {
      for (
        var start = 0.0;
        start < metric.length;
        start += AppShopping.unassignedDash * 2
      ) {
        canvas.drawPath(
          metric.extractPath(start, start + AppShopping.unassignedDash),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutlinePainter oldDelegate) =>
      oldDelegate.color != color;
}
