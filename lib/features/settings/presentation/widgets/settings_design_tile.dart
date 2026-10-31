import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_design_controller.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/settings_design_flow.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Settings row with System, Light, Dark, and Custom segments. A tap
/// switches the app at once and saves the choice.
class SettingsDesignTile extends ConsumerWidget {
  /// Creates the design row.
  const new({super.key});

  /// Key of the segment for [design].
  static Key segmentKey(AppDesign design) =>
      ValueKey('settings_theme_mode_${design.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final design = ref.watch(appDesignControllerProvider);

    return Column(
      key: SettingsPageKeys.designTile,
      children: [
        SettingsTile(
          icon: Icons.contrast_rounded,
          title: l10n.settingsThemeModeTitle,
          showChevron: false,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: SegmentedButton<AppDesign>(
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: [
              for (final (value, label) in [
                (AppDesign.system, l10n.settingsThemeModeSystem),
                (AppDesign.light, l10n.settingsThemeModeLight),
                (AppDesign.dark, l10n.settingsThemeModeDark),
                (AppDesign.custom, l10n.settingsDesignCustom),
              ])
                ButtonSegment(
                  value: value,
                  // Large text shrinks the word instead of breaking it.
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, key: segmentKey(value)),
                  ),
                ),
            ],
            selected: {design},
            onSelectionChanged: (selection) => unawaited(
              selectSettingsDesignFlow(context, ref, selection.single),
            ),
          ),
        ),
      ],
    );
  }
}
