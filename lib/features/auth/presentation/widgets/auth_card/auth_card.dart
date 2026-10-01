import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/presentation/controllers/auth_form_controller.dart';
import 'package:yamt/features/auth/presentation/controllers/google_auth_controller.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_action_button/auth_action_button.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_divider/auth_divider.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_ghost_text_button/auth_ghost_text_button.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_layout_metrics/auth_layout_metrics.dart';
import 'package:yamt/features/auth/presentation/widgets/login_form/login_form.dart';
import 'package:yamt/features/shared/widgets/credential_form_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Login card with email, Google, and guest actions.
class AuthCard extends ConsumerWidget {
  /// Creates an auth card.
  const new({required this.metrics, super.key});

  /// Current layout metrics.
  final AuthLayoutMetrics metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isAuthLoading = ref.watch(authFormControllerProvider).isLoading;
    final isGoogleLoading = ref.watch(googleAuthControllerProvider).isLoading;

    return DecoratedBox(
      decoration: CredentialFormSurfaces.panel(colors),
      child: Padding(
        padding: metrics.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LoginForm(),
            SizedBox(height: metrics.sectionSpacing),
            AuthDivider(label: l10n.commonOr),
            SizedBox(height: metrics.sectionSpacing),
            AuthActionButton(
              buttonKey: const Key('auth_google_button'),
              label: l10n.loginWithGoogle,
              icon: const FaIcon(FontAwesomeIcons.google, size: 18),
              minimumHeight: metrics.socialButtonHeight,
              onPressed: isGoogleLoading || isAuthLoading
                  ? null
                  : () => ref
                        .read(googleAuthControllerProvider.notifier)
                        .signInWithGoogle(),
              isLoading: isGoogleLoading,
            ),
            SizedBox(height: metrics.footerSpacing),
            AuthGhostTextButton(
              buttonKey: const Key('auth_guest_button'),
              label: l10n.authContinueAsGuest,
              minimumHeight: metrics.socialButtonHeight,
              // The guest account is created when onboarding finishes.
              onPressed: isGoogleLoading || isAuthLoading
                  ? null
                  : () => context.go(AppRoutes.calorieGoalSetup),
            ),
          ],
        ),
      ),
    );
  }
}
