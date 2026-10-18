import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_archive_provider.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/presentation/controllers/progress_scope_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Chips that switch the Fortschritt tab between the current goal, all
/// goals, and, with more than one goal, one goal picked from a menu.
class ProgressScopeSwitch extends ConsumerWidget {
  /// Creates the scope switch.
  const new({super.key});

  /// Stable key of the chip for [scope].
  static ValueKey<String> chipKey(ProgressScope scope) =>
      ValueKey<String>('progress-scope-${scope.name}');

  /// Stable key of the chip that opens the goal menu.
  static const goalMenuKey = ValueKey<String>('progress-scope-goal-menu');

  /// Stable key of the menu entry of the goal with [number].
  static ValueKey<String> goalEntryKey(int number) =>
      ValueKey<String>('progress-scope-goal-entry-$number');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(progressScopeControllerProvider);
    final goals =
        ref.watch(calorieGoalArchiveProvider).value ??
        const <TdeeAnalyticsGoalCycle>[];
    void select(ProgressScope scope) =>
        ref.read(progressScopeControllerProvider.notifier).scope = scope;
    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        for (final scope in [ProgressScope.goal, ProgressScope.all])
          ChoiceChip(
            key: chipKey(scope),
            label: Text(
              scope == ProgressScope.goal
                  ? l10n.progressScopeGoal
                  : l10n.progressScopeAll,
            ),
            selected: scope == selected,
            onSelected: (_) => select(scope),
          ),
        if (goals.length > 1)
          _GoalMenuChip(goals: goals, selected: selected, onSelected: select),
      ],
    );
  }
}

/// A chip that opens the list of all goals, newest first; it reads the
/// picked past goal.
class _GoalMenuChip extends ConsumerWidget {
  const new({
    required this.goals,
    required this.selected,
    required this.onSelected,
  });

  /// All goals, newest first.
  final List<TdeeAnalyticsGoalCycle> goals;

  final ProgressScope selected;

  final ValueChanged<ProgressScope> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final thisYear = ref.watch(clockProvider)().year;
    String day(DateTime date) =>
        (date.year == thisYear
                ? DateFormat.MMMd(locale)
                : DateFormat.yMMMd(locale))
            .format(date);
    final selected = this.selected;
    return MenuAnchor(
      menuChildren: [
        for (final (index, goal) in goals.indexed)
          if (goals.length - index case final number)
            MenuItemButton(
              key: ProgressScopeSwitch.goalEntryKey(number),
              // The running goal is the current goal.
              onPressed: () => onSelected(
                index == 0 ? ProgressScope.goal : ProgressPastGoalScope(number),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    index == 0
                        ? l10n.progressGoalMenuRunning(number)
                        : l10n.progressGoalMarker(number),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(switch (goal.endDate) {
                    final end? when index > 0 => l10n.progressGoalMenuRange(
                      day(goal.startDate),
                      day(end),
                    ),
                    _ => l10n.progressGoalMenuSince(day(goal.startDate)),
                  }, style: textTheme.bodySmall),
                ],
              ),
            ),
      ],
      builder: (context, controller, _) => ChoiceChip(
        key: ProgressScopeSwitch.goalMenuKey,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xxs,
          children: [
            Text(switch (selected) {
              ProgressPastGoalScope(:final number) => l10n.progressGoalMarker(
                number,
              ),
              _ => l10n.progressScopePastGoal,
            }),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
        selected: selected is ProgressPastGoalScope,
        onSelected: (_) =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
