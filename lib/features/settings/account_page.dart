import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/features/auth/provider/auth_error_view_model.dart';
import 'package:yamt/features/auth/provider/auth_service.dart'
    show authStateChangesProvider;
import 'package:yamt/features/settings/provider/account_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  Future<void> _signOut(AppLocalizations l10n) async {
    try {
      await ref.read(accountControllerProvider.notifier).signOut();
      if (mounted) {
        context.pop();
      }
    } catch (error) {
      if (!mounted) return;
      _showAuthError(l10n, error);
    }
  }

  Future<void> _linkGuestWithGoogle(AppLocalizations l10n) async {
    try {
      final linked = await ref
          .read(accountControllerProvider.notifier)
          .linkGuestWithGoogle();
      if (!mounted) return;
      if (linked) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.accountPageLinkSuccess)));
      }
    } catch (error) {
      if (!mounted) return;
      _showAuthError(l10n, error);
    }
  }

  void _showAuthError(AppLocalizations l10n, Object error) {
    final message = ref
        .read(authErrorViewModelProvider)
        .messageFor(l10n: l10n, error: error);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildGuestCard({
    required AppLocalizations l10n,
    required bool isActionLoading,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.accountPageGuestTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.accountPageGuestDescription),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isActionLoading
                  ? null
                  : () => _linkGuestWithGoogle(l10n),
              icon: const Icon(Icons.link),
              label: Text(l10n.accountPageLinkGoogle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(User user, AppLocalizations l10n) {
    String valueOrFallback(String? value) {
      if (value == null || value.isEmpty) {
        return l10n.accountPageNotSet;
      }
      return value;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.accountPageDisplayName),
              subtitle: Text(valueOrFallback(user.displayName)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: Text(l10n.accountPageEmail),
              subtitle: Text(valueOrFallback(user.email)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.fingerprint_outlined),
              title: Text(l10n.accountPageUserId),
              subtitle: Text(user.uid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required User user,
    required AppLocalizations l10n,
    required bool isActionLoading,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user.isAnonymous)
          _buildGuestCard(l10n: l10n, isActionLoading: isActionLoading),
        if (user.isAnonymous) const SizedBox(height: 12),
        _buildUserInfoCard(user, l10n),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: isActionLoading ? null : () => _signOut(l10n),
          icon: const Icon(Icons.logout),
          label: Text(l10n.accountPageSignOut),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateChangesProvider);
    final isActionLoading = ref.watch(accountControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAccountTitle)),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.accountPageNoSession));
          }
          return _buildContent(
            user: user,
            l10n: l10n,
            isActionLoading: isActionLoading,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              ref
                  .read(authErrorViewModelProvider)
                  .messageFor(l10n: l10n, error: error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
