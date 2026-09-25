import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';

/// Tick band of a food label ruler: long and short ticks, plus a notch at
/// each of [markFractions].
class FoodLabelRulerTicks extends StatelessWidget {
  /// Creates the tick band.
  const new({
    required this.tickColor,
    required this.markColor,
    this.markFractions = const [],
    super.key,
  });

  /// Color of the ticks.
  final Color tickColor;

  /// Color of the notches.
  final Color markColor;

  /// Positions of the notches, from 0 at the left to 1 at the right.
  final List<double> markFractions;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RulerPainter(
        tickColor: tickColor,
        markColor: markColor,
        markFractions: markFractions,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RulerPainter extends CustomPainter {
  const new({
    required this.tickColor,
    required this.markColor,
    required this.markFractions,
  });

  final Color tickColor;
  final Color markColor;
  final List<double> markFractions;

  @override
  void paint(Canvas canvas, Size size) {
    final tick = Paint()
      ..color = tickColor
      ..strokeWidth = 1;
    const count = AppFoodLabel.rulerTickCount;
    for (var i = 0; i <= count; i++) {
      final x = size.width * i / count;
      final long = i % AppFoodLabel.rulerLongTickEvery == 0;
      final top = long ? 0.0 : size.height / 2;
      canvas.drawLine(Offset(x, top), Offset(x, size.height), tick);
    }
    final mark = Paint()
      ..color = markColor
      ..strokeWidth = AppFoodLabel.rulerMarkTick;
    for (final fraction in markFractions) {
      final x = size.width * fraction.clamp(0, 1);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), mark);
    }
  }

  @override
  bool shouldRepaint(_RulerPainter oldDelegate) {
    return oldDelegate.tickColor != tickColor ||
        oldDelegate.markColor != markColor ||
        !listEquals(oldDelegate.markFractions, markFractions);
  }
}
