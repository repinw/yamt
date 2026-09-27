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

  /// Opacity of a disabled button.
  static const double disabledOpacity = 0.7;

  /// Duration of a state change, such as a progress segment filling.
  static const Duration stateChange = Duration(milliseconds: 240);
}
