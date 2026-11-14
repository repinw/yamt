/// Layout and motion tokens of the shopping list.
abstract final class AppShopping {
  /// Least height of an entry tile; the name may make it taller.
  static const double tileMinHeight = 88;

  /// Edge length of the disc with the picture of an entry.
  static const double itemDisc = 36;

  /// Edge length of the picture disc in the entry sheet.
  static const double sheetItemDisc = 56;

  /// Size of the picture or tick in a disc, as a fraction of its edge.
  static const double itemDiscIconRatio = 0.6;

  /// Least height of a shelf choice in the shelf picker.
  static const double shelfChoiceMinHeight = 56;

  /// Text scale from which the shelf picker shows one choice per row.
  static const double shelfPickerLargeTextScale = 1.5;

  /// Size of the lock on a private tile among household tiles.
  static const double privateLockSize = 14;

  /// Letter spacing of a shelf heading, which is in capitals.
  static const double shelfHeadingLetterSpacing = 0.6;

  /// Stroke width of the dashed outline of an entry without a shelf.
  static const double unassignedOutlineWidth = 2;

  /// Length of one dash, and of one gap, of that outline.
  static const double unassignedDash = 6;

  /// Diameter of the add button on a suggestion card.
  static const double suggestionAddDisc = 30;

  /// Most of the screen height the add sheet takes.
  static const double addSheetHeightFraction = 0.85;

  /// Width of a suggestion card at text scale one.
  static const double suggestionCardWidth = 220;

  /// Least edge length of the quantity badge on a tile.
  static const double quantityBadge = 22;

  /// Height of the progress bar under the cart count.
  static const double progressBarHeight = 6;

  /// Tiles in a row at normal text size on a phone.
  static const int tileColumns = 3;

  /// Tiles in a row when the text is large or the screen is narrow.
  static const int tileColumnsLargeText = 2;

  /// Least tile width, at text scale one, that still fits a name.
  static const double tileMinWidth = 96;

  /// How long a ticked tile stays in place before it moves to the cart, so
  /// that a second tap does not hit the tile that moves up.
  static const Duration tickLinger = Duration(milliseconds: 700);
}
