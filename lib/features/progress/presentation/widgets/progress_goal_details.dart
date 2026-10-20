import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/calories/application/calorie_goal_archive_provider.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_goal_title.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A past goal: where it went, its speed, start day and weight, end weight,
/// and the day it ended or was reached.
class ProgressGoalDetails extends ConsumerWidget {
  /// Creates the details of the goal with [number].
  const new({required this.number, super.key});

  /// Number of the goal among all goals, starting at 1.
  final int number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(calorieGoalArchiveProvider)
        .when(
          data: (goals) {
            // The goals come newest first.
            final goal = goals.elementAtOrNull(goals.length - number);
            if (goal == null) return const ProgressSectionError();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                ProgressGoalTitle(
                  mode: goal.goalMode,
                  targetKg: goal.targetWeightKg,
                ),
                _GoalFacts(goal: goal),
              ],
            );
          },
          loading: () => const ProgressSectionLoading(),
          error: (_, _) => const ProgressSectionError(),
        );
  }
}

class _GoalFacts extends StatelessWidget {
  const new({required this.goal});

  final TdeeAnalyticsGoalCycle goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMMMd(locale);
    final kg = NumberFormat('0.0', locale);
    String weight(double? value) =>
        value == null ? '–' : l10n.progressGoalWeightValue(kg.format(value));
    final speed = goal.goalSpeedKgPerWeek;
    final end = goal.endDate;
    final reached = goal.reachedDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        _FactRow(
          label: l10n.progressGoalSpeedLabel,
          value: goal.goalMode == CalorieGoalMode.maintain || speed == null
              ? '–'
              : l10n.progressGoalSpeedValue(
                  NumberFormat('0.00', locale).format(speed),
                ),
        ),
        _FactRow(
          label: l10n.progressGoalStartLabel,
          value: date.format(goal.startDate),
        ),
        _FactRow(
          label: l10n.progressGoalStartWeightLabel,
          value: weight(goal.startWeightKg),
        ),
        _FactRow(
          label: l10n.progressGoalEndWeightLabel,
          value: weight(goal.endWeightKg),
        ),
        if (end != null)
          _FactRow(label: l10n.progressGoalEndLabel, value: date.format(end)),
        if (reached != null)
          _FactRow(
            label: l10n.progressGoalReachedLabel,
            value: date.format(reached),
          ),
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = FoodLabelColors.of(context).muted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
