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

  /// Width of the selected-item indicator in the home bottom navigation.
  static const double homeBottomNavIndicatorWidth = 16;

  /// Height of the selected-item indicator in the home bottom navigation.
  static const double homeBottomNavIndicatorHeight = 2;

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

  /// Diameter for circular home top bar icon buttons.
  static const double homeTopBarIconButton = 36;

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
}
