import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_pace.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_pace_wheel.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_target_weight_selector.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Row of the new-goal form that opens its control below it.
enum CalorieNewGoalRow {
  /// The target weight slider.
  target,

  /// The pace wheel.
  pace,
}

/// New-goal form: the resulting daily target on top, then one row per value.
///
/// Tapping the target or pace row opens its control below the row; the start
/// row opens the date picker.
class CalorieNewGoalForm extends StatelessWidget {
  /// Creates the new-goal form.
  const new({
    required this.goalKcal,
    required this.learnedTdeeKcal,
    required this.goalStartDate,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.goalMode,
    required this.paceKgPerWeek,
    required this.expandedRow,
    required this.onRowTapped,
    required this.onTargetChanged,
    required this.onPaceChanged,
    required this.onStartTapped,
    required this.today,
    super.key,
  });

  /// Daily target the saved goal gets.
  final double goalKcal;

  /// Learned TDEE the target comes from.
  final double learnedTdeeKcal;

  /// First day of the new goal.
  final DateTime goalStartDate;

  /// Latest measured weight.
  final double currentWeightKg;

  /// Picked target weight.
  final double targetWeightKg;

  /// Goal mode derived from the target.
  final CalorieGoalMode goalMode;

  /// Picked pace, in kilograms per week.
  final double paceKgPerWeek;

  /// Row whose control is open, if any.
  final CalorieNewGoalRow? expandedRow;

  /// Called when the target or pace row is tapped.
  final ValueChanged<CalorieNewGoalRow> onRowTapped;

  /// Receives the target from the slider and its derived goal mode.
  final void Function(double targetWeightKg, CalorieGoalMode mode)
  onTargetChanged;

  /// Receives the pace from the wheel.
  final ValueChanged<String> onPaceChanged;

  /// Called when the start row is tapped.
  final VoidCallback onStartTapped;

  /// Current day for the reach estimate.
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final startText = DateFormat.MMMd(locale).format(goalStartDate);
    final reachedOn = estimateGoalReachedDate(
      currentWeightKg: currentWeightKg,
      targetWeightKg: targetWeightKg,
      goalSpeedKgPerWeek: paceKgPerWeek,
      // The current weight is today's, so a past start counts from today.
      today: goalStartDate.isAfter(today) ? goalStartDate : today,
    );
    final modeLabel = switch (goalMode) {
      CalorieGoalMode.lose => l10n.caloriesCalculatorGoalModeLose,
      CalorieGoalMode.maintain => l10n.caloriesCalculatorGoalModeMaintain,
      CalorieGoalMode.gain => l10n.caloriesCalculatorGoalModeGain,
    };
    final paceText = paceKgPerWeek.toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.caloriesNewGoalStartsOn(startText),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '${numberFormat.format(goalKcal.round())} ${l10n.caloriesUnitKcal}',
          key: CalorieLearnedTdeeSheetKeys.goalValue,
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          l10n.caloriesNewGoalTdee(
            numberFormat.format(learnedTdeeKcal.round()),
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Material(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GoalRow(
                key: CalorieLearnedTdeeSheetKeys.targetRow,
                label: l10n.caloriesNewGoalTargetLabel,
                detail: l10n.caloriesNewGoalTargetDetail(
                  _formatWeight(currentWeightKg),
                  modeLabel,
                ),
                value:
                    '${_formatWeight(targetWeightKg)} ${l10n.caloriesUnitKg}',
                icon: expandedRow == CalorieNewGoalRow.target
                    ? Icons.expand_less
                    : Icons.expand_more,
                onTap: () => onRowTapped(CalorieNewGoalRow.target),
              ),
              if (expandedRow == CalorieNewGoalRow.target)
                CalorieTargetWeightSelector(
                  currentWeightKg: currentWeightKg,
                  targetWeightKg: targetWeightKg,
                  onChanged: onTargetChanged,
                ),
              if (goalMode != CalorieGoalMode.maintain) ...[
                const Divider(height: 1),
                _GoalRow(
                  key: CalorieLearnedTdeeSheetKeys.paceRow,
                  label: l10n.introPaceLabel,
                  value: '$paceText ${l10n.introPacePerWeekUnit}',
                  icon: expandedRow == CalorieNewGoalRow.pace
                      ? Icons.expand_less
                      : Icons.expand_more,
                  onTap: () => onRowTapped(CalorieNewGoalRow.pace),
                ),
                if (expandedRow == CalorieNewGoalRow.pace) ...[
                  CalorieGoalPaceWheel(
                    key: CalorieLearnedTdeeSheetKeys.paceWheel,
                    paceKgPerWeek: paceKgPerWeek,
                    unit: l10n.introPacePerWeekUnit,
                    onChanged: onPaceChanged,
                  ),
                  if (reachedOn != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: Text(
                        l10n.introTargetDateEstimate(
                          DateFormat.yMMMMd(locale).format(reachedOn),
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
              const Divider(height: 1),
              _GoalRow(
                key: CalorieLearnedTdeeSheetKeys.startRow,
                label: l10n.caloriesCalculatorGoalStartLabel,
                value: startText,
                icon: Icons.chevron_right,
                onTap: onStartTapped,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatWeight(double value) {
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
  }
}

class _GoalRow extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.detail,
    super.key,
  });

  final String label;
  final String value;
  final String? detail;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppInkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (detail case final detail?)
                      Text(detail, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(icon),
            ],
          ),
        ),
      ),
    );
  }
}
