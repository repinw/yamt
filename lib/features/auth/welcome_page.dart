import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/provider/auth_error_view_model.dart';
import 'package:yamt/features/auth/provider/auth_form_controller.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateChangesProvider);
    final authUser = authState is AsyncData<User?> ? authState.value : null;
    if (authUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(AppRoutes.home);
        }
      });
    }

    final authFormState = ref.watch(authFormControllerProvider);
    final isAuthFormLoading = authFormState.isLoading;
    final googleAuthState = ref.watch(googleAuthControllerProvider);
    final isGoogleLoading = googleAuthState.isLoading;
    final guestAuthState = ref.watch(guestAuthControllerProvider);
    final isGuestLoading = guestAuthState.isLoading;

    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          context.go(AppRoutes.home);
        }
      });
    });

    ref.listen<AsyncValue<void>>(authFormControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) =>
            _showAuthError(context: context, l10n: l10n, error: error),
      );
    });

    ref.listen<AsyncValue<void>>(guestAuthControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) =>
            _showAuthError(context: context, l10n: l10n, error: error),
      );
    });
    ref.listen<AsyncValue<void>>(googleAuthControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, stackTrace) =>
            _showAuthError(context: context, l10n: l10n, error: error),
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.kitchen_outlined, size: 80),
                    const SizedBox(height: 24),
                    Text(
                      l10n.welcomeTitle,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.appSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_authFormMode == _AuthFormMode.login)
                        const LoginForm()
                      else
                        const RegisterForm(),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _authFormMode = _authFormMode == _AuthFormMode.login
                                ? _AuthFormMode.register
                                : _AuthFormMode.login;
                          });
                        },
                        child: Text(
                          _authFormMode == _AuthFormMode.login
                              ? l10n.authSwitchToRegister
                              : l10n.authSwitchToLogin,
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: isGoogleLoading || isAuthFormLoading
                            ? null
                            : () => ref
                                  .read(googleAuthControllerProvider.notifier)
                                  .signInWithGoogle(),
                        icon: const FaIcon(FontAwesomeIcons.google, size: 18),
                        label: isGoogleLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _authFormMode == _AuthFormMode.login
                                    ? l10n.loginWithGoogle
                                    : l10n.registerWithGoogle,
                              ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed:
                            isGuestLoading ||
                                isGoogleLoading ||
                                isAuthFormLoading
                            ? null
                            : () => ref
                                  .read(guestAuthControllerProvider.notifier)
                                  .signInAnonymously(),
                        icon: const Icon(Icons.person_outline),
                        label: isGuestLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.loginAsGuest),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
