import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/shared/widgets/credential_form_ui_constants.dart';

/// Auth layout sizing values derived from current constraints.
class AuthLayoutMetrics {
  /// Creates auth layout metrics.
  const AuthLayoutMetrics({
    required this.heroBadgeSize,
    required this.heroIconSize,
    required this.cardPadding,
    required this.headerSpacing,
    required this.sectionSpacing,
    required this.footerSpacing,
    required this.socialButtonHeight,
    required this.centerContent,
  });

  /// Creates responsive metrics from the available auth page constraints.
  factory AuthLayoutMetrics.fromConstraints({
    required double maxWidth,
    required double maxHeight,
    required bool isWide,
  }) {
    if (isWide) {
      return const AuthLayoutMetrics(
        heroBadgeSize: CredentialFormUi.heroBadgeSize,
        heroIconSize: CredentialFormUi.heroIconSize * 0.42,
        cardPadding: CredentialFormUi.cardPadding,
        headerSpacing: AppSpacing.xxxl,
        sectionSpacing: AppSpacing.xxxl,
        footerSpacing: AppSpacing.xxl,
        socialButtonHeight: CredentialFormUi.socialButtonHeight,
        centerContent: true,
      );
    }

    final widthScale = maxWidth < 390 ? maxWidth / 390 : 1.0;
    final heightScale = maxHeight < 780 ? maxHeight / 780 : 1.0;
    final scale = math.min(widthScale, heightScale).clamp(0.82, 1.0);

    return AuthLayoutMetrics(
      heroBadgeSize: CredentialFormUi.heroBadgeSize * scale,
      heroIconSize: CredentialFormUi.heroIconSize * 0.42 * scale,
      cardPadding: EdgeInsets.fromLTRB(
        AppSpacing.xxl * scale,
        AppSpacing.xxl * scale,
        AppSpacing.xxl * scale,
        AppSpacing.xxl * scale,
      ),
      headerSpacing: AppSpacing.xxl * scale,
      sectionSpacing: AppSpacing.xxl * scale,
      footerSpacing: AppSpacing.xl * scale,
      socialButtonHeight: math.max(
        48,
        CredentialFormUi.socialButtonHeight * scale,
      ),
      centerContent: maxHeight >= 760,
    );
  }

  /// Size of the hero badge container.
  final double heroBadgeSize;

  /// Size of the hero badge icon.
  final double heroIconSize;

  /// Padding inside the auth card.
  final EdgeInsets cardPadding;

  /// Spacing below the header.
  final double headerSpacing;

  /// Spacing between auth sections.
  final double sectionSpacing;

  /// Footer spacing inside the auth card.
  final double footerSpacing;

  /// Minimum height for social auth buttons.
  final double socialButtonHeight;

  /// Whether mobile content should be vertically centered.
  final bool centerContent;
}
