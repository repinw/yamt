/// Layout and motion tokens of the shopping list.
abstract final class AppShopping {
  /// Least height of an entry tile; the name may make it taller.
  static const double tileMinHeight = 88;

  /// Diameter of the disc with the first letter of an entry.
  static const double letterDisc = 30;

  /// Diameter of the letter disc in the entry sheet.
  static const double sheetLetterDisc = 56;

  /// Size of the letter in a letter disc, as a fraction of its diameter.
  static const double letterDiscLetterRatio = 0.46;

  /// Size of the tick in a letter disc, as a fraction of its diameter.
  static const double letterDiscTickRatio = 0.6;

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
