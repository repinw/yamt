import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/health/application/health_steps_controller.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Settings row turning the steps in the diary on or off. Turning it on
/// connects Health when needed and asks for the steps permission. The row is
/// always there, so the page below never jumps once the Health status loads.
class SettingsStepsTile extends ConsumerWidget {
  /// Creates the steps switch row.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(healthStepsControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    void setEnabled(bool value) => unawaited(_setEnabled(context, ref, value));

    return SettingsTile(
      key: SettingsPageKeys.stepsTile,
      icon: Icons.directions_walk_rounded,
      title: l10n.settingsStepsTitle,
      subtitle: l10n.settingsStepsSubtitle,
      showChevron: false,
      trailing: Switch(value: enabled, onChanged: setEnabled),
      onTap: () => setEnabled(!enabled),
    );
  }

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final steps = ref.read(healthStepsControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      if (!value) {
        await steps.disable();
        return;
      }
      final hint = switch (await steps.enable()) {
        HealthStepsEnableResult.enabled => null,
        HealthStepsEnableResult.denied => l10n.settingsStepsDenied,
        HealthStepsEnableResult.unsupported => l10n.healthUnsupportedHint,
      };
      if (hint != null) {
        messenger.showAppSnackBar(hint, tone: AppSnackBarTone.info);
      }
    } on Object {
      messenger.showAppSnackBar(
        l10n.settingsStepsFailed,
        tone: AppSnackBarTone.error,
      );
    }
  }
}
