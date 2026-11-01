import 'package:material_ui/material_ui.dart';

/// Colors of the gold foil, the same in light and dark.
abstract final class HoloFoilColors {
  /// Glitter dots on a dark card.
  static const glitter = Color(0xFFFFE9A8);

  /// Glitter dots on a light card.
  static const glitterOnLight = Color(0xFFC08A1E);

  /// Bands of the gold sheen: warm gold, a white core, deeper gold.
  static const sheen = [
    Color(0xFFFFE696),
    Color(0xFFFFFFFF),
    Color(0xFFFFD26E),
  ];

  /// Where the edges and bands of the sheen sit: clear, three bands, clear.
  static const sheenStops = [0.28, 0.45, 0.5, 0.56, 0.66];

  /// Bands of the gold sheen on a light card, which darkens toward gold.
  static const sheenOnLight = [
    Color(0xFFE8B850),
    Color(0xFFF6D98A),
    Color(0xFFD9A43A),
  ];
}
