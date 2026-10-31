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
}
