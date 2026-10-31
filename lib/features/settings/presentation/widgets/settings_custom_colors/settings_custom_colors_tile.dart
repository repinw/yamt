import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/theme/app_custom_colors_controller.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Settings row of the design "Individuell": which design the colors were
/// copied from, the accent swatch, and a tap opens the color editor.
class SettingsCustomColorsTile extends ConsumerWidget {
  /// Creates the row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final base = ref.watch(
      appCustomColorsControllerProvider.select((colors) => colors?.base),
    );

    return SettingsTile(
      key: SettingsPageKeys.customColorsTile,
      icon: Icons.tune_rounded,
      title: l10n.settingsCustomColorsTitle,
      subtitle: base == Brightness.dark
          ? l10n.settingsCustomColorsBasedOnDark
          : l10n.settingsCustomColorsBasedOnLight,
      trailing: SettingsTrailingValue(
        value: '',
        swatchColor: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => unawaited(context.push(AppRoutes.homeSettingsCustomColors)),
    );
  }
}
