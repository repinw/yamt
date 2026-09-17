import 'package:flutter/widgets.dart';

/// How much of the pinned macro strip is shown.
enum DiaryMacroStripStage {
  /// The daily card's kcal bar has not reached the top bar yet.
  hidden,

  /// The kcal bar reached the top bar; the macro bars are still visible
  /// below the strip.
  kcal,

  /// The macro bars slid under the strip's kcal row.
  full,
}

/// Keys of the daily card parts the strip replaces once they scroll away.
class DiaryMacroStripAnchors {
  /// Creates fresh anchor keys.
  new();

  /// The whole daily card.
  final GlobalKey card = GlobalKey();

  /// The card's kcal progress bar.
  final GlobalKey kcalBar = GlobalKey();

  /// The card's protein, carbs, and fat bars.
  final GlobalKey macroBars = GlobalKey();

  /// The strip's kcal row, including its spacing to the macro row.
  final GlobalKey stripKcalRow = GlobalKey();
}
