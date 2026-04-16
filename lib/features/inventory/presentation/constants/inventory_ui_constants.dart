import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Defines app receipt review ui.
abstract final class AppReceiptReviewUi {
  /// The panel radius.
  static const double panelRadius = 18;

  /// The chip radius.
  static const double chipRadius = 8;

  /// The button radius.
  static const double buttonRadius = 10;

  /// The header button radius.
  static const double headerButtonRadius = 20;
}

/// Defines app receipt review surfaces.
abstract final class AppReceiptReviewSurfaces {
  /// Panel decoration.
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

  /// Panel shadow.
  static BoxShadow panelShadow(ColorScheme colors) {
    return BoxShadow(
      color: colors.shadow.withValues(alpha: 0.08),
      blurRadius: 10,
      offset: const Offset(0, 2),
    );
  }
}

/// Defines app brand badge.
abstract final class AppBrandBadge {
  /// The padding.
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.xs - AppSpacing.xxs,
    vertical: AppSpacing.xxs,
  );

  /// The border radius.
  static const double borderRadius = 999;

  /// The font size.
  static const double fontSize = 9;

  /// The font weight.
  static const FontWeight fontWeight = FontWeight.w600;

  /// The letter spacing.
  static const double letterSpacing = 0.6;
}

/// Defines app inventory eat action.
abstract final class AppInventoryEatAction {
  /// The tint.
  static const Color tint = Color(0xFF2E7D32);

  /// The background alpha.
  static const double backgroundAlpha = 0.24;

  /// The border alpha.
  static const double borderAlpha = 0.45;

  /// The icon alpha.
  static const double iconAlpha = 0.8;
}

/// Defines app inventory buy again action.
abstract final class AppInventoryBuyAgainAction {
  /// The tint.
  static const Color tint = Color(0xFF1565C0);

  /// The background alpha.
  static const double backgroundAlpha = 0.24;

  /// The border alpha.
  static const double borderAlpha = 0.45;

  /// The icon alpha.
  static const double iconAlpha = 0.8;
}

/// Defines app inventory item visuals.
abstract final class AppInventoryItemVisuals {
  /// The fallback emoji.
  static const String fallbackEmoji = '🍽️';
}

/// Defines app inventory eat action colors.
class AppInventoryEatActionColors {
  /// The app inventory eat action colors.
  const AppInventoryEatActionColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  /// Creates a [AppInventoryEatActionColors] for from color scheme.
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

  /// The background color.
  final Color backgroundColor;

  /// The border color.
  final Color borderColor;

  /// The icon color.
  final Color iconColor;
}

/// Defines app inventory buy again action colors.
class AppInventoryBuyAgainActionColors {
  /// The app inventory buy again action colors.
  const AppInventoryBuyAgainActionColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  /// Creates a [AppInventoryBuyAgainActionColors] for from color scheme.
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

  /// The background color.
  final Color backgroundColor;

  /// The border color.
  final Color borderColor;

  /// The icon color.
  final Color iconColor;
}
