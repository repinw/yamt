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

  /// Height of captured-image scan previews.
  static const double scanPreviewHeight = 220;

  /// Height of animated scan lines.
  static const double scanLineHeight = 3;

  /// Standard one-physical-line divider height.
  static const double dividerThickness = 1;

  /// Base clearance reserved for the home shell bottom chrome.
  static const double homeShellBottomBarClearance = 56;

  /// Icon size in the home bottom navigation.
  static const double homeBottomNavIcon = 20;

  /// Icon size in snack bars.
  static const double snackBarIcon = 20;

  /// Height of the selected-item indicator in the home bottom navigation.
  static const double homeBottomNavIndicatorHeight = 3;

  /// Max width for settings-style content columns.
  static const double narrowContentMaxWidth = 560;

  /// Height of the thin progress bars in the diary macro strip.
  static const double stripProgressBarHeight = 4;

  /// Stroke width of the diagonal stripes that mark a macro's overage.
  static const double overflowStripeWidth = 1.5;

  /// Horizontal distance between the overage stripes.
  static const double overflowStripeSpacing = 4;

  /// Border width that separates a count badge from the image below it.
  static const double badgeBorderWidth = 2;

  /// Minimum size of a tap target.
  static const double minTapTarget = 48;

  /// Height of a full-width primary action button.
  static const double primaryActionHeight = 56;

  /// Width of the drawn barcode icon when no icon size is set.
  static const double barcodeIcon = 20;

  /// Height of the drawn barcode icon relative to its width.
  static const double barcodeIconAspect = 0.75;

  /// Width of each side slot of the diary top bar, so the day stays
  /// centered.
  static const double diaryTopBarSide = 88;

  /// Height for compact search fields and adjacent square controls.
  static const double compactSearchControlHeight = 52;

  /// Width reserved for compact search leading icon.
  static const double compactSearchPrefixWidth = 42;

  /// Size for compact search inline icon buttons.
  static const double compactSearchInlineAction = 40;

  /// Icon size for compact search controls.
  static const double compactSearchIcon = 18;

  /// Icon size for compact search settings button.
  static const double compactSearchSettingsIcon = 21;

  /// Size of small progress spinners, such as in search fields and tiles.
  static const double smallProgressIndicator = 16;

  /// Icon size for segmented controls.
  static const double segmentedControlIcon = 16;

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

  /// Reserved height for compact metric values.
  static const double compactMetricValueSlotHeight = 24;

  /// Divider width for compact metric cards.
  static const double compactMetricDividerWidth = 1;

  /// Vertical divider height for compact metric cards.
  static const double compactMetricDividerHeight = 38;

  /// Skeleton value width for compact metric cards.
  static const double compactMetricSkeletonValueWidth = 58;

  /// Skeleton value height for compact metric cards.
  static const double compactMetricSkeletonValueHeight = 18;

  /// Line width of the trend weight in the weight chart.
  static const double weightChartTrendLineWidth = 3;

  /// Dot radius of a measured weigh-in in the weight chart.
  static const double weightChartScaleDotRadius = 2.5;

  /// Icon inside an icon badge.
  static const double iconBadgeIcon = 18;

  /// Edge length of the household invite QR code.
  static const double householdInviteQrCode = 200;

  /// Edge length of the scan window for QR codes.
  static const double qrScanWindow = 240;

  /// Most product images in a collage of several foods.
  static const int collageImages = 4;

  /// Thickness of a thin divider line.
  static const double hairline = 1;

  /// Edge length of the tilted initial tile on the profile and in the menu.
  static const double profileInitialTile = 44;

  /// Edge length of the icon tile of a side menu entry.
  static const double homeMenuIconTile = 34;

  /// Icon inside a side menu icon tile.
  static const double homeMenuIcon = 18;

  /// Height of the recent weight chart on the profile.
  static const double profileWeightChart = 64;

  /// Smallest weight range in kg the profile chart spans, so small swings
  /// do not look steep.
  static const double profileWeightChartMinRangeKg = 1;

  /// Edge length of a macro color square on the profile.
  static const double profileMacroSquare = 8;

  /// Scale of the home page while the side menu is open.
  static const double homeSlideMenuPageScale = 0.7;

  /// Left edge of the scaled home page, as a share of the screen width.
  static const double homeSlideMenuPageLeft = 0.66;

  /// Top edge of the scaled home page, as a share of the screen height.
  static const double homeSlideMenuPageTop = 0.15;

  /// Scale of the faded card behind the home page.
  static const double homeSlideMenuGhostScale = 0.62;

  /// Left edge of the faded card, as a share of the screen width.
  static const double homeSlideMenuGhostLeft = 0.615;

  /// Top edge of the faded card, as a share of the screen height.
  static const double homeSlideMenuGhostTop = 0.2;

  /// Width of the side menu entries, as a share of the screen width.
  static const double homeSlideMenuContentWidth = 0.62;

  /// Share of the width that the action panel on the right uses; narrower
  /// than the side menu, so its icons clear the shadow of the slid page.
  static const double homeActionPanelContentWidth = 0.54;

  /// Corner radius of the scaled home page, before scaling.
  static const double homeSlideMenuPageRadius = 36;

  /// Blur of the shadow under the scaled home page.
  static const double homeSlideMenuPageShadowBlur = 60;

  /// Downward offset of the shadow under the scaled home page.
  static const double homeSlideMenuPageShadowOffset = 24;

  /// Tap area of a labeled header tool.
  static const double headerTool = 56;

  /// Icon or emoji of a labeled header tool.
  static const double headerToolSymbol = 20;

  /// Gap between the symbol and the word of a labeled header tool.
  static const double headerToolGap = 4;

  /// Icon tile in front of a Mehr sheet entry.
  static const double moreEntryIconTile = 40;
}
