import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/presentation/controllers/data_key_controller.dart';
import 'package:yamt/features/auth/presentation/widgets/recovery_key_card.dart';
import 'package:yamt/features/auth/presentation/widgets/recovery_key_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Gate before the app: shows a new recovery key once, asks for the recovery
/// key on a new device, or offers a retry when the key could not load.
class DataKeyPage extends ConsumerWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(userDataKeySessionProvider);
    final title = switch (session.value) {
      UserDataKeyRecoveryRequired() => l10n.dataKeyRestoreTitle,
      _ => l10n.recoveryKeyTitle,
    };
    return Scaffold(
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
      body: session.when(
        data: (state) => switch (state) {
          UserDataKeyRecoveryRequired() => const RecoveryKeyForm(),
          UserDataKeyReady(:final recoveryKey?)
              when state.needsRecoveryKeyConfirmation =>
            _NewRecoveryKeyView(formattedKey: recoveryKey.formatted),
          _ => const Center(child: CircularProgressIndicator()),
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _LoadFailedView(
          onRetry: ref.read(dataKeyControllerProvider.notifier).retry,
        ),
      ),
    );
  }
}

class _NewRecoveryKeyView extends ConsumerWidget {
  const new({required this.formattedKey});

  final String formattedKey;

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
    final isBusy = ref.watch(dataKeyControllerProvider).isLoading;
    return ListView(
      padding: AppInsets.page,
      children: [
        RecoveryKeyCard(formattedKey: formattedKey),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: isBusy ? null : () => _confirm(context, ref, l10n),
          child: Text(l10n.recoveryKeyConfirmAction),
        ),
      ],
    );
  }
}

class _LoadFailedView extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: AppInsets.pageLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.dataKeyLoadFailed, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onRetry,
              child: Text(l10n.dataKeyRetryAction),
            ),
          ],
        ),
      ),
    );
  }
}
