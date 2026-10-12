import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_calculator_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Title of a goal sheet, with an optional back arrow before it.
class CalorieGoalSheetTitle extends StatelessWidget {
  /// Creates the title of a goal sheet.
  const new({
    required this.title,
    required this.style,
    this.showBackButton = false,
    this.enabled = true,
    super.key,
  });

  /// The title.
  final String title;

  /// Style of the title.
  final TextStyle? style;

  /// Whether an arrow before the title closes the sheet without saving.
  final bool showBackButton;

  /// Whether the arrow reacts; false while the sheet saves.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = Text(title, style: style);
    if (!showBackButton) {
      return text;
    }
    return Row(
      children: [
        IconButton(
          key: CalorieGoalCalculatorSheetKeys.sheetBackButton,
          tooltip: AppLocalizations.of(context)!.caloriesCalculatorBackAction,
          onPressed: enabled ? () => Navigator.of(context).pop() : null,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: text),
      ],
    );
  }
}
