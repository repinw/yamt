import 'package:material_ui/material_ui.dart';

/// What the macros tile shows of one macro, ready to draw.
typedef DiaryMacroTileView = ({
  /// One-letter name.
  String letter,

  /// Full name.
  String label,

  /// Grams left, over, or eaten.
  String value,

  /// Eaten of target, or null when the value says it already.
  String? total,

  /// Color of the name.
  Color labelColor,

  /// Color of the value.
  Color valueColor,

  /// Eaten grams.
  double eaten,

  /// Counted planned grams.
  double planned,

  /// Target grams, or null on a pause day.
  double? target,

  /// Grams of a full line or ring without a target.
  double scale,

  /// Color of the eaten part.
  Color eatenColor,
});
