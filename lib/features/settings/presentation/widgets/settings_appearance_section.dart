import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_accent_tile/settings_accent_tile.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_language_tile/settings_language_tile.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_theme_mode_tile.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Where the revealed section lands in the viewport, as a fraction from the
/// top. The room above it keeps the header in view when a tile above changes
/// height after the jump, for example when the health status loads late.
const _revealAlignment = 0.05;

/// The Appearance section: language, theme, and accent color. With [reveal]
/// it scrolls itself to the top of the page once it is laid out, for the
/// side menu entry that opens settings at this section.
class SettingsAppearanceSection extends StatefulWidget {
  /// Creates the appearance section.
  const new({this.reveal = false, super.key});

  /// Whether the page opens scrolled to this section.
  final bool reveal;

  @override
  State<SettingsAppearanceSection> createState() =>
      _SettingsAppearanceSectionState();
}

class _SettingsAppearanceSectionState extends State<SettingsAppearanceSection> {
  @override
  void initState() {
    super.initState();
    if (widget.reveal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Scrollable.ensureVisible(context, alignment: _revealAlignment);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: AppLocalizations.of(context)!.settingsAppearanceSectionTitle,
      children: const [
        SettingsLanguageTile(),
        SettingsThemeModeTile(),
        SettingsAccentTile(),
      ],
    );
  }
}
