import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/auth/auth_ui_constants.dart';
import 'package:yamt/features/auth/provider/auth_error_view_model.dart';
import 'package:yamt/features/auth/provider/auth_form_controller.dart';
import 'package:yamt/features/auth/provider/google_auth_controller.dart';
import 'package:yamt/features/auth/provider/guest_auth_controller.dart';
import 'package:yamt/features/auth/widgets/login_form.dart';
import 'package:yamt/features/auth/widgets/register_form.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'widgets/welcome_page_desktop_layout.dart';
part 'widgets/welcome_page_editorial_aside.dart';
part 'widgets/welcome_page_mobile_layout.dart';

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
          final minHeight = safeHeight - AppAuthUi.pagePadding.vertical;
          final metrics = _AuthLayoutMetrics.fromConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: safeHeight,
            isWide: isWide,
          );
          final scrollPadding = AppAuthUi.pagePadding.add(
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
                      ? AppAuthUi.maxDesktopWidth
                      : AppAuthUi.maxContentWidth,
                ),
                child: isWide
                    ? _DesktopAuthLayout(
                        isLoginMode: _isLoginMode,
                        onShowLoginMode: _showLoginMode,
                        onShowRegisterMode: _showRegisterMode,
                        metrics: metrics,
                      )
                    : _MobileAuthLayout(
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

class _AuthLayoutMetrics {
  const _AuthLayoutMetrics({
    required this.heroBadgeSize,
    required this.heroIconSize,
    required this.cardPadding,
    required this.headerSpacing,
    required this.sectionSpacing,
    required this.footerSpacing,
    required this.socialButtonHeight,
    required this.centerContent,
  });

  factory _AuthLayoutMetrics.fromConstraints({
    required double maxWidth,
    required double maxHeight,
    required bool isWide,
  }) {
    if (isWide) {
      return const _AuthLayoutMetrics(
        heroBadgeSize: AppAuthUi.heroBadgeSize,
        heroIconSize: AppAuthUi.heroIconSize * 0.42,
        cardPadding: AppAuthUi.cardPadding,
        headerSpacing: AppSpacing.xxxl,
        sectionSpacing: AppSpacing.xxxl,
        footerSpacing: AppSpacing.xxl,
        socialButtonHeight: AppAuthUi.socialButtonHeight,
        centerContent: true,
      );
    }

    final widthScale = maxWidth < 390 ? maxWidth / 390 : 1.0;
    final heightScale = maxHeight < 780 ? maxHeight / 780 : 1.0;
    final scale = math.min(widthScale, heightScale).clamp(0.82, 1.0);

    return _AuthLayoutMetrics(
      heroBadgeSize: AppAuthUi.heroBadgeSize * scale,
      heroIconSize: AppAuthUi.heroIconSize * 0.42 * scale,
      cardPadding: EdgeInsets.fromLTRB(
        AppSpacing.xxl * scale,
        AppSpacing.xxl * scale,
        AppSpacing.xxl * scale,
        AppSpacing.xxl * scale,
      ),
      headerSpacing: AppSpacing.xxl * scale,
      sectionSpacing: AppSpacing.xxl * scale,
      footerSpacing: AppSpacing.xl * scale,
      socialButtonHeight: math.max(48, AppAuthUi.socialButtonHeight * scale),
      centerContent: maxHeight >= 760,
    );
  }

  final double heroBadgeSize;
  final double heroIconSize;
  final EdgeInsets cardPadding;
  final double headerSpacing;
  final double sectionSpacing;
  final double footerSpacing;
  final double socialButtonHeight;
  final bool centerContent;
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({
    required this.isLoginMode,
    required this.isWide,
    required this.metrics,
  });

  final bool isLoginMode;
  final bool isWide;
  final _AuthLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final isCentered = isLoginMode && !isWide;

    return Column(
      crossAxisAlignment: isCentered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (isLoginMode) ...[
          Align(
            alignment: isCentered ? Alignment.center : Alignment.centerLeft,
            child: DecoratedBox(
              decoration: AppAuthSurfaces.heroBadge(colors),
              child: SizedBox(
                key: const Key('auth_header_badge'),
                width: metrics.heroBadgeSize,
                height: metrics.heroBadgeSize,
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  size: metrics.heroIconSize,
                ),
              ),
            ),
          ),
          SizedBox(height: metrics.headerSpacing),
        ],
        Text(
          isLoginMode ? l10n.authBrandTitle : l10n.authRegisterTitle,
          textAlign: isCentered ? TextAlign.center : TextAlign.start,
          style: textTheme.displaySmall?.copyWith(
            color: colors.onSurface,
            height: 0.98,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isLoginMode ? l10n.authBrandSubtitle : l10n.authRegisterSubtitle,
          textAlign: isCentered ? TextAlign.center : TextAlign.start,
          style: isLoginMode
              ? textTheme.labelLarge?.copyWith(color: colors.onSurfaceVariant)
              : textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _AuthCard extends ConsumerWidget {
  const _AuthCard({
    required this.isLoginMode,
    required this.onShowLoginMode,
    required this.onShowRegisterMode,
    required this.metrics,
  });

  final bool isLoginMode;
  final VoidCallback onShowLoginMode;
  final VoidCallback onShowRegisterMode;
  final _AuthLayoutMetrics metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isAuthLoading = ref.watch(authFormControllerProvider).isLoading;
    final isGoogleLoading = ref.watch(googleAuthControllerProvider).isLoading;
    final isGuestLoading = ref.watch(guestAuthControllerProvider).isLoading;

    return DecoratedBox(
      decoration: AppAuthSurfaces.panel(colors),
      child: Padding(
        padding: metrics.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoginMode) const LoginForm() else const RegisterForm(),
            SizedBox(height: metrics.sectionSpacing),
            _AuthDivider(label: l10n.commonOr),
            SizedBox(height: metrics.sectionSpacing),
            _AuthActionButton(
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
              _AuthGhostTextButton(
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
              _AuthFooterPrompt(
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

class _AuthDivider extends StatelessWidget {
  const _AuthDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: AppAuthSurfaces.divider(colors),
            child: const SizedBox(height: 1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.outlineVariant),
          ),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: AppAuthSurfaces.divider(colors),
            child: const SizedBox(height: 1),
          ),
        ),
      ],
    );
  }
}

class _AuthActionButton extends StatelessWidget {
  const _AuthActionButton({
    required this.buttonKey,
    required this.label,
    required this.icon,
    required this.minimumHeight,
    required this.onPressed,
    required this.isLoading,
  });

  final Key buttonKey;
  final String label;
  final Widget icon;
  final double minimumHeight;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      key: buttonKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(minimumHeight),
        backgroundColor: colors.surfaceContainerLowest,
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.22)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppAuthUi.buttonRadius),
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: AppSizes.inlineProgressIndicator,
              height: AppSizes.inlineProgressIndicator,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.progressStrokeWidth,
                color: colors.primary,
              ),
            )
          : icon,
      label: Text(label),
    );
  }
}

class _AuthGhostTextButton extends StatelessWidget {
  const _AuthGhostTextButton({
    required this.buttonKey,
    required this.label,
    required this.minimumHeight,
    required this.onPressed,
    required this.isLoading,
  });

  final Key buttonKey;
  final String label;
  final double minimumHeight;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextButton(
      key: buttonKey,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size.fromHeight(minimumHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppAuthUi.buttonRadius),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: AppSizes.inlineProgressIndicator,
              height: AppSizes.inlineProgressIndicator,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.progressStrokeWidth,
                color: colors.primary,
              ),
            )
          : Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
    );
  }
}

class _AuthFooterPrompt extends StatelessWidget {
  const _AuthFooterPrompt({
    required this.prefixText,
    required this.actionText,
    required this.buttonKey,
    required this.onPressed,
  });

  final String prefixText;
  final String actionText;
  final Key buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prefixText,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        TextButton(
          key: buttonKey,
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(actionText),
        ),
      ],
    );
  }
}
