import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/week_balance_mode_choice.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Settings row of the week balance (#911): "Aus", "Anzeigen" or "Mit
/// Übertrag", the same choice as the week card's menu.
class SettingsWeekBalanceTile extends StatelessWidget {
  /// Creates the row.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      key: SettingsPageKeys.weekBalanceTile,
      children: [
        SettingsTile(
          icon: Icons.calendar_month_outlined,
          title: l10n.weekBalanceTitle,
          showChevron: false,
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: WeekBalanceModeChoice(),
        ),
      ],
    );
  }
}
