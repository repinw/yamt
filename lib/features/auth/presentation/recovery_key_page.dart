import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';
import 'package:yamt/features/auth/presentation/controllers/data_key_controller.dart';
import 'package:yamt/features/auth/presentation/widgets/recovery_key_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the recovery key of the account, opened from the account settings.
///
/// The user can save it in the password manager or mark it as saved.
class RecoveryKeyPage extends ConsumerWidget {
  /// Creates the page.
  const new({super.key});

  Future<void> _saveToPasswordManager(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final result = await ref
        .read(dataKeyControllerProvider.notifier)
        .saveRecoveryKeyToPasswordManager();
    if (!context.mounted) return;
    switch (result) {
      case RecoveryKeySaveResult.saved:
        ScaffoldMessenger.of(context).showAppSnackBar(l10n.recoveryKeySaved);
      case RecoveryKeySaveResult.canceled:
        return;
      case RecoveryKeySaveResult.failed:
        ScaffoldMessenger.of(context).showAppSnackBar(
          l10n.recoveryKeySaveFailed,
          tone: AppSnackBarTone.error,
        );
    }
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await ref
        .read(dataKeyControllerProvider.notifier)
        .confirmRecoveryKeySaved();
    if (confirmed || !context.mounted) return;
    ScaffoldMessenger.of(context).showAppSnackBar(
      l10n.recoveryKeyConfirmFailed,
      tone: AppSnackBarTone.error,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ready = switch (ref.watch(userDataKeySessionProvider).value) {
      final UserDataKeyReady ready when ready.recoveryKey != null => ready,
      _ => null,
    };
    final isBusy = ref.watch(dataKeyControllerProvider).isLoading;
    final canSaveToPasswordManager = ref.watch(
      canSaveRecoveryKeyToPasswordManagerProvider,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recoveryKeyTitle)),
      body: ListView(
        padding: AppInsets.page,
        children: [
          if (ready == null)
            Text(l10n.recoveryKeyUnavailable)
          else ...[
            RecoveryKeyCard(formattedKey: ready.recoveryKey!.formatted),
            const SizedBox(height: AppSpacing.xl),
            if (canSaveToPasswordManager)
              FilledButton.icon(
                onPressed: isBusy
                    ? null
                    : () => _saveToPasswordManager(context, ref, l10n),
                icon: const Icon(Icons.password),
                label: Text(l10n.recoveryKeySaveToPasswordManagerAction),
              ),
            if (ready.needsRecoveryKeyConfirmation) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: isBusy ? null : () => _confirm(context, ref, l10n),
                child: Text(l10n.recoveryKeyConfirmAction),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
