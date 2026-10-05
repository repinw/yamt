/// Sizes of the Graphit design language: paper, ink and one lime.
///
/// Square shapes show content, round shapes are tapped. Buttons carry a
/// word, sit on a soft tile surface and have no frame or hard shadow.
abstract final class AppGraphit {
  /// Height of the main and the secondary button.
  static const double buttonHeight = 48;

  /// Height of a chip, such as a row action or a filter.
  static const double chipHeight = 34;

  /// Edge length of a tool button: a symbol with a word under it.
  static const double toolButton = 56;

  /// Icon inside a tool button or a chip.
  static const double toolIcon = 20;

  /// Icon inside a chip.
  static const double chipIcon = 16;

  /// Width of one segment of the step progress.
  static const double progressSegmentWidth = 18;

  /// Height of one segment of the step progress.
  static const double progressSegmentHeight = 4;

  /// Gap between two progress segments.
  static const double progressSegmentGap = 3;

  /// Edge length of the framed picture tile in a list row.
  static const double rowTile = 44;

  /// Edge length of the framed picture in a Vorrat row.
  static const double stockRowPicture = 42;

  /// Edge length of the framed picture in a Vorrat tile.
  static const double stockTilePicture = 64;

  /// Tilt of a framed picture in radians. Rows alternate the sign.
  static const double pictureTilt = 0.05;

  /// Height of one stock bar segment.
  static const double stockBarHeight = 5;

  /// Gap between two stock bar segments.
  static const double stockBarGap = 3;

  /// Most stock bar segments; more packs draw one continuous bar.
  static const int stockBarMaxSegments = 12;

  /// Share of the stock under which a row turns to the low color.
  static const double lowStockShare = 0.25;

  /// Diameter of the round action button in the middle of the home bar.
  static const double navActionButton = 56;

  /// How far the action button reaches above the home bar.
  static const double navActionOverhang = 22;

  /// Edge length of one square in a line of stock squares, one per food.
  static const double stockSquare = 8;

  /// Most squares in a line of stock squares; longer lists show only text.
  static const int stockSquareMaxCount = 10;

  /// Edge length of a letter tile that stands for one food of a meal.
  static const double letterTile = 34;

  /// How far overlapping letter tiles reach under the previous tile.
  static const double letterTileOverlap = 10;

  /// Width of a tile in a horizontal strip, such as a Vorlage.
  static const double stripTileWidth = 156;

  /// Width of the tile that starts a new entry at the head of a strip.
  static const double stripStartTileWidth = 112;

  /// Height of the picture on a recipe card.
  static const double recipeCardPicture = 116;

  /// Smallest height of a Vorlage tile.
  static const double stripTileMinHeight = 150;

  /// Smallest height of a Vorrat row.
  static const double stockRowMinHeight = 70;

  /// Edge length of the square badge that shows a step number or an icon.
  static const double badge = 32;

  /// Width of a number field that shows a large value, such as portions.
  static const double numberField = 88;

  /// Letter spacing of a small uppercase caption.
  static const double kickerTracking = 1.8;

  /// Line height of a large display number or name.
  static const double displayLineHeight = 1;

  /// Thickness of the underline that marks an amount in an instruction.
  static const double highlightUnderline = 2;

  /// Icon in the round button of the voice zone.
  static const double voiceZoneIcon = 40;

  /// Smallest height of the voice zone, so it stays easy to hit.
  static const double voiceZoneMinHeight = 220;

  /// Opacity of a row that is not real yet: one that speech recognition is
  /// still writing, or a plan.
  static const double pendingRowOpacity = 0.55;

  /// Line width of the dashed frame around a plan.
  static const double dashedFrameWidth = 1.5;

  /// Opacity of a disabled button.
  static const double disabledOpacity = 0.7;

  /// Duration of a state change, such as a progress segment filling.
  static const Duration stateChange = Duration(milliseconds: 240);
}
