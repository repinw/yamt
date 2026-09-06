import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_metric_value_text.dart';

/// Small label/value metric used inside diary balance cards.
class DiaryBalanceMetricTile extends StatelessWidget {
  const DiaryBalanceMetricTile._({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
    required this.unitColor,
    required this.alignment,
    required this.numberFontSize,
    required this.unitFontSize,
    this.unit,
    this.subtitle,
    this.icon,
    this.textAlign,
    this.labelFontSize = 10,
    this.labelFontWeight = FontWeight.w800,
    this.labelValueSpacing = AppSpacing.xs,
    super.key,
  });

  /// Creates a large daily balance metric.
  const DiaryBalanceMetricTile.daily({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
    required Color unitColor,
    required CrossAxisAlignment alignment,
    String? unit,
    double unitFontSize = 13,
    String? subtitle,
    IconData? icon,
    TextAlign? textAlign,
    Key? key,
  }) : this._(
         label: label,
         value: value,
         unit: unit,
         labelColor: labelColor,
         valueColor: valueColor,
         unitColor: unitColor,
         alignment: alignment,
         numberFontSize: 30,
         unitFontSize: unitFontSize,
         subtitle: subtitle,
         icon: icon,
         textAlign: textAlign,
         labelFontWeight: FontWeight.w900,
         key: key,
       );

  /// Creates a compact weekly summary metric.
  const DiaryBalanceMetricTile.weekly({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
    required Color unitColor,
    required CrossAxisAlignment alignment,
    String? unit,
    TextAlign? textAlign,
    Key? key,
  }) : this._(
         label: label,
         value: value,
         unit: unit,
         labelColor: labelColor,
         valueColor: valueColor,
         unitColor: unitColor,
         alignment: alignment,
         numberFontSize: 16,
         unitFontSize: 11,
         textAlign: textAlign,
         labelValueSpacing: AppSpacing.xxs,
         key: key,
       );

  /// Metric label.
  final String label;

  /// Formatted metric value.
  final String value;

  /// Optional unit or target supplement displayed after the value.
  final String? unit;

  /// Optional subtitle below the value.
  final String? subtitle;

  /// Optional icon before the label.
  final IconData? icon;

  /// Label and icon color.
  final Color labelColor;

  /// Main number color.
  final Color valueColor;

  /// Unit and subtitle color.
  final Color unitColor;

  /// Horizontal alignment for the tile content.
  final CrossAxisAlignment alignment;

  /// Optional label/value text alignment.
  final TextAlign? textAlign;

  /// Number font size.
  final double numberFontSize;

  /// Unit font size.
  final double unitFontSize;

  /// Label font size.
  final double labelFontSize;

  /// Label font weight.
  final FontWeight labelFontWeight;

  /// Vertical gap between label and value.
  final double labelValueSpacing;

  @override
  Widget build(BuildContext context) {
    final isEnd = alignment == CrossAxisAlignment.end;
    final effectiveTextAlign =
        textAlign ?? (isEnd ? TextAlign.end : TextAlign.start);

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisAlignment: isEnd
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: labelColor,
                size: icon == Icons.circle ? 7 : 14,
              ),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: effectiveTextAlign,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: labelColor,
                  fontSize: labelFontSize,
                  fontWeight: labelFontWeight,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: labelValueSpacing),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            alignment: isEnd ? Alignment.centerRight : Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: DiaryBalanceMetricValueText(
              value: value,
              unit: unit,
              valueColor: valueColor,
              unitColor: unitColor,
              numberFontSize: numberFontSize,
              unitFontSize: unitFontSize,
            ),
          ),
        ),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: effectiveTextAlign,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: unitColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }
}
