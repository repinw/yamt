import 'package:material_ui/material_ui.dart';

/// What the kcal tile shows, ready to draw.
typedef DiaryKcalTileView = ({
  /// Big number (or the pause day's word).
  String value,

  /// Number in the middle of the ring.
  String ringValue,

  /// What the big number means.
  String caption,

  /// What the ring's number means.
  String ringCaption,

  /// Eaten of target, or null when the caption says it already.
  String? total,

  /// Color of the number.
  Color color,

  /// Eaten kcal of the line and the ring.
  double eaten,

  /// Counted planned kcal of the line and the ring.
  double planned,

  /// Target kcal, or null on a pause day.
  double? target,

  /// Amount of a full line or ring without a target.
  double scale,

  /// Color of the eaten part of the line and the ring.
  Color eatenColor,

  /// Color of the part over the target: the error color when going over
  /// is a miss, else ink.
  Color overColor,

  /// Where the day should be by now, or null without a pace marker.
  double? pace,
});
