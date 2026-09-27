import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/application/calorie_run_training_service.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_effect_box.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_formatters.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What new training days change: each changed day with its calorie goal,
/// and the sum of the run.
class ProfileTrainingEffect extends StatelessWidget {
  /// Creates the effect box for [effect].
  const new({required this.effect, super.key});

  /// The effect to show.
  final CalorieRunTrainingEffect effect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = ProfileFormatters.of(context);
    final sumBefore = format.whole(effect.runKcalBefore);
    final sumAfter = format.whole(effect.runKcalAfter);
    return ProfileEffectBox(
      title: l10n.profileTrainingEffectTitle,
      rows: [
        for (final change in effect.changes)
          ProfileEffectRow(
            label: change.isTraining
                ? l10n.profileTrainingBecomesTraining(
                    format.weekdayDate(change.day),
                  )
                : l10n.profileTrainingBecomesRest(
                    format.weekdayDate(change.day),
                  ),
            value: l10n.profileEditKcalChange(
              format.whole(change.kcalBefore),
              format.whole(change.kcalAfter),
            ),
          ),
        for (final group in effect.otherDays)
          ProfileEffectRow(
            label: group.isTraining
                ? l10n.profileTrainingOtherTrainingDays(group.count)
                : l10n.profileTrainingOtherRestDays(group.count),
            value: l10n.profileEditKcalChange(
              format.whole(group.kcalBefore),
              format.whole(group.kcalAfter),
            ),
          ),
        ProfileEffectRow(
          label: l10n.profileTrainingRunSum,
          value: sumBefore == sumAfter
              ? l10n.profileEditKcalStays(sumAfter)
              : l10n.profileEditKcalChange(sumBefore, sumAfter),
        ),
      ],
      note: l10n.profileTrainingNote,
    );
  }
}
