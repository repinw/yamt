import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_summary_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_fact_tile.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_formatters.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_tile_grid.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The body data as tiles: height, age, sex, and training days, which the
/// user set, plus the macro weight and the daily expenditure, which the app
/// works out.
class ProfileBodyTiles extends StatelessWidget {
  /// Creates the body tiles for [state] with [profile].
  const new({required this.state, required this.profile, super.key});

  /// The profile summary to show.
  final ProfileSummaryState state;

  /// The calculator profile of [state].
  final CalorieCalculatorProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = ProfileFormatters.of(context);
    final birthDate = profile.birthDate;
    final ageYears = state.ageYears;
    final macroWeightKg = state.macroWeightKg;
    final macroWeightSince = state.macroWeightSince;
    final tdee = state.tdee;

    return ProfileTileGrid(
      tiles: [
        ProfileFactTile(
          label: l10n.settingsProfileSummaryHeightLabel,
          value: l10n.settingsProfileSummaryHeightValue(
            format.whole(profile.heightCm),
          ),
        ),
        ProfileFactTile(
          label: l10n.settingsProfileSummaryAgeLabel,
          value: ageYears == null
              ? l10n.profileNoValue
              : l10n.settingsProfileSummaryAgeValue(ageYears),
          note: birthDate == null ? null : format.longDate(birthDate),
        ),
        ProfileFactTile(
          label: l10n.caloriesCalculatorSexLabel,
          value: switch (profile.sex) {
            CalorieCalculatorSex.male => l10n.caloriesCalculatorSexMale,
            CalorieCalculatorSex.female => l10n.caloriesCalculatorSexFemale,
          },
        ),
        _trainingTile(context),
        ProfileFactTile(
          label: l10n.profileMacroWeightLabel,
          value: macroWeightKg == null
              ? l10n.profileNoValue
              : l10n.settingsProfileSummaryWeightValue(
                  format.decimal(macroWeightKg),
                ),
          note: macroWeightSince == null
              ? null
              : l10n.profileMacroWeightSince(
                  format.shortDate(macroWeightSince),
                ),
        ),
        ProfileFactTile(
          label: l10n.profileTdeeLabel,
          value: tdee == null
              ? l10n.profileNoValue
              : l10n.settingsProfileSummaryCaloriesValue(
                  format.whole(tdee.kcal),
                ),
          note: switch (tdee?.isLearned) {
            true => l10n.profileTdeeLearned,
            false => l10n.profileTdeeEstimated,
            null => null,
          },
        ),
      ],
    );
  }

  Widget _trainingTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = ProfileFormatters.of(context);
    // The calculator stores the weekdays sorted.
    final weekdays = profile.trainingWeekdays;
    return ProfileFactTile(
      label: l10n.profileTrainingLabel,
      value: weekdays.isEmpty
          ? l10n.profileTrainingNone
          : weekdays.map(format.weekday).join(' · '),
      note: weekdays.isEmpty
          ? null
          : l10n.profileTrainingOffset(
              format.whole(profile.trainingDayKcalOffset),
            ),
    );
  }
}
