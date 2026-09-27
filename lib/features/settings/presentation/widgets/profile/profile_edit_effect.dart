import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/calories/application/calorie_body_edit_service.dart';
import 'package:yamt/features/calories/domain/calorie_goal_body_edits.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_effect_box.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_formatters.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What a body edit changes: the calorie goal, the macros that change, and
/// why the rest stays.
class ProfileEditEffect extends StatelessWidget {
  /// Creates the effect box for [effect].
  const new({required this.effect, super.key});

  /// The effect to show.
  final CalorieBodyEditEffect effect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = ProfileFormatters.of(context);
    final correctionStart = effect.correctionStart;
    return ProfileEffectBox(
      title: correctionStart == null
          ? l10n.profileEditEffectToday
          : l10n.profileEditEffectFromGoalStart(
              format.longDate(correctionStart),
            ),
      rows: _rows(context),
      note: switch (effect.reach) {
        CalorieBodyEditReach.noGoal => l10n.profileEditNoteNoGoal,
        CalorieBodyEditReach.learnedTdee => l10n.profileEditNoteLearned,
        CalorieBodyEditReach.manualGoal => l10n.profileEditNoteManual,
        CalorieBodyEditReach.goalCorrection => l10n.profileEditNoteCorrection,
      },
    );
  }

  List<Widget> _rows(BuildContext context) {
    final before = effect.before;
    final after = effect.after;
    if (before == null || after == null) {
      return const [];
    }
    final l10n = AppLocalizations.of(context)!;
    final accents = MetricAccentColors.of(context);
    final format = ProfileFormatters.of(context);
    final kcalBefore = format.whole(before.goalKcal);
    final kcalAfter = format.whole(after.goalKcal);
    final macros = [
      (
        l10n.caloriesProteinLabel,
        accents.protein,
        before.proteinGrams,
        after.proteinGrams,
      ),
      (
        l10n.caloriesCarbsLabel,
        accents.carbs,
        before.carbsGrams,
        after.carbsGrams,
      ),
      (l10n.caloriesFatLabel, accents.fat, before.fatGrams, after.fatGrams),
    ];
    final changedMacros = [
      for (final (name, color, gramsBefore, gramsAfter) in macros)
        if (format.whole(gramsBefore) != format.whole(gramsAfter))
          ProfileEffectRow(
            label: name,
            color: color,
            value: l10n.profileEditGramsChange(
              format.whole(gramsBefore),
              format.whole(gramsAfter),
            ),
          ),
    ];
    return [
      ProfileEffectRow(
        label: l10n.profileEditKcalLabel,
        value: kcalBefore == kcalAfter
            ? l10n.profileEditKcalStays(kcalAfter)
            : l10n.profileEditKcalChange(kcalBefore, kcalAfter),
      ),
      if (changedMacros.isEmpty)
        ProfileEffectRow(
          label: l10n.profileEditMacrosLabel,
          value: l10n.profileEditMacrosStay,
        )
      else
        ...changedMacros,
    ];
  }
}
