import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/presentation/widgets/recovery_key_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the recovery key of the account again, opened from the settings.
class RecoveryKeyPage extends ConsumerWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recoveryKey = switch (ref.watch(userDataKeySessionProvider).value) {
      UserDataKeyReady(:final recoveryKey) => recoveryKey,
      _ => null,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recoveryKeyTitle)),
      body: ListView(
        padding: AppInsets.page,
        children: [
          if (recoveryKey == null)
            Text(l10n.recoveryKeyUnavailable)
          else
            RecoveryKeyCard(formattedKey: recoveryKey.formatted),
        ],
      ),
    );
  }
}
