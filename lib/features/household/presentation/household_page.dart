import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/household/presentation/widgets/'
    'household_sharing_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines household page.
class HouseholdPage extends ConsumerWidget {
  /// The household page.
  const HouseholdPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateChangesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.householdTitle)),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.accountPageNoSession));
          }

          return ListView(
            padding: AppInsets.page,
            children: [HouseholdSharingCard(user: user)],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.authFailed)),
      ),
    );
  }
}
