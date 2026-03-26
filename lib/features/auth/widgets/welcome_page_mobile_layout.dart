part of 'package:yamt/features/auth/welcome_page.dart';

class _MobileAuthLayout extends StatelessWidget {
  const _MobileAuthLayout({
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
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: metrics.centerContent
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthHeader(isLoginMode: isLoginMode, isWide: false, metrics: metrics),
        SizedBox(height: metrics.headerSpacing),
        _AuthCard(
          isLoginMode: isLoginMode,
          onShowLoginMode: onShowLoginMode,
          onShowRegisterMode: onShowRegisterMode,
          metrics: metrics,
        ),
        if (isLoginMode) ...[
          SizedBox(height: metrics.sectionSpacing),
          _AuthFooterPrompt(
            prefixText: AppLocalizations.of(context)!.authFooterNoAccountPrefix,
            actionText: AppLocalizations.of(context)!.authSwitchRegisterAction,
            buttonKey: const Key('auth_switch_to_register_button'),
            onPressed: onShowRegisterMode,
          ),
        ],
      ],
    );
  }
}
