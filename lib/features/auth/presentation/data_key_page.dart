import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/domain/user_data_key_state.dart';
import 'package:yamt/features/auth/presentation/controllers/data_key_controller.dart';
import 'package:yamt/features/auth/presentation/widgets/recovery_key_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Gate before the app on a new device: asks for the recovery key when the
/// platform backup could not restore it, or offers a retry when the key
/// could not load.
class DataKeyPage extends ConsumerWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(userDataKeySessionProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dataKeyRestoreTitle),
        automaticallyImplyLeading: false,
      ),
      body: session.when(
        data: (state) => switch (state) {
          UserDataKeyRecoveryRequired() => const RecoveryKeyForm(),
          _ => const Center(child: CircularProgressIndicator()),
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        // Reads the controller on tap: it is auto-dispose and nothing on
        // this view watches it, so a notifier read during build is gone by
        // the time the user taps.
        error: (error, stackTrace) => _LoadFailedView(
          onRetry: () => ref.read(dataKeyControllerProvider.notifier).retry(),
        ),
      ),
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
