import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The "Ins Kochbuch" switch of the "Gekocht" step: it also saves the meal
/// as a cookbook template with today's ingredients and amounts.
class CookedMealCookbookSwitch extends StatelessWidget {
  /// Creates the switch, on when [value].
  const new({required this.value, required this.onChanged, super.key});

  /// Key of the switch.
  static const switchKey = ValueKey<String>('cooked-to-cookbook');

  /// Whether the meal also goes to the cookbook.
  final bool value;

  /// Turns the switch on or off.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: AppSwitchListTile(
        key: switchKey,
        value: value,
        onChanged: onChanged,
        secondary: Icon(Icons.bookmark_add_outlined, color: colors.accentText),
        title: Text(l10n.cookedToCookbook),
        subtitle: Text(
          l10n.cookedToCookbookNote,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.muted),
        ),
      ),
    );
  }
}
