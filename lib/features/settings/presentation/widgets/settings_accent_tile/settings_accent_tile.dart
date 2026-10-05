import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/app_accent_controller.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_accent_tile/settings_accent_sheet.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Settings row that shows the current accent color and opens the picker.
class SettingsAccentTile extends ConsumerWidget {
  /// Creates the accent color row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accent = ref.watch(appAccentControllerProvider);

    return SettingsTile(
      key: SettingsPageKeys.accentTile,
      icon: Icons.palette_outlined,
      title: l10n.settingsAccentTitle,
      trailing: SettingsTrailingValue(
        value: settingsAccentLabel(l10n, accent),
        swatchColor: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => unawaited(showSettingsAccentSheet(context)),
    );
  }
}
