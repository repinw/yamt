import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';

/// Horizontal pill selector for TDEE analytics time ranges.
class TdeeTimeRangeChips extends StatelessWidget {
  /// Creates time range chips bar.
  const TdeeTimeRangeChips({
    required this.selectedRange,
    required this.onSelectRange,
    super.key,
  });

  /// Currently selected time range.
  final TdeeAnalyticsTimeRange selectedRange;

  /// Callback when range changes.
  final ValueChanged<TdeeAnalyticsTimeRange> onSelectRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final range in TdeeAnalyticsTimeRange.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _RangePill(
                range: range,
                isSelected: range == selectedRange,
                colorScheme: colorScheme,
                theme: theme,
                onTap: () => onSelectRange(range),
              ),
            ),
        ],
      ),
    );
  }
}

class _RangePill extends StatelessWidget {
  const _RangePill({
    required this.range,
    required this.isSelected,
    required this.colorScheme,
    required this.theme,
    required this.onTap,
  });

  final TdeeAnalyticsTimeRange range;
  final bool isSelected;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final foregroundColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          range.label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: foregroundColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
