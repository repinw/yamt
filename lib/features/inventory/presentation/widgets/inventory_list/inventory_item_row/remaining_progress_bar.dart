import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

const _maxSegmentCount = 12;

/// Defines remaining progress bar label layout.
enum RemainingProgressBarLabelLayout {
  /// Below bar.
  belowBar,

  /// Above bar.
  aboveBar,
}

/// Defines remaining progress bar.
class RemainingProgressBar extends StatelessWidget {
  /// The remaining progress bar.
  const RemainingProgressBar({
    required this.ratio,
    required this.stockLabel,
    required this.segmentedByUnits,
    required this.totalUnits,
    required this.remainingUnits,
    super.key,
    this.labelLayout = RemainingProgressBarLabelLayout.belowBar,
    this.trackColor,
    this.fillColor,
    this.stockLabelStyle,
    this.percentageStyle,
  });

  /// The ratio.
  final double ratio;

  /// The stock label.
  final String stockLabel;

  /// The segmented by units.
  final bool segmentedByUnits;

  /// The total units.
  final int totalUnits;

  /// The remaining units.
  final int remainingUnits;

  /// The label layout.
  final RemainingProgressBarLabelLayout labelLayout;

  /// The track color.
  final Color? trackColor;

  /// The fill color.
  final Color? fillColor;

  /// The stock label style.
  final TextStyle? stockLabelStyle;

  /// The percentage style.
  final TextStyle? percentageStyle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final safeRatio = ratio.clamp(0.0, 1.0);
    final resolvedTrackColor =
        trackColor ?? colorScheme.surfaceContainerHighest;
    final isLowStock = safeRatio < 0.1;
    final resolvedFillColor =
        fillColor ?? (isLowStock ? colorScheme.error : colorScheme.primary);
    final percentage = (safeRatio * 100).round();
    final useSegmentedBar = segmentedByUnits && totalUnits <= _maxSegmentCount;
    final resolvedStockLabelStyle =
        stockLabelStyle ??
        Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        );
    final resolvedPercentageStyle =
        percentageStyle ??
        Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: labelLayout == RemainingProgressBarLabelLayout.aboveBar
              ? resolvedFillColor
              : colorScheme.onSurfaceVariant,
        );
    final labelRow = Row(
      children: [
        _StockLabel(
          stockLabel: stockLabel,
          baseStyle: resolvedStockLabelStyle,
          accentColor: resolvedFillColor,
        ),
        const Spacer(),
        Text('$percentage%', style: resolvedPercentageStyle),
      ],
    );
    final bar = Row(
      children: [
        Expanded(
          child: useSegmentedBar
              ? _buildSegmentedBar(
                  trackColor: resolvedTrackColor,
                  fillColor: resolvedFillColor,
                  safeRatio: safeRatio,
                )
              : _buildSingleBar(
                  trackColor: resolvedTrackColor,
                  fillColor: resolvedFillColor,
                  safeRatio: safeRatio,
                ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelLayout == RemainingProgressBarLabelLayout.aboveBar) ...[
          labelRow,
          const SizedBox(height: AppSpacing.xxs * 2),
          bar,
        ] else ...[
          bar,
          const SizedBox(height: AppSpacing.xxs * 2),
          labelRow,
        ],
      ],
    );
  }

  Widget _buildSingleBar({
    required Color trackColor,
    required Color fillColor,
    required double safeRatio,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: safeRatio,
        minHeight: AppInventoryEditorial.progressHeight,
        borderRadius: BorderRadius.circular(999),
        backgroundColor: trackColor,
        valueColor: AlwaysStoppedAnimation<Color>(fillColor),
      ),
    );
  }

  Widget _buildSegmentedBar({
    required Color trackColor,
    required Color fillColor,
    required double safeRatio,
  }) {
    final safeTotal = totalUnits < 1 ? 1 : totalUnits;
    final exactFilledByRatio = safeRatio * safeTotal;
    final exactFilledByUnits = remainingUnits.clamp(0, safeTotal).toDouble();
    final exactFilled = exactFilledByRatio < exactFilledByUnits
        ? exactFilledByRatio
        : exactFilledByUnits;

    return Row(
      children: List<Widget>.generate(safeTotal, (index) {
        final fillValue = _segmentFillValue(index, exactFilled);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == safeTotal - 1 ? 0 : AppSpacing.xxs,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: fillValue,
                minHeight: AppInventoryEditorial.progressHeight,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation<Color>(fillColor),
              ),
            ),
          ),
        );
      }),
    );
  }

  double _segmentFillValue(int segmentIndex, double exactFilled) {
    if (segmentIndex + 1 <= exactFilled) {
      return 1.0;
    }
    if (segmentIndex >= exactFilled) {
      return 0.0;
    }
    return (exactFilled - segmentIndex).clamp(0.0, 1.0);
  }
}

class _StockLabel extends StatelessWidget {
  const _StockLabel({
    required this.stockLabel,
    required this.baseStyle,
    required this.accentColor,
  });

  final String stockLabel;
  final TextStyle? baseStyle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final slashIndex = stockLabel.indexOf('/');
    if (slashIndex <= 0) {
      return Text(stockLabel, style: baseStyle);
    }

    final currentAmount = stockLabel.substring(0, slashIndex).trimRight();
    final remainingLabel = stockLabel.substring(slashIndex);

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: '$currentAmount ',
            style: baseStyle?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: remainingLabel),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
