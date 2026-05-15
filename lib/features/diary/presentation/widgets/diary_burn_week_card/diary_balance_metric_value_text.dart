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
    this.splitUnit = true,
    super.key,
  });

  /// Formatted value, optionally ending in a unit separated by a space.
  final String value;

  /// Color for the numeric part.
  final Color valueColor;

  /// Color for the unit part.
  final Color unitColor;

  /// Font size for the numeric part.
  final double numberFontSize;

  /// Font size for the unit part.
  final double unitFontSize;

  /// Whether to split the last space-separated token as a unit.
  final bool splitUnit;

  @override
  Widget build(BuildContext context) {
    final split = splitUnit ? _splitValueAndUnit(value) : null;
    if (split == null) {
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
            text: split.value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontSize: numberFontSize,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          TextSpan(
            text: ' ${split.unit}',
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

({String value, String unit})? _splitValueAndUnit(String text) {
  final index = text.lastIndexOf(' ');
  if (index <= 0 || index == text.length - 1) {
    return null;
  }
  return (value: text.substring(0, index), unit: text.substring(index + 1));
}
