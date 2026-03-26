import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

abstract final class AppReceiptReviewUi {
  static const double panelRadius = 18;
  static const double chipRadius = 8;
  static const double buttonRadius = 10;
  static const double headerButtonRadius = 20;
}

abstract final class AppReceiptReviewSurfaces {
  static BoxDecoration panelDecoration(
    ColorScheme colors, {
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? colors.surface,
      borderRadius: BorderRadius.circular(AppReceiptReviewUi.panelRadius),
      border: Border.all(color: colors.outlineVariant),
      boxShadow: [panelShadow(colors)],
    );
  }

  static BoxShadow panelShadow(ColorScheme colors) {
    return BoxShadow(
      color: colors.shadow.withValues(alpha: 0.08),
      blurRadius: 10,
      offset: const Offset(0, 2),
    );
  }
}

abstract final class AppBrandBadge {
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.xs - AppSpacing.xxs,
    vertical: AppSpacing.xxs,
  );
  static const double borderRadius = 999;
  static const double fontSize = 9;
  static const FontWeight fontWeight = FontWeight.w600;
  static const double letterSpacing = 0.6;
}

abstract final class AppInventoryEatAction {
  static const Color tint = Color(0xFF2E7D32);
  static const double backgroundAlpha = 0.24;
  static const double borderAlpha = 0.45;
  static const double iconAlpha = 0.8;
}

abstract final class AppInventoryBuyAgainAction {
  static const Color tint = Color(0xFF1565C0);
  static const double backgroundAlpha = 0.24;
  static const double borderAlpha = 0.45;
  static const double iconAlpha = 0.8;
}

class AppInventoryEatActionColors {
  const AppInventoryEatActionColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  factory AppInventoryEatActionColors.fromColorScheme(ColorScheme colors) {
    final backgroundColor = Color.alphaBlend(
      AppInventoryEatAction.tint.withValues(
        alpha: AppInventoryEatAction.backgroundAlpha,
      ),
      colors.secondaryContainer,
    );
    final borderColor = Color.alphaBlend(
      AppInventoryEatAction.tint.withValues(
        alpha: AppInventoryEatAction.borderAlpha,
      ),
      colors.outlineVariant,
    );
    final iconColor = Color.alphaBlend(
      AppInventoryEatAction.tint.withValues(
        alpha: AppInventoryEatAction.iconAlpha,
      ),
      colors.onSecondaryContainer,
    );

    return AppInventoryEatActionColors(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      iconColor: iconColor,
    );
  }

  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
}

class AppInventoryBuyAgainActionColors {
  const AppInventoryBuyAgainActionColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  factory AppInventoryBuyAgainActionColors.fromColorScheme(ColorScheme colors) {
    final backgroundColor = Color.alphaBlend(
      AppInventoryBuyAgainAction.tint.withValues(
        alpha: AppInventoryBuyAgainAction.backgroundAlpha,
      ),
      colors.primaryContainer,
    );
    final borderColor = Color.alphaBlend(
      AppInventoryBuyAgainAction.tint.withValues(
        alpha: AppInventoryBuyAgainAction.borderAlpha,
      ),
      colors.outlineVariant,
    );
    final iconColor = Color.alphaBlend(
      AppInventoryBuyAgainAction.tint.withValues(
        alpha: AppInventoryBuyAgainAction.iconAlpha,
      ),
      colors.onPrimaryContainer,
    );

    return AppInventoryBuyAgainActionColors(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      iconColor: iconColor,
    );
  }

  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
}
