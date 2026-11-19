/// Sizes of the diary's week card (#911): seven fields, one for each day of
/// the goal run.
abstract final class AppWeekCard {
  /// Corner radius of the card.
  static const double radius = 18;

  /// Horizontal padding of the card.
  static const double horizontalPadding = 17;

  /// Top padding of the card.
  static const double topPadding = 15;

  /// Bottom padding of the card.
  static const double bottomPadding = 10;

  /// Gap between two fields.
  static const double fieldGap = 6;

  /// Height of a field.
  static const double fieldHeight = 14;

  /// Corner radius of a field.
  static const double fieldRadius = 4;

  /// Gap between a field and the text under it.
  static const double textGap = 5;

  /// Width of the frame of the shown day and of a dashed outline.
  static const double outlineWidth = 1.5;

  /// Width of the frame of the shown day.
  static const double frameWidth = 2;

  /// Least width of the over part, the debt piece, and the extra piece, so
  /// that a small one stays visible.
  static const double minPieceWidth = 4;

  /// Width of a dash in a dashed outline.
  static const double dashLength = 3;

  /// Gap between two dashes in a dashed outline.
  static const double dashGap = 2.5;

  /// Distance between two stripes of a pause day's hatching.
  static const double hatchSpacing = 4;

  /// Width of a stripe of a pause day's hatching.
  static const double hatchStroke = 1.2;

  /// Gap between the text of an option of the week menu and its mark.
  static const double optionGap = 14;

  /// Least height of an option of the week menu.
  static const double optionHeight = 64;

  /// Edge length of the mark of an option.
  static const double optionMark = 22;

  /// Edge length of the dot in a selected mark.
  static const double optionDot = 10;

  /// Width of the ring of an option's mark.
  static const double optionRing = 2;
}
