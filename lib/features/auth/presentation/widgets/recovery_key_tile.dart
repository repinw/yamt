import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the recovery key page, with a hint while the key is not saved yet.
class RecoveryKeyTile extends ConsumerWidget {
  /// Creates the tile.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final needsConfirmation = switch (ref
        .watch(userDataKeySessionProvider)
        .value) {
      final UserDataKeyReady ready => ready.needsRecoveryKeyConfirmation,
      _ => false,
    };
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        needsConfirmation ? Icons.key_off_outlined : Icons.key_outlined,
        color: needsConfirmation ? colorScheme.error : null,
      ),
      title: Text(l10n.recoveryKeyTitle),
      subtitle: needsConfirmation ? Text(l10n.recoveryKeyNotSavedHint) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(AppRoutes.homeSettingsRecoveryKey),
    );
  }
}
