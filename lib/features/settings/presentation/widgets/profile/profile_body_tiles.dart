import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_body_edit_controller.dart';
import 'package:yamt/features/settings/presentation/controllers/profile_summary_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_body_edit_sheet.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_fact_tile.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_formatters.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_tile_grid.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_training_edit_sheet.dart';
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

  /// Stable key of the height tile.
  static const heightTileKey = ValueKey<String>('profile-height-tile');

  /// Stable key of the training tile.
  static const trainingTileKey = ValueKey<String>('profile-training-tile');

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
          key: heightTileKey,
          label: l10n.settingsProfileSummaryHeightLabel,
          value: l10n.settingsProfileSummaryHeightValue(
            format.whole(profile.heightCm),
          ),
          onTap: () => _edit(context, ProfileBodyField.height),
        ),
        ProfileFactTile(
          label: l10n.settingsProfileSummaryAgeLabel,
          value: ageYears == null
              ? l10n.profileNoValue
              : l10n.settingsProfileSummaryAgeValue(ageYears),
          note: birthDate == null ? null : format.longDate(birthDate),
          onTap: () => _edit(context, ProfileBodyField.birthDate),
        ),
        ProfileFactTile(
          label: l10n.caloriesCalculatorSexLabel,
          value: switch (profile.sex) {
            CalorieCalculatorSex.male => l10n.caloriesCalculatorSexMale,
            CalorieCalculatorSex.female => l10n.caloriesCalculatorSexFemale,
          },
          onTap: () => _edit(context, ProfileBodyField.sex),
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

  void _edit(BuildContext context, ProfileBodyField field) {
    unawaited(
      showProfileBodyEditSheet(context, field: field, profile: profile),
    );
  }

  Widget _trainingTile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = ProfileFormatters.of(context);
    final run = state.runTraining;
    if (run == null) {
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
    final trainingDays = [
      for (final day in run.orderedTrainingDays) format.weekday(day.weekday),
    ];
    return ProfileFactTile(
      key: trainingTileKey,
      label: l10n.profileTrainingLabel,
      value: trainingDays.isEmpty
          ? l10n.profileTrainingNone
          : trainingDays.join(' · '),
      note: l10n.profileTrainingRunNote(format.shortDate(run.lastDay)),
      onTap: () => unawaited(showProfileTrainingEditSheet(context, plan: run)),
    );
  }
}
