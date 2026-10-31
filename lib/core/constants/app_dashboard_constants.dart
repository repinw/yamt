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

  /// Diameter of the round edit buttons on a tile in edit mode.
  static const double editButtonSize = 28;

  /// Icon size inside the edit buttons.
  static const double editButtonIcon = 16;

  /// Gap between an edit button and the tile's corner.
  static const double editButtonInset = 4;

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

  /// Diameter of a day mark in the week tile.
  static const double weekMark = 14;

  /// Diameter of the selected day's mark in the week tile.
  static const double weekMarkSelected = 18;

  /// Icon size inside a week tile day mark.
  static const double weekMarkIcon = 10;

  /// Outline of a planned or today mark in the week tile.
  static const double weekMarkOutline = 1.5;

  /// Gap between the balance number and the day marks of a wide week tile.
  static const double weekNumberGap = 12;

  /// Icon size of a day type button in the day type tile.
  static const double dayTypeIcon = 18;
}
