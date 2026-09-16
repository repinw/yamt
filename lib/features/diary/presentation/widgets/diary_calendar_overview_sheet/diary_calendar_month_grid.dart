import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/domain/diary_calendar_bounds.dart';

const double _cellHeight = 44;
const double _dayCircleSize = 38;
const double _todayDotSize = 4;
const int _maxWeekRows = 6;

/// Localized Monday-to-Sunday weekday labels above the month grid.
class DiaryCalendarWeekdayRow extends StatelessWidget {
  /// Creates the weekday row.
  const DiaryCalendarWeekdayRow({required this.referenceDay, super.key});

  /// Any day; its calendar week provides the weekday names.
  final DateTime referenceDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final monday = startOfCalendarWeek(referenceDay);
    return Row(
      children: [
        for (var offset = 0; offset < DateTime.daysPerWeek; offset++)
          Expanded(
            child: Text(
              calendarWeekdayLabel(
                DateTime(monday.year, monday.month, monday.day + offset),
                localeName,
              ).toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

/// Month grid of selectable diary days, starting on Monday.
class DiaryCalendarMonthGrid extends StatelessWidget {
  /// Creates a month grid.
  const DiaryCalendarMonthGrid({
    required this.month,
    required this.selectedDay,
    required this.today,
    required this.bounds,
    required this.onSelectDay,
    super.key,
  });

  /// Fixed grid height so every month page has the same size.
  static const double height = _cellHeight * _maxWeekRows;

  /// Any day within the displayed month.
  final DateTime month;

  /// Selected day.
  final DateTime selectedDay;

  /// Normalized current day.
  final DateTime today;

  /// Selectable range.
  final DiaryCalendarBounds bounds;

  /// Called when a selectable day is tapped.
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final leadingBlanks =
        DateTime(month.year, month.month).weekday - DateTime.monday;
    final dayCount = DateUtils.getDaysInMonth(month.year, month.month);
    final rowCount = ((leadingBlanks + dayCount) / DateTime.daysPerWeek).ceil();

    return Column(
      children: [
        for (var row = 0; row < rowCount; row++)
          SizedBox(
            height: _cellHeight,
            child: Row(
              children: [
                for (var column = 0; column < DateTime.daysPerWeek; column++)
                  Expanded(
                    child: _buildCell(
                      row * DateTime.daysPerWeek + column - leadingBlanks + 1,
                      dayCount,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCell(int dayNumber, int dayCount) {
    if (dayNumber < 1 || dayNumber > dayCount) {
      return const SizedBox.shrink();
    }
    final day = DateTime(month.year, month.month, dayNumber);
    return _DiaryCalendarDayCell(
      day: day,
      isSelected: isSameCalendarDay(day, selectedDay),
      isToday: isSameCalendarDay(day, today),
      onTap: bounds.contains(day) ? () => onSelectDay(day) : null,
    );
  }
}

class _DiaryCalendarDayCell extends StatelessWidget {
  const _DiaryCalendarDayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = MetricAccentColors.of(context).today;
    final textColor = isSelected
        ? colors.onPrimary
        : onTap != null
        ? colors.onSurface
        : colors.onSurface.withValues(alpha: 0.3);

    return Center(
      child: Material(
        color: isSelected ? accent : Colors.transparent,
        shape: const CircleBorder(),
        child: AppInkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: _dayCircleSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w900
                        : FontWeight.w600,
                  ),
                ),
                if (isToday && !isSelected)
                  Positioned(
                    bottom: AppSpacing.xxs * 2,
                    child: SizedBox.square(
                      dimension: _todayDotSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
