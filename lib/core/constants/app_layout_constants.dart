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

/// Shared animation durations.
abstract final class AppDurations {
  /// Expansion duration for compact metric controls.
  static const Duration compactMetricExpansion = Duration(milliseconds: 220);
}

/// Shared opacity values.
abstract final class AppOpacities {
  /// Divider opacity for compact metric cards.
  static const double compactMetricDivider = 0.42;
}

/// Shared font-size scale for app typography.
abstract final class AppFontSizes {
  /// Display-small size from the current diary baseline.
  static const double displaySmall = 36;

  /// Headline-small size from the current diary baseline.
  static const double headlineSmall = 24;

  /// Large title size from the current diary baseline.
  static const double titleLarge = 22;

  /// Medium title size from the current diary baseline.
  static const double titleMedium = 16;

  /// Medium body size from the current diary baseline.
  static const double bodyMedium = 14;

  /// Small body size from the current diary baseline.
  static const double bodySmall = 12;

  /// Large label size from the current diary baseline.
  static const double labelLarge = 14;

  /// Small label size from the current diary baseline.
  static const double labelSmall = 11;

  /// Home tab title size for regular layouts.
  static const double homeTabTitle = headlineSmall;

  /// Home tab title size for compact layouts.
  static const double homeTabTitleCompact = titleLarge;

  /// Home tab subtitle size.
  static const double homeTabSubtitle = labelLarge;
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

  /// Diameter for circular home top bar icon buttons.
  static const double homeTopBarIconButton = 36;

  /// Height for compact search fields and adjacent square controls.
  static const double compactSearchControlHeight = 52;

  /// Dark theme blur for compact metric card shadows.
  static const double compactMetricCardShadowBlurDark = 22;

  /// Light theme blur for compact metric card shadows.
  static const double compactMetricCardShadowBlurLight = 16;

  /// Vertical offset for compact metric card shadows.
  static const double compactMetricCardShadowYOffset = 6;

  /// Icon size for compact metric labels.
  static const double compactMetricIcon = 16;

  /// Gap between compact metric icons and labels.
  static const double compactMetricIconLabelGap = 4;

  /// Top gap above compact metric values.
  static const double compactMetricValueTopGap = 6;

  /// Font size for compact metric labels.
  static const double compactMetricLabelFont = 12;

  /// Font size for compact metric values.
  static const double compactMetricValueFont = 16;

  /// Divider width for compact metric cards.
  static const double compactMetricDividerWidth = 1;

  /// Vertical divider height for compact metric cards.
  static const double compactMetricDividerHeight = 38;

  /// Skeleton label width for compact metric cards.
  static const double compactMetricSkeletonLabelWidth = 74;

  /// Skeleton label height for compact metric cards.
  static const double compactMetricSkeletonLabelHeight = 12;

  /// Skeleton value width for compact metric cards.
  static const double compactMetricSkeletonValueWidth = 58;

  /// Skeleton value height for compact metric cards.
  static const double compactMetricSkeletonValueHeight = 18;
}
