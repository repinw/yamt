import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_summary_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_profile_summary_card/settings_profile_summary_body_facts.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_profile_summary_card/settings_profile_summary_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Name, body data, and goal list of the profile summary card.
class SettingsProfileSummarySections extends StatelessWidget {
  /// Creates the profile summary sections for [state].
  const new({required this.state, super.key});

  /// The profile summary to show.
  final ProfileSummaryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeader(name: state.name),
        const SizedBox(height: AppSpacing.md),
        if (state.hasBodyData)
          SettingsProfileSummaryBodyFacts(state: state)
        else
          _HintText(l10n.settingsProfileSummaryNoProfile),
        const Divider(height: AppSpacing.xxxl),
        Text(
          l10n.settingsProfileSummaryGoalsTitle,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _GoalList(state: state),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const new({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final name = this.name;

    return Row(
      children: [
        CircleAvatar(
          radius: AppSizes.profileAvatarRadius,
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: name == null
              ? const Icon(Icons.person_rounded)
              : Text(
                  name.characters.first.toUpperCase(),
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            name ?? l10n.settingsProfileSummaryFallbackTitle,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _GoalList extends StatelessWidget {
  const new({required this.state});

  final ProfileSummaryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goalKcal = state.dailyKcalGoal;
    if (goalKcal == null) {
      return _HintText(l10n.settingsDiaryGoalSetGoalFirst);
    }

    final accents = MetricAccentColors.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final whole = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 0;
    final decimal = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 2;
    final profile = state.profile;
    final targetWeightKg = profile?.targetWeightKg;
    final macros = state.macroTarget;

    return Column(
      children: [
        SettingsProfileSummaryRow(
          label: l10n.settingsProfileSummaryCaloriesLabel,
          value: l10n.settingsProfileSummaryCaloriesValue(
            whole.format(goalKcal),
          ),
        ),
        if (targetWeightKg != null)
          SettingsProfileSummaryRow(
            label: l10n.settingsProfileSummaryTargetWeightLabel,
            value: l10n.settingsProfileSummaryWeightValue(
              decimal.format(targetWeightKg),
            ),
          ),
        if (profile != null)
          SettingsProfileSummaryRow(
            label: l10n.caloriesCalculatorGoalModeLabel,
            value: _goalModeText(l10n, profile, decimal),
          ),
        if (macros != null) ...[
          SettingsProfileSummaryRow(
            label: l10n.caloriesProteinLabel,
            value: l10n.settingsProfileSummaryGramsValue(
              whole.format(macros.proteinGrams),
            ),
            valueColor: accents.protein,
          ),
          SettingsProfileSummaryRow(
            label: l10n.caloriesCarbsLabel,
            value: l10n.settingsProfileSummaryGramsValue(
              whole.format(macros.carbsGrams),
            ),
            valueColor: accents.carbs,
          ),
          SettingsProfileSummaryRow(
            label: l10n.caloriesFatLabel,
            value: l10n.settingsProfileSummaryGramsValue(
              whole.format(macros.fatGrams),
            ),
            valueColor: accents.fat,
          ),
        ],
      ],
    );
  }

  String _goalModeText(
    AppLocalizations l10n,
    CalorieCalculatorProfile profile,
    NumberFormat format,
  ) {
    final pace = format.format(profile.goalSpeedKgPerWeek);
    return switch (profile.goalMode) {
      CalorieGoalMode.lose => l10n.settingsProfileSummaryPaceValue(
        l10n.caloriesCalculatorGoalModeLose,
        pace,
      ),
      CalorieGoalMode.maintain => l10n.caloriesCalculatorGoalModeMaintain,
      CalorieGoalMode.gain => l10n.settingsProfileSummaryPaceValue(
        l10n.caloriesCalculatorGoalModeGain,
        pace,
      ),
    };
  }
}

class _HintText extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
