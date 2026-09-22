import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/home_widget/presentation/widgets/'
    'home_widget_verbose_mode_builder.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Settings row toggling the home-screen widget's silent/verbose layout.
///
/// The choice itself is owned by the Home Widget feature; this row only
/// renders it through `HomeWidgetVerboseModeBuilder`.
class SettingsHomeWidgetTile extends StatelessWidget {
  /// Creates the home-screen widget verbose-mode row.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return HomeWidgetVerboseModeBuilder(
      builder: (context, {required verbose, required toggle}) => SettingsTile(
        key: SettingsPageKeys.homeWidgetVerboseModeTile,
        icon: Icons.widgets_outlined,
        title: l10n.settingsHomeWidgetVerboseModeTitle,
        subtitle: l10n.settingsHomeWidgetVerboseModeSubtitle,
        showChevron: false,
        trailing: Switch(value: verbose, onChanged: (_) => toggle()),
        onTap: toggle,
      ),
    );
  }
}
