import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/calories/domain/calorie_run_training_plan.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_formatters.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The seven days of a run as round buttons. A dark button is a training
/// day; a pause day cannot be tapped.
class ProfileRunDayPicker extends StatelessWidget {
  /// Creates the picker for [plan] with [trainingDays] marked.
  const new({
    required this.plan,
    required this.trainingDays,
    required this.onToggle,
    super.key,
  });

  /// The run whose days are shown.
  final CalorieRunTrainingPlan plan;

  /// The days marked as training days.
  final Set<DateTime> trainingDays;

  /// Called with the tapped day.
  final ValueChanged<DateTime> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.xxs,
      children: [
        for (final day in plan.days)
          Expanded(
            child: _DayButton(
              day: day,
              isTraining: trainingDays.contains(day),
              isPause: plan.pauseDays.contains(day),
              onTap: () => onToggle(day),
            ),
          ),
      ],
    );
  }
}

class _DayButton extends StatelessWidget {
  const new({
    required this.day,
    required this.isTraining,
    required this.isPause,
    required this.onTap,
  });

  final DateTime day;
  final bool isTraining;
  final bool isPause;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = FoodLabelColors.of(context);
    final format = ProfileFormatters.of(context);
    final foreground = switch ((isPause, isTraining)) {
      (true, _) => colors.muted,
      (false, true) => colors.paper,
      (false, false) => colors.ink,
    };
    final radius = BorderRadius.circular(AppRadius.pill);
    return Semantics(
      button: !isPause,
      selected: isTraining,
      label: isPause ? l10n.profileTrainingPauseDay : null,
      child: Material(
        color: isPause
            ? Colors.transparent
            : (isTraining ? colors.ink : colors.tile),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: isPause ? BorderSide(color: colors.rule) : BorderSide.none,
        ),
        child: AppInkWell(
          onTap: isPause ? null : onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTapTarget,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    format.weekday(day.weekday),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                  Text(
                    format.dayOfMonth(day),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
