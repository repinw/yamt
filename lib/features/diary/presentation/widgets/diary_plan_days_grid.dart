import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_plan_days_provider.dart';
import 'package:yamt/features/diary/domain/diary_calendar_bounds.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_calendar_overview_sheet/diary_calendar_month_grid.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The days that can be planned, from the Monday of [today]'s week to the
/// last day that can be planned, to pick days in. Days that hold plans carry
/// a dot.
class DiaryPlanDaysGrid extends ConsumerWidget {
  /// Creates the grid.
  const new({
    required this.today,
    required this.selected,
    required this.onToggle,
    super.key,
  });

  /// Key of the cell of [day].
  static Key dayKey(DateTime day) =>
      Key('diary_plan_days_${day.year}-${day.month}-${day.day}');

  /// The current day, the first one that can be picked.
  final DateTime today;

  /// The picked days.
  final Set<DateTime> selected;

  /// Picks or drops a day.
  final ValueChanged<DateTime> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final kick = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final first = dateOnly(today);
    final last = addLocalDays(first, diaryPlanAheadDayCount);
    final planDays =
        ref
            .watch(
              diaryPlanDaysProvider(
                DiaryCalendarBounds(earliestDay: first, latestDay: last),
              ),
            )
            .value ??
        const <DateTime>{};
    final monday = startOfCalendarWeek(first);
    final dayCount = diaryDaysBetween(monday, last) + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n
                  .diaryPlanCopyRange(DateFormat.MMMM(localeName).format(first))
                  .toUpperCase(),
              style: kick,
            ),
            Text(l10n.diaryPlanCopyPlannedLegend.toUpperCase(), style: kick),
          ],
        ),
        Column(
          children: [
            DiaryCalendarWeekdayRow(referenceDay: first),
            GridView.count(
              crossAxisCount: DateTime.daysPerWeek,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var index = 0; index < dayCount; index++)
                  _DayCell(
                    day: addLocalDays(monday, index),
                    today: first,
                    isSelected: selected.contains(addLocalDays(monday, index)),
                    hasPlans: planDays.contains(addLocalDays(monday, index)),
                    onToggle: onToggle,
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const new({
    required this.day,
    required this.today,
    required this.isSelected,
    required this.hasPlans,
    required this.onToggle,
  });

  final DateTime day;
  final DateTime today;
  final bool isSelected;
  final bool hasPlans;
  final ValueChanged<DateTime> onToggle;

  @override
  Widget build(BuildContext context) {
    return DiaryCalendarDayCell(
      key: DiaryPlanDaysGrid.dayKey(day),
      day: day,
      isSelected: isSelected,
      isToday: isSameCalendarDay(day, today),
      plan: hasPlans ? DiaryCalendarDayPlan.open : null,
      onTap: day.isBefore(today) ? null : () => onToggle(day),
    );
  }
}
