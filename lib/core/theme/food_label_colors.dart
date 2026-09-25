import 'package:material_ui/material_ui.dart';

/// Colors of the food label pages, such as the eat page.
///
/// The pages follow their own "Graphit" look instead of the app's color
/// scheme: paper, ink and one lime accent.
@immutable
class FoodLabelColors extends ThemeExtension<FoodLabelColors> {
  /// Creates food label colors.
  const new({
    required this.paper,
    required this.card,
    required this.ink,
    required this.muted,
    required this.rule,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.tile,
    required this.onTile,
  });

  /// The colors of the active theme, or the Graphit colors for its
  /// brightness.
  factory of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<FoodLabelColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  /// Light Graphit colors.
  static const light = FoodLabelColors(
    paper: Color(0xFFEBEBE8),
    card: Color(0xFFFAFAF8),
    ink: Color(0xFF141414),
    muted: Color(0xFF626260),
    rule: Color(0xFFC4C4BF),
    accent: Color(0xFFB6E21F),
    onAccent: Color(0xFF141414),
    accentText: Color(0xFF4F6A00),
    tile: Color(0xFFFFFFFF),
    onTile: Color(0xFF141414),
  );

  /// Dark Graphit colors.
  static const dark = FoodLabelColors(
    paper: Color(0xFF121313),
    card: Color(0xFF1B1C1C),
    ink: Color(0xFFECECE8),
    muted: Color(0xFF9A9A95),
    rule: Color(0xFF393A3A),
    accent: Color(0xFFC7F23A),
    onAccent: Color(0xFF121313),
    accentText: Color(0xFFD4F55F),
    tile: Color(0xFF2A2B2B),
    onTile: Color(0xFFC7F23A),
  );

  /// Page background.
  final Color paper;

  /// Background of the nutrition label.
  final Color card;

  /// Text, lines and borders.
  final Color ink;

  /// Secondary text.
  final Color muted;

  /// Thin lines between sub-rows.
  final Color rule;

  /// Main button background.
  final Color accent;

  /// Text on [accent].
  final Color onAccent;

  /// Links and hints.
  final Color accentText;

  /// Background of the image tile when there is no image.
  final Color tile;

  /// Icon on [tile].
  final Color onTile;

  @override
  FoodLabelColors copyWith({
    Color? paper,
    Color? card,
    Color? ink,
    Color? muted,
    Color? rule,
    Color? accent,
    Color? onAccent,
    Color? accentText,
    Color? tile,
    Color? onTile,
  }) {
    return FoodLabelColors(
      paper: paper ?? this.paper,
      card: card ?? this.card,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      rule: rule ?? this.rule,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentText: accentText ?? this.accentText,
      tile: tile ?? this.tile,
      onTile: onTile ?? this.onTile,
    );
  }

  @override
  FoodLabelColors lerp(FoodLabelColors? other, double t) {
    if (other == null) {
      return this;
    }
    return FoodLabelColors(
      paper: Color.lerp(paper, other.paper, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      tile: Color.lerp(tile, other.tile, t)!,
      onTile: Color.lerp(onTile, other.onTile, t)!,
    );
  }
}
