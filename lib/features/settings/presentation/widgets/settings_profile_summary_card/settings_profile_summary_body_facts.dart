import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_summary_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_profile_summary_card/settings_profile_summary_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Body data rows of the profile summary card: height, current weight, sex,
/// birthday with age, and daily expenditure.
class SettingsProfileSummaryBodyFacts extends StatelessWidget {
  /// Creates the body data rows for [state].
  const new({required this.state, super.key});

  /// The profile summary to show.
  final ProfileSummaryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final decimal = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 1;
    final whole = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 0;
    final profile = state.profile;
    final ageYears = state.ageYears;
    final currentWeightKg = state.currentWeightKg;
    final tdee = state.tdee;

    return Column(
      children: [
        if (profile != null)
          SettingsProfileSummaryRow(
            label: l10n.settingsProfileSummaryHeightLabel,
            value: l10n.settingsProfileSummaryHeightValue(
              decimal.format(profile.heightCm),
            ),
          ),
        if (currentWeightKg != null)
          SettingsProfileSummaryRow(
            label: l10n.settingsProfileSummaryCurrentWeightLabel,
            value: l10n.settingsProfileSummaryWeightValue(
              decimal.format(currentWeightKg),
            ),
          ),
        if (profile != null)
          SettingsProfileSummaryRow(
            label: l10n.caloriesCalculatorSexLabel,
            value: switch (profile.sex) {
              CalorieCalculatorSex.male => l10n.caloriesCalculatorSexMale,
              CalorieCalculatorSex.female => l10n.caloriesCalculatorSexFemale,
            },
          ),
        if (profile != null && ageYears != null)
          _AgeRow(birthDate: profile.birthDate, ageYears: ageYears),
        if (tdee != null)
          SettingsProfileSummaryRow(
            label: l10n.settingsProfileSummaryTdeeLabel,
            value: tdee.isLearned
                ? l10n.settingsProfileSummaryTdeeLearnedValue(
                    whole.format(tdee.kcal),
                  )
                : l10n.settingsProfileSummaryTdeeEstimatedValue(
                    whole.format(tdee.kcal),
                  ),
          ),
      ],
    );
  }
}

class _AgeRow extends StatelessWidget {
  const new({required this.birthDate, required this.ageYears});

  final DateTime? birthDate;
  final int ageYears;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final birthDate = this.birthDate;
    if (birthDate == null) {
      return SettingsProfileSummaryRow(
        label: l10n.settingsProfileSummaryAgeLabel,
        value: l10n.settingsProfileSummaryAgeValue(ageYears),
      );
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    return SettingsProfileSummaryRow(
      label: l10n.settingsProfileSummaryBirthdayLabel,
      value: l10n.settingsProfileSummaryBirthdayValue(
        DateFormat.yMMMd(locale).format(birthDate),
        ageYears,
      ),
    );
  }
}
