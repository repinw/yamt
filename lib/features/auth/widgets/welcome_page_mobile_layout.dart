import 'package:flutter/material.dart';
import 'package:yamt/features/auth/widgets/auth_card.dart';
import 'package:yamt/features/auth/widgets/auth_footer_prompt.dart';
import 'package:yamt/features/auth/widgets/auth_header.dart';
import 'package:yamt/features/auth/widgets/auth_layout_metrics.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Narrow auth welcome layout.
class MobileAuthLayout extends StatelessWidget {
  /// Creates the narrow auth welcome layout.
  const MobileAuthLayout({
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
    return Column(
      mainAxisAlignment: metrics.centerContent
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeader(isLoginMode: isLoginMode, isWide: false, metrics: metrics),
        SizedBox(height: metrics.headerSpacing),
        AuthCard(
          isLoginMode: isLoginMode,
          onShowLoginMode: onShowLoginMode,
          onShowRegisterMode: onShowRegisterMode,
          metrics: metrics,
        ),
        if (isLoginMode) ...[
          SizedBox(height: metrics.sectionSpacing),
          AuthFooterPrompt(
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
