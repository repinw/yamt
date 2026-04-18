import 'package:flutter/material.dart';

/// Shared spacing scale for layout and component padding.
abstract final class AppSpacing {
  /// Extra-extra-small spacing.
  static const double xxs = 2;

  /// Extra-small spacing.
  static const double xs = 8;

  /// Small spacing.
  static const double sm = 10;

  /// Medium spacing.
  static const double md = 12;

  /// Large spacing.
  static const double lg = 14;

  /// Extra-large spacing.
  static const double xl = 16;

  /// Extra-extra-large spacing.
  static const double xxl = 20;

  /// Triple extra-large spacing.
  static const double xxxl = 24;

  /// Quadruple extra-large spacing.
  static const double xxxxl = 32;
}

/// Shared edge insets used across the app.
abstract final class AppInsets {
  /// Zero inset.
  static const EdgeInsets zero = EdgeInsets.zero;

  /// Default page padding.
  static const EdgeInsets page = EdgeInsets.all(AppSpacing.xl);

  /// Spacious page padding.
  static const EdgeInsets pageLarge = EdgeInsets.all(AppSpacing.xxxl);

  /// Default card padding.
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.xl);

  /// Margin used for floating snack bars.
  static const EdgeInsets snackBarMargin = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.md,
  );

  /// Outer inset for dialogs.
  static const EdgeInsets dialogInset = EdgeInsets.symmetric(
    horizontal: AppSpacing.xxl,
  );

  /// Internal dialog content padding.
  static const EdgeInsets dialogPadding = EdgeInsets.fromLTRB(
    AppSpacing.xxl,
    AppSpacing.xxl,
    AppSpacing.xxl,
    AppSpacing.md,
  );

  /// Padding used by action list tiles.
  static const EdgeInsets actionTilePadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );
}

/// Shared corner radii.
abstract final class AppRadius {
  /// Medium radius.
  static const double md = 14;

  /// Large radius.
  static const double lg = 16;

  /// Extra-large radius.
  static const double xl = 24;
}

/// Shared fixed dimensions used by widgets.
abstract final class AppSizes {
  /// Size of icon container in dialogs.
  static const double dialogIconContainer = 44;

  /// Width of action chevrons.
  static const double actionChevron = 14;

  /// Size of welcome screen icon.
  static const double welcomeIcon = 80;

  /// Size of inline progress indicators.
  static const double inlineProgressIndicator = 20;

  /// Stroke width for progress indicators.
  static const double progressStrokeWidth = 2;

  /// Base clearance reserved for the floating home shell bottom chrome.
  static const double homeShellBottomBarClearance = 96;
}
