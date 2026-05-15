import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yamt/features/auth/presentation/controllers/auth_form_controller.dart';
import 'package:yamt/features/auth/presentation/controllers/google_auth_controller.dart';
import 'package:yamt/features/auth/presentation/controllers/guest_auth_controller.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_action_button/auth_action_button.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_divider/auth_divider.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_footer_prompt/auth_footer_prompt.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_ghost_text_button/auth_ghost_text_button.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_layout_metrics/auth_layout_metrics.dart';
import 'package:yamt/features/auth/presentation/widgets/login_form/login_form.dart';
import 'package:yamt/features/auth/presentation/widgets/register_form/register_form.dart';
import 'package:yamt/features/shared/widgets/credential_form_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Auth form card with email, social, and guest actions.
class AuthCard extends ConsumerWidget {
  /// Creates an auth card.
  const AuthCard({
    required this.isLoginMode,
    required this.onShowLoginMode,
    required this.onShowRegisterMode,
    required this.metrics,
    super.key,
  });

  /// Whether login mode is active.
  final bool isLoginMode;

  /// Switches to login mode.
  final VoidCallback onShowLoginMode;

  /// Switches to register mode.
  final VoidCallback onShowRegisterMode;

  /// Current layout metrics.
  final AuthLayoutMetrics metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isAuthLoading = ref.watch(authFormControllerProvider).isLoading;
    final isGoogleLoading = ref.watch(googleAuthControllerProvider).isLoading;
    final isGuestLoading = ref.watch(guestAuthControllerProvider).isLoading;

    return DecoratedBox(
      decoration: CredentialFormSurfaces.panel(colors),
      child: Padding(
        padding: metrics.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoginMode) const LoginForm() else const RegisterForm(),
            SizedBox(height: metrics.sectionSpacing),
            AuthDivider(label: l10n.commonOr),
            SizedBox(height: metrics.sectionSpacing),
            AuthActionButton(
              buttonKey: const Key('auth_google_button'),
              label: isLoginMode
                  ? l10n.loginWithGoogle
                  : l10n.registerWithGoogle,
              icon: const FaIcon(FontAwesomeIcons.google, size: 18),
              minimumHeight: metrics.socialButtonHeight,
              onPressed: isGoogleLoading || isAuthLoading || isGuestLoading
                  ? null
                  : () => ref
                        .read(googleAuthControllerProvider.notifier)
                        .signInWithGoogle(),
              isLoading: isGoogleLoading,
            ),
            if (isLoginMode) ...[
              SizedBox(height: metrics.footerSpacing),
              AuthGhostTextButton(
                buttonKey: const Key('auth_guest_button'),
                label: l10n.authContinueAsGuest,
                minimumHeight: metrics.socialButtonHeight,
                onPressed: isGuestLoading || isGoogleLoading || isAuthLoading
                    ? null
                    : () => ref
                          .read(guestAuthControllerProvider.notifier)
                          .signInAnonymously(),
                isLoading: isGuestLoading,
              ),
            ] else ...[
              SizedBox(height: metrics.footerSpacing),
              AuthFooterPrompt(
                prefixText: l10n.authFooterHasAccountPrefix,
                actionText: l10n.authSwitchLoginAction,
                buttonKey: const Key('auth_switch_to_login_button'),
                onPressed: onShowLoginMode,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
