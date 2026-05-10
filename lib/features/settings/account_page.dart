import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/auth/provider/auth_error_view_model.dart';
import 'package:yamt/features/auth/provider/auth_service.dart'
    show authStateChangesProvider;
import 'package:yamt/features/settings/provider/account_controller.dart';
import 'package:yamt/features/settings/provider/account_page_flow_service.dart';
import 'package:yamt/features/settings/widgets/account_cards.dart';
import 'package:yamt/features/settings/widgets/account_status_snackbar.dart';
import 'package:yamt/features/settings/widgets/credential_conflict_dialog.dart';
import 'package:yamt/features/settings/widgets/link_email_password_dialog.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines account page.
class AccountPage extends ConsumerStatefulWidget {
  /// The account page.
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  Future<void> _signOut(AppLocalizations l10n) async {
    try {
      await ref.read(accountControllerProvider.notifier).signOut();
    } on Object catch (error) {
      if (!mounted) return;
      _showAuthError(l10n, error);
    }
  }

  Future<void> _confirmAndDeleteAccount(AppLocalizations l10n) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.accountPageDeleteDialogTitle),
          content: Text(l10n.accountPageDeleteDialogMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.accountPageDeleteDialogConfirmAction),
            ),
          ],
        );
      },
    );
    if (!mounted || shouldDelete != true) {
      return;
    }

    try {
      await ref.read(accountControllerProvider.notifier).deleteCurrentAccount();
      if (!mounted) {
        return;
      }
      showAccountStatusSnackBar(
        context,
        message: l10n.accountPageDeleteSuccess,
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      final flowService = ref.read(accountPageFlowServiceProvider);
      if (flowService.isRequiresRecentLoginError(error)) {
        _showRecentLoginRequiredSnackBar(l10n);
        return;
      }
      _showAuthError(l10n, error);
    }
  }

  void _showRecentLoginRequiredSnackBar(AppLocalizations l10n) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.authErrorRequiresRecentLogin),
          action: SnackBarAction(
            label: l10n.accountPageSignOut,
            onPressed: () {
              unawaited(_signOut(l10n));
            },
          ),
        ),
      );
  }

  Future<void> _linkGuestWithGoogle(AppLocalizations l10n) async {
    try {
      final linked = await ref
          .read(accountControllerProvider.notifier)
          .linkGuestWithGoogle();
      if (!mounted) return;
      if (linked) {
        showAccountStatusSnackBar(
          context,
          message: l10n.accountPageLinkSuccess,
        );
      }
    } on Object catch (error, stackTrace) {
      if (!mounted) return;
      if (error is FirebaseAuthException &&
          error.code == 'credential-already-in-use') {
        await _handleCredentialAlreadyInUse(l10n, error);
        return;
      }
      _logAuthError(error: error, stackTrace: stackTrace);
      _showAuthError(l10n, error);
    }
  }

  Future<void> _linkGuestWithEmailPassword(AppLocalizations l10n) async {
    final dialogResult = await _showEmailPasswordDialog(l10n);
    if (!mounted || dialogResult == null) {
      return;
    }
    final flowService = ref.read(accountPageFlowServiceProvider);
    if (dialogResult is FirebaseAuthException &&
        flowService.isCredentialAlreadyInUseError(dialogResult)) {
      await _handleCredentialAlreadyInUse(l10n, dialogResult);
      return;
    }
    if (dialogResult == true) {
      showAccountStatusSnackBar(context, message: l10n.accountPageLinkSuccess);
    }
  }

  Future<Object?> _showEmailPasswordDialog(AppLocalizations l10n) {
    final authErrorViewModel = ref.read(authErrorViewModelProvider);
    final flowService = ref.read(accountPageFlowServiceProvider);
    return showDialog<Object?>(
      context: context,
      builder: (_) => LinkEmailPasswordDialog(
        l10n: l10n,
        onSubmitCredentials: ({required email, required password}) async {
          try {
            final linked = await ref
                .read(accountControllerProvider.notifier)
                .linkGuestWithEmailPassword(email: email, password: password);
            if (!linked) {
              throw FirebaseAuthException(
                code: 'link-not-completed',
                message: 'Account linking was not completed. Please try again.',
              );
            }
          } on Object catch (error, stackTrace) {
            _logAuthError(error: error, stackTrace: stackTrace);
            rethrow;
          }
        },
        shouldBubbleSubmitError: (error) =>
            error is FirebaseAuthException &&
            flowService.isCredentialAlreadyInUseError(error),
        errorMessageFor: (error) =>
            authErrorViewModel.messageFor(l10n: l10n, error: error),
      ),
    );
  }

  Future<void> _handleCredentialAlreadyInUse(
    AppLocalizations l10n,
    FirebaseAuthException error,
  ) async {
    final credential = error.credential;
    if (credential == null) {
      _showAuthError(l10n, error);
      return;
    }

    final action = await showDialog<CredentialConflictAction>(
      context: context,
      builder: (dialogContext) {
        return CredentialConflictDialog(
          title: l10n.accountPageLinkConflictTitle,
          description: l10n.accountPageLinkConflictDescription,
          overwriteAction: l10n.accountPageLinkConflictOverwriteAction,
          overwriteSubtitle: l10n.accountPageLinkConflictOverwriteSubtitle,
          deleteGuestAction: l10n.accountPageLinkConflictDeleteGuestAction,
          deleteGuestSubtitle: l10n.accountPageLinkConflictDeleteGuestSubtitle,
          cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
          onCancel: () => _popConflictDialog(dialogContext),
          onOverwrite: () => _popConflictDialog(
            dialogContext,
            CredentialConflictAction.overwriteWithGuest,
          ),
          onDeleteGuestAndContinue: () => _popConflictDialog(
            dialogContext,
            CredentialConflictAction.deleteGuestAndSignInWithGoogle,
          ),
        );
      },
    );
    if (!mounted || action == null) return;

    try {
      final (choice, successMessage) = _resolveConflictChoice(l10n, action);
      await ref
          .read(accountPageFlowServiceProvider)
          .resolveCredentialConflict(choice: choice, credential: credential);
      if (!mounted) return;
      showAccountStatusSnackBar(context, message: successMessage);
    } on Object catch (error, stackTrace) {
      if (!mounted) return;
      _logAuthError(error: error, stackTrace: stackTrace);
      _showAuthError(l10n, error);
    }
  }

  (AccountCredentialConflictChoice, String) _resolveConflictChoice(
    AppLocalizations l10n,
    CredentialConflictAction action,
  ) {
    return switch (action) {
      CredentialConflictAction.overwriteWithGuest => (
        AccountCredentialConflictChoice.overwriteWithGuest,
        l10n.accountPageLinkConflictOverwriteDone,
      ),
      CredentialConflictAction.deleteGuestAndSignInWithGoogle => (
        AccountCredentialConflictChoice.deleteGuestAndSignInWithGoogle,
        l10n.accountPageLinkConflictDeleteGuestDone,
      ),
    };
  }

  void _logAuthError({required Object error, required StackTrace stackTrace}) {
    if (error case final FirebaseAuthException authError) {
      developer.log(
        'Failed account action: ${authError.code}',
        name: 'yamt.settings.account',
        level: 1000,
        error: authError,
        stackTrace: stackTrace,
      );
      return;
    }

    developer.log(
      'Failed account action: ${error.runtimeType}',
      name: 'yamt.settings.account',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _popConflictDialog(
    BuildContext dialogContext, [
    CredentialConflictAction? result,
  ]) {
    final router = GoRouter.maybeOf(dialogContext);
    if (router != null) {
      router.pop(result);
      return;
    }
    Navigator.of(dialogContext).pop(result);
  }

  void _showAuthError(AppLocalizations l10n, Object error) {
    final message = ref
        .read(authErrorViewModelProvider)
        .messageFor(l10n: l10n, error: error);
    showAccountStatusSnackBar(context, message: message, isError: true);
  }

  Widget _buildContent({
    required User user,
    required AppLocalizations l10n,
    required bool isActionLoading,
  }) {
    return ListView(
      padding: AppInsets.page,
      children: [
        if (user.isAnonymous)
          AccountGuestCard(
            l10n: l10n,
            isActionLoading: isActionLoading,
            onLinkWithGoogle: () => _linkGuestWithGoogle(l10n),
            onLinkWithEmailPassword: () => _linkGuestWithEmailPassword(l10n),
          ),
        if (user.isAnonymous) const SizedBox(height: AppSpacing.md),
        AccountUserInfoCard(user: user, l10n: l10n),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: isActionLoading ? null : () => _signOut(l10n),
          icon: const Icon(Icons.logout),
          label: Text(l10n.accountPageSignOut),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton.icon(
          onPressed: isActionLoading
              ? null
              : () => _confirmAndDeleteAccount(l10n),
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.accountPageDeleteAction),
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
            padding: AppInsets.pageLarge,
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
