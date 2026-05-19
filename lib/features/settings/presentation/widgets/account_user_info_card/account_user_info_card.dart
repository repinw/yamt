import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines account user info card.
class AccountUserInfoCard extends StatelessWidget {
  /// The account user info card.
  const AccountUserInfoCard({
    required this.user,
    required this.l10n,
    super.key,
  });

  /// The user.
  final User user;

  /// The l10n.
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
