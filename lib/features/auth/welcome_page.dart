import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/auth/provider/auth_error_view_model.dart';
import 'package:yamt/features/auth/provider/auth_form_controller.dart';
import 'package:yamt/features/auth/provider/google_auth_controller.dart';
import 'package:yamt/features/auth/provider/guest_auth_controller.dart';
import 'package:yamt/features/auth/widgets/login_form.dart';
import 'package:yamt/features/auth/widgets/register_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum _AuthFormMode { login, register }

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  _AuthFormMode _authFormMode = _AuthFormMode.register;

  bool get _isLoginMode => _authFormMode == _AuthFormMode.login;

  void _showAuthError({
    required BuildContext context,
    required AppLocalizations l10n,
    required Object error,
  }) {
    final message = ref
        .read(authErrorViewModelProvider)
        .messageFor(l10n: l10n, error: error);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleAsyncError(
    AsyncValue<void> next,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    next.whenOrNull(
      error: (error, stackTrace) =>
          _showAuthError(context: context, l10n: l10n, error: error),
    );
  }

  void _listenForAuthErrors(BuildContext context, AppLocalizations l10n) {
    ref.listen<AsyncValue<void>>(authFormControllerProvider, (previous, next) {
      _handleAsyncError(next, context, l10n);
    });
    ref.listen<AsyncValue<void>>(guestAuthControllerProvider, (previous, next) {
      _handleAsyncError(next, context, l10n);
    });
    ref.listen<AsyncValue<void>>(googleAuthControllerProvider, (
      previous,
      next,
    ) {
      _handleAsyncError(next, context, l10n);
    });
  }

  void _toggleAuthMode() {
    setState(() {
      _authFormMode = _isLoginMode
          ? _AuthFormMode.register
          : _AuthFormMode.login;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _listenForAuthErrors(context, l10n);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: AppInsets.authPage,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.xxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _WelcomeHeader(l10n: l10n),
                    const SizedBox(height: AppSpacing.xxxl),
                    if (_isLoginMode)
                      const LoginForm()
                    else
                      const RegisterForm(),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton(
                      onPressed: _toggleAuthMode,
                      child: Text(
                        _isLoginMode
                            ? l10n.authSwitchToRegister
                            : l10n.authSwitchToLogin,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    _SocialAuthButtons(
                      isLoginMode: _isLoginMode,
                      onGooglePressed: () => ref
                          .read(googleAuthControllerProvider.notifier)
                          .signInWithGoogle(),
                      onGuestPressed: () => ref
                          .read(guestAuthControllerProvider.notifier)
                          .signInAnonymously(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.kitchen_outlined, size: AppSizes.welcomeIcon),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          l10n.welcomeTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.appSubtitle,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SocialAuthButtons extends ConsumerWidget {
  const _SocialAuthButtons({
    required this.isLoginMode,
    required this.onGooglePressed,
    required this.onGuestPressed,
  });

  final bool isLoginMode;
  final VoidCallback onGooglePressed;
  final VoidCallback onGuestPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isAuthFormLoading = ref.watch(authFormControllerProvider).isLoading;
    final isGoogleLoading = ref.watch(googleAuthControllerProvider).isLoading;
    final isGuestLoading = ref.watch(guestAuthControllerProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: isGoogleLoading || isAuthFormLoading
              ? null
              : onGooglePressed,
          icon: const FaIcon(FontAwesomeIcons.google, size: 18),
          label: isGoogleLoading
              ? const _ButtonProgressIndicator()
              : Text(
                  isLoginMode ? l10n.loginWithGoogle : l10n.registerWithGoogle,
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: isGuestLoading || isGoogleLoading || isAuthFormLoading
              ? null
              : onGuestPressed,
          icon: const Icon(Icons.person_outline),
          label: isGuestLoading
              ? const _ButtonProgressIndicator()
              : Text(l10n.loginAsGuest),
        ),
      ],
    );
  }
}

class _ButtonProgressIndicator extends StatelessWidget {
  const _ButtonProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: AppSizes.inlineProgressIndicator,
      height: AppSizes.inlineProgressIndicator,
      child: CircularProgressIndicator(
        strokeWidth: AppSizes.progressStrokeWidth,
      ),
    );
  }
}
