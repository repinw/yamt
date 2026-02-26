import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color seed = Color(0xFF29F006);
}

abstract final class AppSeedColors {
  static const Color lime = Color(0xFF29F006);
  static const Color blue = Color(0xFF0D47A1);
  static const Color teal = Color(0xFF00695C);
  static const Color pink = Color.fromARGB(255, 255, 0, 111);
  static const Color orange = Color(0xFFE65100);

  static const List<Color> values = <Color>[lime, blue, teal, pink, orange];
}

abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 24;
  static const double xxxxl = 32;
}

abstract final class AppInsets {
  static const EdgeInsets zero = EdgeInsets.zero;

  static const EdgeInsets page = EdgeInsets.all(AppSpacing.xl);
  static const EdgeInsets pageLarge = EdgeInsets.all(AppSpacing.xxxl);
  static const EdgeInsets authPage = EdgeInsets.symmetric(
    horizontal: AppSpacing.xxxxl,
    vertical: AppSpacing.md,
  );
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.xl);
  static const EdgeInsets listVertical = EdgeInsets.symmetric(
    vertical: AppSpacing.xl,
  );

  static const EdgeInsets snackBarMargin = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.md,
  );

  static const EdgeInsets dialogInset = EdgeInsets.symmetric(
    horizontal: AppSpacing.xxl,
  );
  static const EdgeInsets dialogPadding = EdgeInsets.fromLTRB(
    AppSpacing.xxl,
    AppSpacing.xxl,
    AppSpacing.xxl,
    AppSpacing.md,
  );
  static const EdgeInsets actionTilePadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );
}

abstract final class AppRadius {
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 24;
}

abstract final class AppThemeBackground {
  // Subtle light/dark tinting tuned against Material 3 surface tones.
  static const double lightTintAlpha = 0.04;
  static const double darkTintAlpha = 0.18;
  // Borders stay subtle in dark mode and clearer in light mode.
  static const double lightCardBorderAlpha = 0.28;
  static const double darkCardBorderAlpha = 0.18;
}

abstract final class AppSizes {
  static const double dialogIconContainer = 44;
  static const double actionChevron = 14;
  static const double welcomeIcon = 80;
  static const double inlineProgressIndicator = 20;
  static const double progressStrokeWidth = 2;
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
