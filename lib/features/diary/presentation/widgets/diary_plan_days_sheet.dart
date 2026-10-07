import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_plan_days_provider.dart';
import 'package:yamt/features/diary/domain/diary_calendar_bounds.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_calendar_overview_sheet/diary_calendar_month_grid.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The days and the meal picked in the [showDiaryPlanDaysSheet].
typedef DiaryPlanDaysChoice = ({List<DateTime> days, MealType mealType});

/// Asks on which days [plan] is planned too: the days from today to the
/// last day that can be planned, and the meal, preset to the plan's.
/// Resolves with the choice, or null when the sheet closes.
Future<DiaryPlanDaysChoice?> showDiaryPlanDaysSheet({
  required BuildContext context,
  required CalorieEntry plan,
  required DateTime today,
}) {
  return showModalBottomSheet<DiaryPlanDaysChoice>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => DiaryPlanDaysSheet(plan: plan, today: today),
  );
}

/// The "Auch planen für" sheet: two weeks to pick days in, the meal, and
/// the button that plans them.
class DiaryPlanDaysSheet extends ConsumerStatefulWidget {
  /// Creates the sheet for [plan].
  const new({required this.plan, required this.today, super.key});

  /// Key of the button that plans the picked days.
  static const confirmKey = Key('diary_plan_days_confirm');

  /// Key of the cell of [day].
  static Key dayKey(DateTime day) =>
      Key('diary_plan_days_${day.year}-${day.month}-${day.day}');

  /// Key of the chip of [type].
  static Key mealKey(MealType type) => Key('diary_plan_days_meal_${type.name}');

  /// The plan to copy.
  final CalorieEntry plan;

  /// The current day.
  final DateTime today;

  @override
  ConsumerState<DiaryPlanDaysSheet> createState() => _DiaryPlanDaysSheetState();
}

class _DiaryPlanDaysSheetState extends ConsumerState<DiaryPlanDaysSheet> {
  final _days = <DateTime>{};
  late MealType _mealType = widget.plan.mealType;

  DateTime get _today => dateOnly(widget.today);

  DateTime get _lastDay => addLocalDays(_today, diaryPlanAheadDayCount);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final kick = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final planDays =
        ref
            .watch(
              diaryPlanDaysProvider(
                DiaryCalendarBounds(earliestDay: _today, latestDay: _lastDay),
              ),
            )
            .value ??
        const <DateTime>{};
    final first = startOfCalendarWeek(_today);
    final dayCount = diaryDaysBetween(first, _lastDay) + 1;
    final kcal = widget.plan.totalKcal * _days.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xxs,
              children: [
                Text(l10n.diaryPlanCopyTitle.toUpperCase(), style: kick),
                Text(
                  widget.plan.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  l10n.eatPageKcal(widget.plan.totalKcal.round()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n
                      .diaryPlanCopyRange(
                        DateFormat.MMMM(localeName).format(_today),
                      )
                      .toUpperCase(),
                  style: kick,
                ),
                Text(
                  l10n.diaryPlanCopyPlannedLegend.toUpperCase(),
                  style: kick,
                ),
              ],
            ),
            Column(
              children: [
                DiaryCalendarWeekdayRow(referenceDay: _today),
                GridView.count(
                  crossAxisCount: DateTime.daysPerWeek,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var index = 0; index < dayCount; index++)
                      _DayCell(
                        day: addLocalDays(first, index),
                        today: _today,
                        isSelected: _days.contains(addLocalDays(first, index)),
                        hasPlans: planDays.contains(addLocalDays(first, index)),
                        onToggle: (day) => setState(
                          () => _days.contains(day)
                              ? _days.remove(day)
                              : _days.add(day),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Text(l10n.diaryPlanCopyMealLabel.toUpperCase(), style: kick),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final type in MealType.sectionOrder)
                  ChoiceChip(
                    key: DiaryPlanDaysSheet.mealKey(type),
                    label: Text(type.localizedName(l10n)),
                    selected: type == _mealType,
                    onSelected: (_) => setState(() => _mealType = type),
                  ),
              ],
            ),
            FilledButton(
              key: DiaryPlanDaysSheet.confirmKey,
              onPressed: _days.isEmpty
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pop((days: _days.toList()..sort(), mealType: _mealType)),
              child: Text(
                _days.isEmpty
                    ? l10n.diaryPlanCopyConfirm(0)
                    : l10n.diaryPlanCopyConfirmKcal(_days.length, kcal.round()),
              ),
            ),
          ],
        ),
      ),
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
      key: DiaryPlanDaysSheet.dayKey(day),
      day: day,
      isSelected: isSelected,
      isToday: isSameCalendarDay(day, today),
      plan: hasPlans ? DiaryCalendarDayPlan.open : null,
      onTap: day.isBefore(today) ? null : () => onToggle(day),
    );
  }
}
