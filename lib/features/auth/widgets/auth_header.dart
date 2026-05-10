import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/auth/auth_ui_constants.dart';
import 'package:yamt/features/auth/widgets/auth_layout_metrics.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Header shown above the auth card.
class AuthHeader extends StatelessWidget {
  /// Creates the auth header.
  const AuthHeader({
    required this.isLoginMode,
    required this.isWide,
    required this.metrics,
    super.key,
  });

  /// Whether login mode is active.
  final bool isLoginMode;

  /// Whether the wide layout is active.
  final bool isWide;

  /// Current layout metrics.
  final AuthLayoutMetrics metrics;

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
