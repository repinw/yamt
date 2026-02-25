import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

class AccountGuestCard extends StatelessWidget {
  const AccountGuestCard({
    super.key,
    required this.l10n,
    required this.isActionLoading,
    required this.onLinkWithGoogle,
    required this.onLinkWithEmailPassword,
  });

  final AppLocalizations l10n;
  final bool isActionLoading;
  final VoidCallback onLinkWithGoogle;
  final VoidCallback onLinkWithEmailPassword;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.accountPageGuestTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.accountPageGuestDescription),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: isActionLoading ? null : onLinkWithGoogle,
              icon: const Icon(Icons.link),
              label: Text(l10n.accountPageLinkGoogle),
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton.icon(
              onPressed: isActionLoading ? null : onLinkWithEmailPassword,
              icon: const Icon(Icons.email_outlined),
              label: Text(l10n.accountPageLinkEmailPassword),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountUserInfoCard extends StatelessWidget {
  const AccountUserInfoCard({
    super.key,
    required this.user,
    required this.l10n,
  });

  final User user;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    String valueOrFallback(String? value) {
      if (value == null || value.isEmpty) {
        return l10n.accountPageNotSet;
      }
      return value;
    }

    return Card(
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: AppInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.accountPageDisplayName),
              subtitle: Text(valueOrFallback(user.displayName)),
            ),
            ListTile(
              contentPadding: AppInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: Text(l10n.accountPageEmail),
              subtitle: Text(valueOrFallback(user.email)),
            ),
            ListTile(
              contentPadding: AppInsets.zero,
              leading: const Icon(Icons.fingerprint_outlined),
              title: Text(l10n.accountPageUserId),
              subtitle: Text(user.uid),
            ),
          ],
        ),
      ),
    );
  }
}
