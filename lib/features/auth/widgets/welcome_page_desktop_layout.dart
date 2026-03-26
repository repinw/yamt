part of 'package:yamt/features/auth/welcome_page.dart';

class _DesktopAuthLayout extends StatelessWidget {
  const _DesktopAuthLayout({
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _EditorialAside(isLoginMode: isLoginMode)),
        const SizedBox(width: AppSpacing.xxxxl),
        SizedBox(
          width: AppAuthUi.maxContentWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AuthHeader(
                isLoginMode: isLoginMode,
                isWide: true,
                metrics: metrics,
              ),
              SizedBox(height: metrics.headerSpacing),
              _AuthCard(
                isLoginMode: isLoginMode,
                onShowLoginMode: onShowLoginMode,
                onShowRegisterMode: onShowRegisterMode,
                metrics: metrics,
              ),
              if (isLoginMode) ...[
                SizedBox(height: metrics.footerSpacing),
                _AuthFooterPrompt(
                  prefixText: AppLocalizations.of(
                    context,
                  )!.authFooterNoAccountPrefix,
                  actionText: AppLocalizations.of(
                    context,
                  )!.authSwitchRegisterAction,
                  buttonKey: const Key('auth_switch_to_register_button'),
                  onPressed: onShowRegisterMode,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
