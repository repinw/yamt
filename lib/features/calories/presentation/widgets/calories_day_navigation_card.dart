import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/presentation/calorie_weekday_l10n.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CaloriesDayNavigationCard extends StatelessWidget {
  const CaloriesDayNavigationCard({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.onSelectDay,
    required this.onPreviousDay,
    required this.onNextDay,
  });

  final List<CalorieWeekDayOverview> days;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: CaloriesPageKeys.weekStrip,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 0) {
          onPreviousDay();
          return;
        }
        if (velocity < 0) {
          onNextDay();
        }
      },
      child: Row(
        children: [
          for (final day in days)
            Expanded(
              child: _DiaryDayButton(
                day: day,
                isToday: _isSameDay(day.date, DateTime.now()),
                isSelected: _isSameDay(day.date, selectedDay),
                onTap: () => onSelectDay(day.date),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiaryDayButton extends StatelessWidget {
  const _DiaryDayButton({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final CalorieWeekDayOverview day;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final label = localizedDiaryWeekdayLabel(l10n, day.date);
    final labelColor = isToday
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final numberBackground = isToday
        ? AppInventoryEditorial.primary
        : Colors.transparent;
    final numberColor = isToday ? colorScheme.onPrimary : colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: labelColor,
                fontWeight: isToday || isSelected
                    ? FontWeight.w800
                    : FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: numberBackground,
                shape: BoxShape.circle,
                border: isSelected && !isToday
                    ? Border.all(
                        color: AppInventoryEditorial.primary.withValues(
                          alpha: 0.22,
                        ),
                      )
                    : null,
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: AppInventoryEditorial.primary.withValues(
                            alpha: 0.26,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '${day.date.day}'.padLeft(2, '0'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: numberColor,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w800
                        : FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DiaryDayStatus(day: day, isToday: isToday, isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _DiaryDayStatus extends StatelessWidget {
  const _DiaryDayStatus({
    required this.day,
    required this.isToday,
    required this.isSelected,
  });

  final CalorieWeekDayOverview day;
  final bool isToday;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isToday) {
      return Container(
        width: 16,
        height: 4,
        decoration: BoxDecoration(
          color: AppInventoryEditorial.primary.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }
    if (isSelected) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppInventoryEditorial.primary.withValues(alpha: 0.4),
          ),
          shape: BoxShape.circle,
        ),
      );
    }
    if (day.isWithinGoal) {
      return Icon(
        Icons.check_circle,
        size: 12,
        color: AppInventoryEditorial.primary,
      );
    }
    final statusColor = day.isOverGoal
        ? AppInventoryEditorial.warning
        : colorScheme.surfaceContainerHighest;
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
    );
  }
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
