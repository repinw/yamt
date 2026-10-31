import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';

/// The colors the user can pick in the design "Individuell".
enum AppCustomColor {
  /// Page background.
  paper,

  /// Cards, sheets and dialogs.
  card,

  /// Text and icons.
  ink,

  /// Secondary text.
  muted,

  /// Lines, dividers and empty bar tracks.
  lines,

  /// Main buttons and marks.
  accent,

  /// Planned food.
  plan,

  /// Protein.
  protein,

  /// Carbohydrates.
  carbs,

  /// Fat.
  fat,

  /// Errors, deleting, and going over a target.
  signal,
}

/// The user's own colors of the design "Individuell". They start as a copy
/// of the light or dark design ([base]) and every one can be changed.
@immutable
class AppCustomColors {
  /// Creates custom colors. [colors] holds every [AppCustomColor].
  const new({required this.base, required this.colors});

  /// Copies the colors of [theme], a light or dark app theme.
  factory copyOf(ThemeData theme) {
    final label = theme.extension<FoodLabelColors>()!;
    final metrics = theme.extension<MetricAccentColors>()!;
    return AppCustomColors(
      base: theme.brightness,
      colors: {
        AppCustomColor.paper: label.paper,
        AppCustomColor.card: label.card,
        AppCustomColor.ink: label.ink,
        AppCustomColor.muted: label.muted,
        AppCustomColor.lines: label.rule,
        AppCustomColor.accent: label.accent,
        AppCustomColor.plan: label.plan,
        AppCustomColor.protein: metrics.protein,
        AppCustomColor.carbs: metrics.carbs,
        AppCustomColor.fat: metrics.fat,
        AppCustomColor.signal: theme.colorScheme.error,
      },
    );
  }

  /// Reads colors saved with [toJson].
  factory fromJson(Map<String, Object?> json) {
    final colors = json['colors']! as Map<String, Object?>;
    return AppCustomColors(
      base: Brightness.values.byName(json['base']! as String),
      colors: {
        for (final key in AppCustomColor.values)
          key: Color(colors[key.name]! as int),
      },
    );
  }

  /// Whether the colors started as the light or the dark design. Text
  /// contrast helpers and the launch screen follow it.
  final Brightness base;

  /// Every picked color.
  final Map<AppCustomColor, Color> colors;

  /// The color picked for [key].
  Color operator [](AppCustomColor key) => colors[key]!;

  /// These colors with [color] for [key].
  AppCustomColors withColor(AppCustomColor key, Color color) {
    return AppCustomColors(base: base, colors: {...colors, key: color});
  }

  /// The colors as JSON for the device preferences.
  Map<String, Object?> toJson() => {
    'base': base.name,
    'colors': {
      for (final key in AppCustomColor.values) key.name: this[key].toARGB32(),
    },
  };

  @override
  bool operator ==(Object other) =>
      other is AppCustomColors &&
      other.base == base &&
      mapEquals(other.colors, colors);

  @override
  int get hashCode => Object.hash(
    base,
    Object.hashAll(AppCustomColor.values.map((key) => colors[key])),
  );
}
