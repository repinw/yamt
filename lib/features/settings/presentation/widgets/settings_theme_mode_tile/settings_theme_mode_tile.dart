import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_mode_controller.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Settings row with System, Light, and Dark segments. A tap switches the
/// app at once and saves the choice.
class SettingsThemeModeTile extends ConsumerWidget {
  /// Creates the theme row.
  const new({super.key});

  /// Key of the segment for [mode].
  static Key segmentKey(ThemeMode mode) =>
      ValueKey('settings_theme_mode_${mode.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mode = ref.watch(appThemeModeControllerProvider);

    return Column(
      key: SettingsPageKeys.themeModeTile,
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
          child: SegmentedButton<ThemeMode>(
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: [
              for (final (value, label) in [
                (ThemeMode.system, l10n.settingsThemeModeSystem),
                (ThemeMode.light, l10n.settingsThemeModeLight),
                (ThemeMode.dark, l10n.settingsThemeModeDark),
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
            selected: {mode},
            onSelectionChanged: (selection) => unawaited(
              ref
                  .read(appThemeModeControllerProvider.notifier)
                  .select(selection.single),
            ),
          ),
        ),
      ],
    );
  }
}
