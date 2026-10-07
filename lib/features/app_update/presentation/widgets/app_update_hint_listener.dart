import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/app_version.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/app_update/presentation/app_update_store_flow.dart';
import 'package:yamt/features/app_update/presentation/controllers/app_update_hint_controller.dart';
import 'package:yamt/features/app_update/presentation/widgets/app_update_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows a snackbar once per newer app version. Wraps the app below its
/// `ScaffoldMessenger`.
class AppUpdateHintListener extends ConsumerWidget {
  /// Creates the listener around [child].
  const new({required this.child, super.key});

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(appUpdateHintControllerProvider, (_, next) {
      final version = next.isLoading ? null : next.value;
      if (version != null) {
        _showHint(context, ref, version);
      }
    });
    return child;
  }

  void _showHint(BuildContext context, WidgetRef ref, AppVersion version) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showAppSnackBar(
      l10n.appUpdateAvailable(version.toString()),
      key: AppUpdateKeys.availableSnackBar,
      tone: AppSnackBarTone.info,
      staysUntilClosed: true,
      action: (
        label: l10n.appUpdateAction,
        onPressed: () => unawaited(openAppUpdateStore(context)),
      ),
    );
    unawaited(
      ref.read(appUpdateHintControllerProvider.notifier).markShown(version),
    );
  }
}
