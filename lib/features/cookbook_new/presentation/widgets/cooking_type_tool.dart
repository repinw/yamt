import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Schreiben" while cooking: the cook types ingredients instead of saying
/// them.
class CookingTypeTool extends StatelessWidget {
  /// Creates the tool; a `null` [onPressed] disables it.
  const new({required this.onPressed, super.key});

  /// Opens the text sheet.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return HomeHeaderTool(
      symbol: Icon(Icons.keyboard_rounded, color: colors.ink),
      label: AppLocalizations.of(context)!.freeCookingTypeAction,
      color: colors.ink,
      onPressed: onPressed,
    );
  }
}
