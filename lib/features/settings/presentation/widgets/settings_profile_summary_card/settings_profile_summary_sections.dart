import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_summary_controller.dart';
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
        switch ((state.profile, state.ageYears)) {
          (final profile?, final ageYears?) => _BodyFacts(
            profile: profile,
            ageYears: ageYears,
          ),
          _ => _HintText(l10n.settingsProfileSummaryNoProfile),
        },
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

class _BodyFacts extends StatelessWidget {
  const new({required this.profile, required this.ageYears});

  final CalorieCalculatorProfile profile;
  final int ageYears;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final decimal = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 1;
    final birthDate = profile.birthDate;

    return Column(
      children: [
        _SummaryRow(
          label: l10n.settingsProfileSummaryHeightLabel,
          value: l10n.settingsProfileSummaryHeightValue(
            decimal.format(profile.heightCm),
          ),
        ),
        _SummaryRow(
          label: l10n.caloriesCalculatorSexLabel,
          value: switch (profile.sex) {
            CalorieCalculatorSex.male => l10n.caloriesCalculatorSexMale,
            CalorieCalculatorSex.female => l10n.caloriesCalculatorSexFemale,
          },
        ),
        if (birthDate == null)
          _SummaryRow(
            label: l10n.settingsProfileSummaryAgeLabel,
            value: l10n.settingsProfileSummaryAgeValue(ageYears),
          )
        else
          _SummaryRow(
            label: l10n.settingsProfileSummaryBirthdayLabel,
            value: l10n.settingsProfileSummaryBirthdayValue(
              DateFormat.yMMMd(locale).format(birthDate),
              ageYears,
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
        _SummaryRow(
          label: l10n.settingsProfileSummaryCaloriesLabel,
          value: l10n.settingsProfileSummaryCaloriesValue(
            whole.format(goalKcal),
          ),
        ),
        if (targetWeightKg != null)
          _SummaryRow(
            label: l10n.settingsProfileSummaryTargetWeightLabel,
            value: l10n.settingsProfileSummaryWeightValue(
              decimal.format(targetWeightKg),
            ),
          ),
        if (profile != null)
          _SummaryRow(
            label: l10n.caloriesCalculatorGoalModeLabel,
            value: _goalModeText(l10n, profile, decimal),
          ),
        if (macros != null) ...[
          _SummaryRow(
            label: l10n.caloriesProteinLabel,
            value: l10n.settingsProfileSummaryGramsValue(
              whole.format(macros.proteinGrams),
            ),
            valueColor: accents.protein,
          ),
          _SummaryRow(
            label: l10n.caloriesCarbsLabel,
            value: l10n.settingsProfileSummaryGramsValue(
              whole.format(macros.carbsGrams),
            ),
            valueColor: accents.carbs,
          ),
          _SummaryRow(
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

class _SummaryRow extends StatelessWidget {
  const new({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium?.copyWith(
                color: valueColor ?? colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
