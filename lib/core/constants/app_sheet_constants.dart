/// Layout and motion tokens for bottom sheets that open with a hero image.
abstract final class AppSheetTokens {
  /// Duration of the sheet entrance and the hero flight into it.
  static const Duration heroSheetTransition = Duration(milliseconds: 380);

  /// Duration of the sheet exit and the hero flight back.
  static const Duration heroSheetReverseTransition = Duration(
    milliseconds: 300,
  );

  /// Duration of the sheet sliding back after a drag that did not close it.
  static const Duration dragSettle = Duration(milliseconds: 220);

  /// Fraction of the sheet height it travels while it slides in.
  static const double heroSheetEntranceOffset = 0.08;

  /// Drag distance, as a fraction of the sheet height, that closes the sheet.
  static const double dismissDragFraction = 0.25;

  /// Downward fling velocity in logical pixels per second that closes the
  /// sheet.
  static const double dismissFlingVelocity = 700;
}
