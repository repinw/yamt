import 'package:material_ui/material_ui.dart';

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
  /// Extra-small radius.
  static const double xs = 4;

  /// Small radius.
  static const double sm = 8;

  /// Medium radius.
  static const double md = 14;

  /// Large radius.
  static const double lg = 16;

  /// Extra-large radius.
  static const double xl = 24;

  /// Fully rounded pill radius.
  static const double pill = 999;
}

/// Shared animation durations.
abstract final class AppDurations {
  /// Expansion duration for compact metric controls.
  static const Duration compactMetricExpansion = Duration(milliseconds: 220);

  /// Duration for one nutrition-label scan sweep.
  static const Duration scanSweep = Duration(milliseconds: 1200);

  /// Duration of the home bottom navigation indicator animation.
  static const Duration homeBottomNavIndicator = Duration(milliseconds: 180);

  /// Slide to the neighbouring diary day after an arrow tap.
  static const Duration diaryDayPageSlide = Duration(milliseconds: 300);
}

/// Shared opacity values.
abstract final class AppOpacities {
  /// Divider opacity for compact metric cards.
  static const double compactMetricDivider = 0.42;

  /// Compact search surface opacity.
  static const double compactSearchSurface = 0.72;

  /// Compact search hint opacity.
  static const double compactSearchHint = 0.82;

  /// Compact search focus border opacity.
  static const double compactSearchFocusBorder = 0.38;

  /// Compact search leading icon opacity.
  static const double compactSearchPrefixIcon = 0.78;

  /// Compact search enabled trailing icon opacity.
  static const double compactSearchTrailingIcon = 0.72;

  /// Compact search settings foreground opacity.
  static const double compactSearchSettingsForeground = 0.86;

  /// Compact search disabled control opacity.
  static const double compactSearchDisabled = 0.38;

  /// Disabled home top bar icon background opacity.
  static const double homeTopBarDisabledBackground = 0.6;

  /// Disabled home top bar icon foreground opacity.
  static const double homeTopBarDisabledForeground = 0.48;

  /// Inventory filter divider opacity.
  static const double inventoryFilterDivider = 0.45;

  /// Modal barrier opacity for lightweight bottom sheets.
  static const double modalBarrier = 0.38;

  /// Home bottom navigation border opacity.
  static const double homeBottomNavBorder = 0.5;

  /// Home bottom navigation unselected item opacity.
  static const double homeBottomNavUnselected = 0.7;

  /// Measured weigh-in dots behind the trend line in the weight chart.
  static const double weightChartScaleDot = 0.35;
}

/// Shared font-size scale for app typography.
abstract final class AppFontSizes {
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

  /// Extra-small label size for dense chrome labels.
  static const double labelXSmall = 10;

  /// Large label size from the current diary baseline.
  static const double labelLarge = 14;

  /// Small label size from the current diary baseline.
  static const double labelSmall = 11;

  /// Home tab title size for regular layouts.
  static const double homeTabTitle = headlineSmall;

  /// Home tab title size for compact layouts.
  static const double homeTabTitleCompact = titleLarge;

  /// Home bottom navigation label size.
  static const double homeBottomNavLabel = labelXSmall;

  /// Compact search field input size.
  static const double compactSearchInput = 15;
}
