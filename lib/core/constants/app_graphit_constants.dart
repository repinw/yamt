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

  /// Icon in the small round badge at the lower right of a framed picture,
  /// such as the action of a Vorrat history row.
  static const double pictureBadgeIcon = 12;

  /// Height of one stock bar segment.
  static const double stockBarHeight = 5;

  /// Gap between two stock bar segments.
  static const double stockBarGap = 3;

  /// Most stock bar segments; more packs draw one continuous bar.
  static const int stockBarMaxSegments = 12;

  /// Share of the stock under which a row turns to the low color.
  static const double lowStockShare = 0.25;

  /// Least height of the floating tab capsule and of the action button beside
  /// it in the home bar; large text makes the bar taller.
  static const double navBarHeight = 62;

  /// Gap between the home bar and the bottom edge of the safe area.
  static const double navBarBottomMargin = 20;

  /// Soft fade of the page into the home bar, above the bar.
  static const double navBarFade = 40;

  /// Space between the capsule edge and its tabs.
  static const double navCapsulePadding = 6;

  /// Corner radius of the selected tab in the home bar capsule.
  static const double navTabRadius = 18;

  /// Width of the action button in the home bar.
  static const double navActionWidth = 68;

  /// Least gap between a word of the home bar and the edge of its tab or of
  /// the action button.
  static const double navWordGap = 4;

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

  /// Blur of the light shadow under a recipe card.
  static const double recipeCardShadowBlur = 8;

  /// Downward offset of the light shadow under a recipe card.
  static const double recipeCardShadowOffset = 2;

  /// Size of the spinner where a recipe card's estimate will stand.
  static const double recipeCardSpinner = 12;

  /// Stroke of the spinner on a recipe card.
  static const double recipeCardSpinnerStroke = 1.5;

  /// Opacity of the light shadow under a recipe card.
  static const double recipeCardShadowAlpha = 0.18;

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

  /// Thickness of the underline under a text action, such as "Bearbeiten".
  static const double highlightUnderline = 2;

  /// Opacity of a row that is not real yet: one that speech recognition is
  /// still writing, or a plan.
  static const double pendingRowOpacity = 0.55;

  /// Line width of the dashed frame around a plan.
  static const double dashedFrameWidth = 1.5;

  /// Opacity of a disabled button.
  static const double disabledOpacity = 0.7;

  /// Height of the recipe photo at the top of the recipe page.
  static const double recipeHeroHeight = 280;

  /// Width to height of the picture at the top of a recipe idea.
  static const double recipeIdeaPictureAspectRatio = 16 / 9;

  /// Edge length of the photo button of the recipe editor.
  static const double editorPhoto = 72;

  /// Opacity of the dark scrim at the lower edge of a photo with text on it.
  static const double photoScrimOpacity = 0.92;

  /// Opacity of the background of a button on a photo.
  static const double photoButtonOpacity = 0.5;

  /// Duration of a state change, such as a progress segment filling.
  static const Duration stateChange = Duration(milliseconds: 240);

  /// Smallest height of the large button that a page offers first, such as
  /// "Packung scannen".
  static const double leadButtonMinHeight = 112;

  /// Icon in the large button that a page offers first.
  static const double leadButtonIcon = 48;

  /// Smallest height of a row that picks one food.
  static const double foodRowMinHeight = 64;

  /// Opacity of the accent behind a line that confirms what the app did,
  /// such as "1 kg eingetragen".
  static const double confirmTintOpacity = 0.16;

  /// Diameter of the check mark circle of such a line.
  static const double confirmCheck = 28;
}
