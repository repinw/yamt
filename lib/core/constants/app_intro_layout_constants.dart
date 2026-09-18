/// Layout tokens of the calorie onboarding intro.
abstract final class AppIntroLayout {
  /// Space reserved above page content for the chapter chrome, including the
  /// gap between the chapter counter and the page kicker.
  static const double chromeClearance = 72;

  /// Space reserved below page content for the intro controls.
  static const double controlsClearance = 96;

  /// Diameter of the illustrated badge on the story pages.
  static const double storyBadge = 112;

  /// Icon size inside the story badge.
  static const double storyIcon = 56;

  /// Height of a scroll wheel when the page scrolls instead of filling.
  static const double wheelHeight = 112;

  /// Height of one item inside the vertical scroll wheels.
  static const double wheelItemExtent = 34;

  /// Page height below which input pages scroll instead of filling.
  static const double fillLayoutMinHeight = 520;

  /// Room one picker card needs before it fills instead of scrolling.
  static const double fillMinHeightOnePicker = 140;

  /// Room two picker blocks need before they fill instead of scrolling.
  static const double fillMinHeightTwoPickers = 300;

  /// Text scale above which input pages scroll instead of filling.
  static const double fillLayoutMaxTextScale = 1.3;

  /// Curvature of the vertical scroll wheels.
  static const double wheelDiameterRatio = 1.6;

  /// Selection band opacity of the vertical scroll wheels.
  static const double wheelSelectionOpacity = 0.12;

  /// Opacity of the items above and below the selected wheel item.
  static const double wheelOffCenterOpacity = 0.45;

  /// Opacity of the glass surfaces that sit on the animated backdrop.
  static const double glassOpacity = 0.55;

  /// Diameter of the icon badge on a choice card.
  static const double choiceIconBadge = 36;

  /// Icon size inside the choice card badge.
  static const double choiceIcon = 20;

  /// Border width of the picker cards.
  static const double cardBorderWidth = 1.5;

  /// Border width of a selectable card.
  static const double choiceBorderWidth = 2;

  /// Tint of a selected choice card.
  static const double choiceSelectedOpacity = 0.05;

  /// Tint of a selected gender card.
  static const double genderSelectedOpacity = 0.12;

  /// Tint behind the icon of a selected gender card.
  static const double genderIconOpacity = 0.18;

  /// Side length of a weekday chip.
  static const double weekdayChip = 38;

  /// Tint of an unselected weekday chip.
  static const double weekdayIdleOpacity = 0.5;

  /// Transition duration of the selectable cards.
  static const Duration selectionTransition = Duration(milliseconds: 200);

  /// Border opacity of the intro controls.
  static const double controlBorderOpacity = 0.45;

  /// Height of one progress segment in the chapter chrome.
  static const double progressSegmentHeight = 3;

  /// Width of an inactive progress segment.
  static const double progressSegmentWidth = 6;

  /// Width of the active progress segment.
  static const double progressSegmentActiveWidth = 18;

  /// Cycle of the faster backdrop blob.
  static const Duration backdropSlowCycle = Duration(seconds: 9);

  /// Cycle of the slower backdrop blob.
  static const Duration backdropSlowerCycle = Duration(seconds: 13);

  /// Duration of the accent crossfade between chapters.
  static const Duration backdropAccentFade = Duration(milliseconds: 650);

  /// Diameter of the large backdrop blob, relative to the shortest side.
  static const double backdropBlobLarge = 1.15;

  /// Diameter of the small backdrop blob, relative to the shortest side.
  static const double backdropBlobSmall = 0.95;

  /// How much a backdrop blob grows over its cycle.
  static const double backdropBreath = 0.12;

  /// Center opacity of a backdrop blob.
  static const double backdropBlobOpacity = 0.22;

  /// Cycle of the marching stream dashes.
  static const Duration streamCycle = Duration(seconds: 8);

  /// Length of one stream dash.
  static const double streamDash = 8;

  /// Gap between two stream dashes.
  static const double streamGap = 14;

  /// Stroke width of the leading stream line.
  static const double streamStrokeWide = 2.5;

  /// Stroke width of the trailing stream line.
  static const double streamStrokeThin = 2;

  /// Opacity of the stream lines.
  static const double streamOpacity = 0.4;

  /// Opacity of the vignette at the top and bottom of a page.
  static const double vignetteOpacity = 0.55;

  /// Height of the weekly depot chart.
  static const double depotChartHeight = 96;

  /// Fill opacity of the story badge.
  static const double storyBadgeOpacity = 0.16;

  /// Border opacity of the story badge.
  static const double storyBadgeBorderOpacity = 0.35;

  /// Letter spacing of the chapter kicker and counter.
  static const double kickerSpacing = 1.4;

  /// Line height of the chapter headline.
  static const double titleHeight = 1.15;
}
