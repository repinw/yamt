import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_archive_provider.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/data_export/domain/data_export_range.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Chips that pick the export period: the current goal, all data, goals
/// from a menu, the last 7 days, 4 weeks, or 3 months, or days from a
/// calendar.
class DataExportRangeChips extends ConsumerWidget {
  /// Creates the chips with [selected] picked.
  const new({required this.selected, required this.onSelected, super.key});

  /// Key of the current goal chip.
  static const goalKey = ValueKey<String>('data-export-range-goal');

  /// Key of the all data chip.
  static const allKey = ValueKey<String>('data-export-range-all');

  /// Key of the goals menu chip.
  static const goalsKey = ValueKey<String>('data-export-range-goals');

  /// Key of the goal [number] in the menu.
  static ValueKey<String> goalEntryKey(int number) =>
      ValueKey<String>('data-export-range-goal-$number');

  /// Key of the chip of the last [days] days.
  static ValueKey<String> lastDaysKey(int days) =>
      ValueKey<String>('data-export-range-days-$days');

  /// Key of the calendar chip.
  static const customKey = ValueKey<String>('data-export-range-custom');

  /// The picked range.
  final DataExportRange selected;

  /// Called with the newly picked range.
  final ValueChanged<DataExportRange> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final goals =
        ref.watch(calorieGoalArchiveProvider).value ??
        const <TdeeAnalyticsGoalCycle>[];
    final selected = this.selected;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        ChoiceChip(
          key: goalKey,
          label: Text(l10n.progressScopeGoal),
          selected: selected == const DataExportGoalRange(ProgressScope.goal),
          onSelected: (_) =>
              onSelected(const DataExportGoalRange(ProgressScope.goal)),
        ),
        ChoiceChip(
          key: allKey,
          label: Text(l10n.dataExportRangeAll),
          selected: selected == const DataExportGoalRange(ProgressScope.all),
          onSelected: (_) =>
              onSelected(const DataExportGoalRange(ProgressScope.all)),
        ),
        if (goals.length > 1)
          _GoalsChip(goals: goals, selected: selected, onSelected: onSelected),
        for (final range in DataExportLastDaysRange.presets)
          ChoiceChip(
            key: lastDaysKey(range.days),
            label: Text(switch (range.days) {
              7 => l10n.dataExportRangeSevenDays,
              28 => l10n.dataExportRangeFourWeeks,
              _ => l10n.dataExportRangeThreeMonths,
            }),
            selected: selected == range,
            onSelected: (_) => onSelected(range),
          ),
        ChoiceChip(
          key: customKey,
          label: Text(l10n.dataExportRangeCustom),
          selected: selected is DataExportCustomRange,
          onSelected: (_) => unawaited(_pickDays(context, ref, goals)),
        ),
      ],
    );
  }

  /// [goals] are newest first; the calendar starts on the first goal.
  Future<void> _pickDays(
    BuildContext context,
    WidgetRef ref,
    List<TdeeAnalyticsGoalCycle> goals,
  ) async {
    final today = normalizeLocalDay(ref.read(clockProvider)());
    final current = selected;
    final firstGoal = goals.isEmpty
        ? null
        : normalizeLocalDay(goals.last.startDate);
    final firstDate = firstGoal == null || firstGoal.isAfter(today)
        ? DateTime(today.year - 10)
        : firstGoal;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: today,
      initialDateRange:
          current is DataExportCustomRange &&
              !current.from.isBefore(firstDate) &&
              !current.to.isAfter(today)
          ? DateTimeRange(start: current.from, end: current.to)
          : null,
    );
    if (picked == null) return;
    onSelected(DataExportCustomRange(from: picked.start, to: picked.end));
  }
}

class _GoalsChip extends StatelessWidget {
  const new({
    required this.goals,
    required this.selected,
    required this.onSelected,
  });

  /// Every goal, newest first; the first one is the current goal.
  final List<TdeeAnalyticsGoalCycle> goals;

  final DataExportRange selected;

  final ValueChanged<DataExportRange> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final picked = switch (selected) {
      final DataExportGoalsRange range => range,
      _ => null,
    };
    return MenuAnchor(
      menuChildren: [
        for (final (index, goal) in goals.indexed)
          if (goals.length - index case final number)
            CheckboxMenuButton(
              key: DataExportRangeChips.goalEntryKey(number),
              value: picked?.contains(number) ?? false,
              closeOnActivate: false,
              onChanged: (_) => onSelected(
                picked == null
                    ? DataExportGoalsRange(number, number)
                    : picked.toggle(number) ??
                          const DataExportGoalRange(ProgressScope.goal),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.progressGoalMarker(number),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(switch (goal.endDate) {
                    final end? => l10n.progressGoalMenuRange(
                      date.format(goal.startDate),
                      date.format(end),
                    ),
                    null => l10n.progressGoalMenuSince(
                      date.format(goal.startDate),
                    ),
                  }, style: textTheme.bodySmall),
                ],
              ),
            ),
      ],
      builder: (context, controller, _) => ChoiceChip(
        key: DataExportRangeChips.goalsKey,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xxs,
          children: [
            Text(switch (picked) {
              null => l10n.dataExportRangeGoals,
              DataExportGoalsRange(:final first, :final last)
                  when first == last =>
                l10n.progressGoalMarker(first),
              DataExportGoalsRange(:final first, :final last) =>
                l10n.dataExportRangeGoalSpan(first, last),
            }),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
        selected: picked != null,
        onSelected: (_) =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
