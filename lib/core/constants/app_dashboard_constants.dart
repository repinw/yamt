/// Sizes and timings of the diary dashboard grid.
abstract final class AppDashboard {
  /// Gap between two cells.
  static const double gap = 8;

  /// Inner padding of a framed tile.
  static const double tilePadding = 12;

  /// Corner radius of a framed tile.
  static const double tileRadius = 20;

  /// Largest text scale the row height follows; bigger text makes tiles
  /// show less instead of growing further.
  static const double maxRowTextScale = 1.5;

  /// Icon size in a tile caption.
  static const double captionIcon = 14;

  /// Gap between the icon and the text of a tile caption.
  static const double captionGap = 4;

  /// Size of the main icon of a small status tile, such as the overdue
  /// plans tile.
  static const double statusIcon = 24;

  /// Share of a meal row in the meals tile that the meal name takes.
  static const int mealNameFlex = 2;

  /// Share of a meal row in the meals tile that the kcal bar takes.
  static const int mealBarFlex = 3;

  /// Share of a meal row in the meals tile that the kcal number takes.
  static const int mealNumberFlex = 2;

  /// Largest share of a macro's row in the macros tile that its name or its
  /// ring takes; a longer name ends with an ellipsis, and the grams shrink
  /// into the rest.
  static const double macroNameShare = 0.7;

  /// Stroke of a large progress ring in a tile.
  static const double ringStroke = 7;

  /// Stroke of a small progress ring in a tile.
  static const double ringStrokeSmall = 4;

  /// Least height the number of a tile keeps before a caption shows below
  /// it.
  static const double numberMinHeight = 24;

  /// Height one caption line takes at text scale 1; it grows with the text.
  static const double captionLineHeight = 18;

  /// Gap between the number and the line of a tile that shows both.
  static const double tileInnerGap = 8;

  /// Width of the line of a tile's sparkline.
  static const double sparklineStroke = 2;

  /// Radius of the dot on the newest value of a tile's sparkline.
  static const double sparklineDotRadius = 3;

  /// Weekly weight change in kg below which the trend arrow lies flat; the
  /// tile shows the change with one decimal.
  static const double weightFlatKgPerWeek = 0.05;

  /// Diameter of the round edit buttons on a tile in edit mode: the corner
  /// radius, so each sits in its corner like a badge on the outline and
  /// covers little of the content. Their tap areas stay bigger.
  static const double editButtonSize = tileRadius;

  /// Icon size inside the edit buttons.
  static const double editButtonIcon = 12;

  /// Width of the outline of a tile in edit mode.
  static const double editOutline = 1.5;

  /// Scale of the tile that follows the finger.
  static const double dragLiftScale = 1.04;

  /// Opacity of the tile that follows the finger.
  static const double dragLiftOpacity = 0.92;

  /// Hold before a drag starts in edit mode; a quicker swipe scrolls.
  static const Duration editDragDelay = Duration(milliseconds: 150);

  /// Hold before the resize handle grabs; it grabs at once.
  static const Duration resizeDelay = Duration(milliseconds: 1);

  /// Tiles sliding to their new cells.
  static const Duration reflow = Duration(milliseconds: 200);

  /// Speed of the page scroll per pixel a dragged tile reaches past the
  /// edge, like a reorderable list.
  static const double autoScrollVelocity = 50;

  /// Icon size of a day type button in the day type tile.
  static const double dayTypeIcon = 18;
}
