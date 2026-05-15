import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_card/auth_card.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_footer_prompt/auth_footer_prompt.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_header/auth_header.dart';
import 'package:yamt/features/auth/presentation/widgets/auth_layout_metrics/auth_layout_metrics.dart';
import 'package:yamt/features/auth/presentation/widgets/welcome_page_editorial_aside/welcome_page_editorial_aside.dart';
import 'package:yamt/features/shared/widgets/credential_form_ui_constants.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Wide auth welcome layout.
class DesktopAuthLayout extends StatelessWidget {
  /// Creates the wide auth welcome layout.
  const DesktopAuthLayout({
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: EditorialAside(isLoginMode: isLoginMode)),
        const SizedBox(width: AppSpacing.xxxxl),
        SizedBox(
          width: CredentialFormUi.maxContentWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                isLoginMode: isLoginMode,
                isWide: true,
                metrics: metrics,
              ),
              SizedBox(height: metrics.headerSpacing),
              AuthCard(
                isLoginMode: isLoginMode,
                onShowLoginMode: onShowLoginMode,
                onShowRegisterMode: onShowRegisterMode,
                metrics: metrics,
              ),
              if (isLoginMode) ...[
                SizedBox(height: metrics.footerSpacing),
                AuthFooterPrompt(
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
