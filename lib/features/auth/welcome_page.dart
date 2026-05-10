import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/auth/provider/auth_error_view_model.dart';
import 'package:yamt/features/auth/provider/auth_form_controller.dart';
import 'package:yamt/features/auth/provider/google_auth_controller.dart';
import 'package:yamt/features/auth/provider/guest_auth_controller.dart';
import 'package:yamt/features/auth/widgets/auth_layout_metrics.dart';
import 'package:yamt/features/auth/widgets/welcome_page_desktop_layout.dart';
import 'package:yamt/features/auth/widgets/welcome_page_mobile_layout.dart';
import 'package:yamt/features/shared/widgets/credential_form_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

enum _AuthFormMode { login, register }

/// Defines welcome page.
class WelcomePage extends ConsumerStatefulWidget {
  /// The welcome page.
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  _AuthFormMode _authFormMode = _AuthFormMode.login;

  bool get _isLoginMode => _authFormMode == _AuthFormMode.login;

  void _showAuthError({
    required BuildContext context,
    required AppLocalizations l10n,
    required Object error,
  }) {
    final message = ref
        .read(authErrorViewModelProvider)
        .messageFor(l10n: l10n, error: error);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    ref
      ..listen<AsyncValue<void>>(authFormControllerProvider, (previous, next) {
        _handleAsyncError(next, context, l10n);
      })
      ..listen<AsyncValue<void>>(guestAuthControllerProvider, (previous, next) {
        _handleAsyncError(next, context, l10n);
      })
      ..listen<AsyncValue<void>>(googleAuthControllerProvider, (
        previous,
        next,
      ) {
        _handleAsyncError(next, context, l10n);
      });
  }

  void _showLoginMode() {
    setState(() {
      _authFormMode = _AuthFormMode.login;
    });
  }

  void _showRegisterMode() {
    setState(() {
      _authFormMode = _AuthFormMode.register;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _listenForAuthErrors(context, l10n);
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;
          final safeHeight =
              constraints.maxHeight - mediaQuery.viewPadding.vertical;
          final minHeight = safeHeight - CredentialFormUi.pagePadding.vertical;
          final metrics = AuthLayoutMetrics.fromConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: safeHeight,
            isWide: isWide,
          );
          final scrollPadding = CredentialFormUi.pagePadding.add(
            EdgeInsets.only(
              top: mediaQuery.viewPadding.top,
              bottom: mediaQuery.viewPadding.bottom,
            ),
          );

          return SingleChildScrollView(
            padding: scrollPadding,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: minHeight > 0 ? minHeight : 0,
                  maxWidth: isWide
                      ? CredentialFormUi.maxDesktopWidth
                      : CredentialFormUi.maxContentWidth,
                ),
                child: isWide
                    ? DesktopAuthLayout(
                        isLoginMode: _isLoginMode,
                        onShowLoginMode: _showLoginMode,
                        onShowRegisterMode: _showRegisterMode,
                        metrics: metrics,
                      )
                    : MobileAuthLayout(
                        isLoginMode: _isLoginMode,
                        onShowLoginMode: _showLoginMode,
                        onShowRegisterMode: _showRegisterMode,
                        metrics: metrics,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
