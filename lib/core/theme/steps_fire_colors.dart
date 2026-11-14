import 'package:material_ui/material_ui.dart';

/// Colors of the fire on the steps card, the same in light and dark.
abstract final class StepsFireColors {
  /// Dim ember, the rim at its darkest.
  static const ember = Color(0xFFE2551A);

  /// Flame, the body of the fire.
  static const flame = Color(0xFFFF7A2E);

  /// The rim at its brightest: warm, not as yellow as the gold foil.
  static const rimBright = Color(0xFFFFA23C);

  /// Bright core of the fire.
  static const core = Color(0xFFFFD24A);

  /// The glow around the fire.
  static const glow = Color(0xFFFF5A14);

  /// The bands that run through the burning goal line; they start and end
  /// alike, so the run repeats without a seam.
  static const List<Color> run = [ember, flame, core, flame, ember];
}
