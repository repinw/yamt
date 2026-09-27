import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_summary_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_formatters.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The current goal: where the user wants to go, how far the trend weight
/// got, and the daily calories and macros.
class ProfileGoalCard extends StatelessWidget {
  /// Creates the goal card for [state] with [profile].
  const new({required this.state, required this.profile, super.key});

  /// The profile summary to show.
  final ProfileSummaryState state;

  /// The calculator profile of [state].
  final CalorieCalculatorProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = FoodLabelColors.of(context);
    final format = ProfileFormatters.of(context);
    final target = profile.targetWeightKg;
    final progress = state.goalProgress;
    final kgToTarget = state.kgToTarget;
    final pace = format.decimal(profile.goalSpeedKgPerWeek);

    return Container(
      padding: AppInsets.card,
      decoration: BoxDecoration(
        color: label.tile,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Text(
            switch ((profile.goalMode, target)) {
              (CalorieGoalMode.lose, final kg?) => l10n.profileGoalLose(
                format.decimal(kg),
              ),
              (CalorieGoalMode.gain, final kg?) => l10n.profileGoalGain(
                format.decimal(kg),
              ),
              _ => l10n.profileGoalMaintain,
            },
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (progress != null) _GoalProgressBar(progress: progress),
          if (target != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.profileGoalStart(format.decimal(profile.weightKg)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: label.muted,
                    ),
                  ),
                ),
                if (kgToTarget != null)
                  Text(
                    l10n.profileGoalRemaining(format.decimal(kgToTarget), pace),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: label.muted,
                    ),
                  ),
              ],
            ),
          Divider(height: AppSizes.hairline, color: label.rule),
          _GoalTargets(state: state),
        ],
      ),
    );
  }
}

/// Four equal segments that fill in order as the trend weight nears the
/// target.
class _GoalProgressBar extends StatelessWidget {
  const new({required this.progress});

  final double progress;

  static const _segments = 4;

  @override
  Widget build(BuildContext context) {
    final label = FoodLabelColors.of(context);
    return Row(
      spacing: AppSpacing.xxs,
      children: [
        for (var index = 0; index < _segments; index++)
          Expanded(
            child: Container(
              height: AppSizes.profileGoalSegment,
              color: label.rule,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (progress * _segments - index)
                    .clamp(0, 1)
                    .toDouble(),
                child: ColoredBox(color: label.ink),
              ),
            ),
          ),
      ],
    );
  }
}

/// The daily calories and the grams of protein, carbs, and fat.
class _GoalTargets extends StatelessWidget {
  const new({required this.state});

  final ProfileSummaryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accents = MetricAccentColors.of(context);
    final format = ProfileFormatters.of(context);
    final goalKcal = state.dailyKcalGoal;
    final macros = state.macroTarget;
    if (goalKcal == null) {
      return Text(l10n.profileGoalNone, style: theme.textTheme.bodyMedium);
    }
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.settingsProfileSummaryCaloriesValue(format.whole(goalKcal)),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (macros != null) ...[
          _MacroGrams(
            color: accents.protein,
            semanticLabel: l10n.caloriesProteinLabel,
            grams: format.whole(macros.proteinGrams),
          ),
          _MacroGrams(
            color: accents.carbs,
            semanticLabel: l10n.caloriesCarbsLabel,
            grams: format.whole(macros.carbsGrams),
          ),
          _MacroGrams(
            color: accents.fat,
            semanticLabel: l10n.caloriesFatLabel,
            grams: format.whole(macros.fatGrams),
          ),
        ],
      ],
    );
  }
}

class _MacroGrams extends StatelessWidget {
  const new({
    required this.color,
    required this.semanticLabel,
    required this.grams,
  });

  final Color color;
  final String semanticLabel;
  final String grams;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = l10n.settingsProfileSummaryGramsValue(grams);
    return Semantics(
      label: '$semanticLabel $text',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          SizedBox.square(
            dimension: AppSizes.profileMacroSquare,
            child: ColoredBox(color: color),
          ),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
