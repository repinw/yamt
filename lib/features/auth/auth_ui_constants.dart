import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

abstract final class AppAuthUi {
  static const double maxContentWidth = 420;
  static const double maxDesktopWidth = 1120;
  static const double heroIconSize = 84;
  static const double heroBadgeSize = 88;
  static const double cardRadius = 32;
  static const double fieldRadius = 18;
  static const double buttonRadius = 18;
  static const double socialButtonHeight = 56;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.xxl,
    vertical: AppSpacing.xxl,
  );

  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(
    AppSpacing.xxxl,
    AppSpacing.xxxl,
    AppSpacing.xxxl,
    AppSpacing.xxxl,
  );
}

abstract final class AppAuthSurfaces {
  static BoxDecoration panel(ColorScheme colors) {
    return BoxDecoration(
      color: colors.surfaceContainerLowest.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(AppAuthUi.cardRadius),
      border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.12)),
      boxShadow: [
        BoxShadow(
          color: colors.shadow.withValues(alpha: 0.08),
          blurRadius: 40,
          offset: const Offset(0, 24),
        ),
      ],
    );
  }

  static BoxDecoration heroBadge(ColorScheme colors) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colors.primaryContainer,
          Color.alphaBlend(
            colors.primary.withValues(alpha: 0.22),
            colors.primaryContainer,
          ),
        ],
      ),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      boxShadow: [
        BoxShadow(
          color: colors.primary.withValues(alpha: 0.16),
          blurRadius: 28,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }

  static BoxDecoration divider(ColorScheme colors) {
    return BoxDecoration(
      color: colors.outlineVariant.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(999),
    );
  }

  static BoxDecoration editorialAside(ColorScheme colors) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.surfaceContainerLow.withValues(alpha: 0.9),
          colors.surfaceContainerLowest.withValues(alpha: 0.95),
        ],
      ),
      borderRadius: BorderRadius.circular(AppAuthUi.cardRadius),
      border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.1)),
      boxShadow: [
        BoxShadow(
          color: colors.shadow.withValues(alpha: 0.05),
          blurRadius: 36,
          offset: const Offset(0, 20),
        ),
      ],
    );
  }
}
