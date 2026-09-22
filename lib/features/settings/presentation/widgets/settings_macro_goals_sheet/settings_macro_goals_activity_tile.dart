import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_sheet_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Tile allowing the user to toggle the sport active multiplier setting.
class SettingsMacroGoalsActivityTile extends StatelessWidget {
  /// Creates the macro goals activity tile.
  const new({required this.isSportActive, required this.onChanged, super.key});

  /// Whether sport activity is currently enabled.
  final bool isSportActive;

  /// Callback when activity toggle changes.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: AppSwitchListTile.adaptive(
        key: SettingsMacroGoalsSheetKeys.sportActiveSwitch,
        value: isSportActive,
        onChanged: onChanged,
        title: Text(
          l10n.settingsMacroGoalsSportActiveLabel,
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          l10n.settingsMacroGoalsSportActiveSubtitle,
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}
