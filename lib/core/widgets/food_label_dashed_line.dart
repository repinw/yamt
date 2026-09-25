import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';

/// Full-width dashed line of the food label look, as thick as an outline.
class FoodLabelDashedLine extends StatelessWidget {
  /// Creates a dashed line in [color].
  const new({required this.color, super.key});

  /// Color of the dashes.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(color),
      child: const SizedBox(
        height: AppFoodLabel.outline,
        width: double.infinity,
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += AppFoodLabel.dash * 2) {
      canvas.drawLine(Offset(x, y), Offset(x + AppFoodLabel.dash, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
