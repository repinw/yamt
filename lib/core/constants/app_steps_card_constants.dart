/// Sizes of the diary's steps card.
abstract final class AppStepsCard {
  /// Horizontal padding, in line with the budget card's content.
  static const double horizontalPadding = 18;

  /// Vertical padding.
  static const double verticalPadding = 10;

  /// Corner radius.
  static const double radius = 18;

  /// Size of the steps icon.
  static const double icon = 18;

  /// Font size of the steps number.
  static const double value = 20;

  /// Height of a day's slot in the week bars.
  static const double barsHeight = 22;

  /// Least height of the bar of the card's day, so it stays visible.
  static const double barDayMinHeight = 5;

  /// Height of the line that fills up to the steps goal.
  static const double goalLine = 5;

  /// Gap between the row and the goal line.
  static const double goalLineGap = 8;

  /// Width of one bar.
  static const double barWidth = 6;

  /// Gap between two bars.
  static const double barGap = 4;

  /// Corner radius of a bar.
  static const double barRadius = 2;

  /// How many times the goal the steps must reach to set the card on fire.
  static const int fireGoalFactor = 2;

  /// Width of the glowing rim of a card on fire.
  static const double emberRim = 2;

  /// Blur of the glow around a card on fire at its dimmest.
  static const double emberGlowMin = 18;

  /// Blur of the glow around a card on fire at its brightest.
  static const double emberGlowMax = 34;

  /// How far the glow around a card on fire spreads at its brightest.
  static const double emberGlowSpread = 4;

  /// Blur of the tight hot edge on a card on fire.
  static const double emberEdgeGlow = 8;

  /// Time the flame takes from small to large.
  static const Duration flameFlicker = Duration(milliseconds: 420);

  /// Size of the flame at its largest, as a share of the icon.
  static const double flameFlickerScale = 1.2;

  /// Time the glowing rim takes from dim to bright.
  static const Duration emberBreath = Duration(milliseconds: 1300);

  /// Time the fire takes to run once through the goal line.
  static const Duration fireRun = Duration(milliseconds: 1600);

  /// Blur of the glow above the burning goal line.
  static const double fireLineGlow = 12;

  /// Opacity of the wide glow around a card on fire, dim and bright.
  static const double emberGlowAlphaMin = 0.3;

  /// Opacity of the wide glow around a card on fire at its brightest.
  static const double emberGlowAlphaMax = 0.6;

  /// Opacity of the tight hot edge on a card on fire at its dimmest.
  static const double emberEdgeAlphaMin = 0.5;

  /// Opacity of the tight hot edge on a card on fire at its brightest.
  static const double emberEdgeAlphaMax = 0.95;

  /// Opacity of the heat at the lower edge of a card on fire at its dimmest.
  static const double emberHeatAlphaMin = 0.16;

  /// Opacity of the heat at the lower edge of a card on fire at its
  /// brightest.
  static const double emberHeatAlphaMax = 0.42;

  /// Where the heat starts in the card: above the middle, as an alignment.
  static const double emberHeatStart = -0.5;

  /// Size of the flame at its smallest, as a share of the icon.
  static const double flameFlickerScaleMin = 0.92;

  /// Opacity of the glow above the burning goal line.
  static const double fireLineGlowAlpha = 0.7;

  /// How far the glow of the burning goal line rises.
  static const double fireLineGlowRise = 4;

  /// Where a fire stands with Reduce Motion: halfway.
  static const double fireStill = 0.5;

  /// Steps that the menu's minus and plus change the goal by.
  static const int goalStep = 500;

  /// The usual goals the menu offers with one tap.
  static const List<int> goalPresets = [5000, 7500, 10000];
}
