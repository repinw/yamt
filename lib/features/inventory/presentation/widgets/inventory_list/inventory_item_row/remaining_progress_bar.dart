import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';

const _maxSegmentCount = 12;

class RemainingProgressBar extends StatelessWidget {
  const RemainingProgressBar({
    super.key,
    required this.ratio,
    required this.stockLabel,
    required this.segmentedByUnits,
    required this.totalUnits,
    required this.remainingUnits,
  });

  final double ratio;
  final String stockLabel;
  final bool segmentedByUnits;
  final int totalUnits;
  final int remainingUnits;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final safeRatio = ratio.clamp(0.0, 1.0);
    final trackColor = colorScheme.surfaceContainerHighest;
    final consumedRatio = (1 - safeRatio).clamp(0.0, 1.0);
    final fillColor = Color.lerp(
      colorScheme.primary,
      colorScheme.error,
      consumedRatio,
    );
    final resolvedFillColor = fillColor ?? colorScheme.primary;
    final percentage = (safeRatio * 100).round();
    final useSegmentedBar = segmentedByUnits && totalUnits <= _maxSegmentCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: useSegmentedBar
                  ? _buildSegmentedBar(
                      trackColor: trackColor,
                      fillColor: resolvedFillColor,
                      safeRatio: safeRatio,
                    )
                  : _buildSingleBar(
                      trackColor: trackColor,
                      fillColor: resolvedFillColor,
                      safeRatio: safeRatio,
                    ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs * 2),
        Row(
          children: [
            Text(
              stockLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
        minHeight: 10,
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
                minHeight: 10,
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
