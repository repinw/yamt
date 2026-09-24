import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/auth/domain/auth_exceptions.dart';
import 'package:yamt/features/auth/presentation/controllers/data_key_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Asks for the recovery key on a new device, or lets the user start fresh.
class RecoveryKeyForm extends ConsumerStatefulWidget {
  /// Creates the form.
  const new({super.key});

  @override
  ConsumerState<RecoveryKeyForm> createState() => _RecoveryKeyFormState();
}

class _RecoveryKeyFormState extends ConsumerState<RecoveryKeyForm> {
  final _keyController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _restore(AppLocalizations l10n) async {
    setState(() => _errorText = null);
    final restored = await ref
        .read(dataKeyControllerProvider.notifier)
        .restore(_keyController.text);
    if (restored || !mounted) return;
    final error = ref.read(dataKeyControllerProvider).error;
    setState(() {
      _errorText = error is InvalidRecoveryKeyException
          ? l10n.dataKeyRestoreInvalid
          : l10n.dataKeyRestoreFailed;
    });
  }

  Future<void> _pickFromPasswordManager(AppLocalizations l10n) async {
    setState(() => _errorText = null);
    final picked = await ref
        .read(dataKeyControllerProvider.notifier)
        .pickRecoveryKeyFromPasswordManager();
    if (!mounted) return;
    if (picked == null) {
      if (ref.read(dataKeyControllerProvider).hasError) {
        setState(() => _errorText = l10n.dataKeyPickFailed);
      }
      return;
    }
    _keyController.text = picked;
    await _restore(l10n);
  }

  Future<void> _startFresh(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.dataKeyStartFreshDialogTitle),
        content: Text(l10n.dataKeyStartFreshDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.dataKeyStartFreshConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final started = await ref
        .read(dataKeyControllerProvider.notifier)
        .startFresh();
    if (started || !mounted) return;
    ScaffoldMessenger.of(context).showAppSnackBar(
      l10n.dataKeyStartFreshFailed,
      tone: AppSnackBarTone.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isBusy = ref.watch(dataKeyControllerProvider).isLoading;
    final canUsePasswordManager = ref.watch(
      canSaveRecoveryKeyToPasswordManagerProvider,
    );
    return ListView(
      padding: AppInsets.page,
      children: [
        Text(
          l10n.dataKeyRestoreExplanation,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _keyController,
          enabled: !isBusy,
          autocorrect: false,
          enableSuggestions: false,
          // Lets the password manager fill in a saved recovery key.
          autofillHints: const <String>[AutofillHints.password],
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: l10n.recoveryKeyTitle,
            errorText: _errorText,
          ),
          onSubmitted: (_) => _restore(l10n),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (canUsePasswordManager) ...[
          FilledButton.icon(
            onPressed: isBusy ? null : () => _pickFromPasswordManager(l10n),
            icon: const Icon(Icons.password),
            label: Text(l10n.dataKeyPickFromPasswordManagerAction),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        OutlinedButton(
          onPressed: isBusy ? null : () => _restore(l10n),
          child: Text(l10n.dataKeyRestoreAction),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: isBusy ? null : () => _startFresh(l10n),
          child: Text(l10n.dataKeyStartFreshAction),
        ),
      ],
    );
  }
}
