/// Sizes of the food label look: thick outlines, label rules, the ruler
/// slider and the tilted image tile.
abstract final class AppFoodLabel {
  /// Edge length of the tilted image tile.
  static const double imageTile = 76;

  /// Tilt of the image tile in radians (about -3 degrees).
  static const double imageTilt = -0.052;

  /// Icon inside the image tile when there is no image.
  static const double imageFallbackIcon = 40;

  /// Width of the thick outlines.
  static const double outline = 2;

  /// Width of the thin frame of a small chip.
  static const double chipOutline = 1.5;

  /// Line under the nutrition label header.
  static const double labelHeaderRule = 6;

  /// Line under the energy row.
  static const double labelEnergyRule = 3;

  /// Offset of the hard button shadow.
  static const double buttonShadow = 4;

  /// Width of the per-100 column of the nutrition label.
  static const double per100Column = 68;

  /// Width of the eaten column of the nutrition label.
  static const double eatenColumn = 76;

  /// Height of the tick band of the ruler.
  static const double rulerTicks = 26;

  /// Number of tick gaps on the ruler.
  static const int rulerTickCount = 18;

  /// Every n-th tick is a long one.
  static const int rulerLongTickEvery = 3;

  /// Width of the notch that shows a mark on the ruler.
  static const double rulerMarkTick = 3;

  /// Height of a mark chip on the ruler.
  static const double rulerMark = 26;

  /// Width of the amount field.
  static const double amountField = 128;

  /// Width of a small number field inside a line of text.
  static const double inlineAmountField = 72;

  /// Space above and below a mark chip so its tap target reaches 48.
  static const double rulerMarkTapPadding = 11;

  /// Letter spacing of the brand line.
  static const double brandTracking = 1.6;

  /// Letter spacing of the bottom navigation labels.
  static const double navLabelTracking = 0.8;

  /// Opacity of the slider's touch halo.
  static const double sliderOverlayAlpha = 0.24;

  /// Length of one dash of a dashed line.
  static const double dash = 6;

  /// Height of the diary kcal bar under the ruler.
  static const double kcalBar = 14;

  /// Opacity of each quarter of the diary kcal bar, from the first to the
  /// last. Each quarter is a lighter step of the accent.
  static const List<double> kcalQuarterAlphas = [1, 0.74, 0.52, 0.34];

  /// Height of a diary macro bar.
  static const double macroBar = 8;

  /// Gap between the segments of a diary macro bar.
  static const double macroSegmentGap = 3;

  /// Width of the label column of a diary macro row.
  static const double macroLabelColumn = 58;

  /// Width of the value column of a diary macro row.
  static const double macroValueColumn = 112;

  /// Highest HSL lightness of macro colored text on light paper, so bright
  /// macro colors such as the fat yellow stay readable.
  static const double lightLabelMaxLightness = 0.38;
}
