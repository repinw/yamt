import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/profile_pill_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Two round choices for the sex.
class ProfileSexChoice extends StatelessWidget {
  /// Creates the choice with [selected] marked.
  const new({required this.selected, required this.onSelected, super.key});

  /// The chosen sex.
  final CalorieCalculatorSex selected;

  /// Called with the tapped sex.
  final ValueChanged<CalorieCalculatorSex> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      spacing: AppSpacing.xs,
      children: [
        for (final sex in CalorieCalculatorSex.values)
          Expanded(
            child: ProfilePillButton(
              label: switch (sex) {
                CalorieCalculatorSex.male => l10n.caloriesCalculatorSexMale,
                CalorieCalculatorSex.female => l10n.caloriesCalculatorSexFemale,
              },
              isSelected: sex == selected,
              onTap: () => onSelected(sex),
            ),
          ),
      ],
    );
  }
}
