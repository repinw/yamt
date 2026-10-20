import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Where a goal goes, such as "Lose weight to 78.0 kg".
class ProgressGoalTitle extends StatelessWidget {
  /// Creates the title of a goal with [mode] and [targetKg].
  const new({required this.mode, required this.targetKg, super.key});

  /// Whether the goal loses, keeps, or gains weight.
  final CalorieGoalMode? mode;

  /// The target weight, if any.
  final double? targetKg;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kg = NumberFormat(
      '0.0',
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Text(
      switch ((mode, targetKg)) {
        (CalorieGoalMode.lose, final target?) => l10n.progressGoalLose(
          kg.format(target),
        ),
        (CalorieGoalMode.gain, final target?) => l10n.progressGoalGain(
          kg.format(target),
        ),
        _ => l10n.progressGoalMaintain,
      },
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}
