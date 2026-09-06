import 'package:flutter/material.dart';

/// Responsive metric value text that can style the unit separately.
class DiaryBalanceMetricValueText extends StatelessWidget {
  /// Creates metric value text.
  const DiaryBalanceMetricValueText({
    required this.value,
    required this.valueColor,
    required this.unitColor,
    required this.numberFontSize,
    required this.unitFontSize,
    this.unit,
    super.key,
  });

  /// Formatted numeric part or label.
  final String value;

  /// Optional unit or target supplement (e.g. 'kcal' or '/ 2,000').
  final String? unit;

  /// Color for the numeric part.
  final Color valueColor;

  /// Color for the unit part.
  final Color unitColor;

  /// Font size for the numeric part.
  final double numberFontSize;

  /// Font size for the unit part.
  final double unitFontSize;

  @override
  Widget build(BuildContext context) {
    final effectiveUnit = unit?.trim();
    if (effectiveUnit == null || effectiveUnit.isEmpty) {
      return Text(
        value,
        maxLines: 1,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: valueColor,
          fontSize: numberFontSize,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      );
    }

    return RichText(
      maxLines: 1,
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontSize: numberFontSize,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          TextSpan(
            text: ' $effectiveUnit',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: unitColor,
              fontSize: unitFontSize,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
