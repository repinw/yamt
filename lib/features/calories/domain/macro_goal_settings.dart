import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Scientific recommendations for macro multipliers based on sex and activity.
abstract final class MacroCalculationDefaults {
  /// Default protein multiplier in g/kg.
  static double defaultProteinMultiplier({
    required bool isMale,
    required bool isSportActive,
  }) {
    if (isSportActive) {
      return isMale ? 2.0 : 1.8;
    } else {
      return 1.2;
    }
  }

  /// Default fat multiplier in g/kg.
  static double defaultFatMultiplier({
    required bool isMale,
    required bool isSportActive,
  }) {
    if (isSportActive) {
      return isMale ? 1.0 : 1.2;
    } else {
      return isMale ? 0.9 : 1.0;
    }
  }
}

/// User-configured settings for macro targets calculation.
@immutable
class MacroGoalSettings {
  /// Creates macro goal settings.
  const MacroGoalSettings({
    this.isSportActive = true,
    this.customProteinMultiplier,
    this.customFatMultiplier,
  });

  /// Parses from JSON map.
  factory MacroGoalSettings.fromJson(Map<String, dynamic> json) {
    return MacroGoalSettings(
      isSportActive: json['is_sport_active'] as bool? ?? true,
      customProteinMultiplier: (json['custom_protein_multiplier'] as num?)
          ?.toDouble(),
      customFatMultiplier: (json['custom_fat_multiplier'] as num?)?.toDouble(),
    );
  }

  /// Whether the user engages in regular sport/workouts.
  final bool isSportActive;

  /// Custom protein multiplier in g/kg if overridden by user.
  final double? customProteinMultiplier;

  /// Custom fat multiplier in g/kg if overridden by user.
  final double? customFatMultiplier;

  /// Resolves the effective protein multiplier in g/kg.
  double effectiveProteinMultiplier({required bool isMale}) {
    return customProteinMultiplier ??
        MacroCalculationDefaults.defaultProteinMultiplier(
          isMale: isMale,
          isSportActive: isSportActive,
        );
  }

  /// Resolves the effective fat multiplier in g/kg.
  double effectiveFatMultiplier({required bool isMale}) {
    return customFatMultiplier ??
        MacroCalculationDefaults.defaultFatMultiplier(
          isMale: isMale,
          isSportActive: isSportActive,
        );
  }

  /// Creates a copy with optionally replaced fields.
  MacroGoalSettings copyWith({
    bool? isSportActive,
    double? customProteinMultiplier,
    double? customFatMultiplier,
    bool clearCustomProtein = false,
    bool clearCustomFat = false,
  }) {
    return MacroGoalSettings(
      isSportActive: isSportActive ?? this.isSportActive,
      customProteinMultiplier: clearCustomProtein
          ? null
          : (customProteinMultiplier ?? this.customProteinMultiplier),
      customFatMultiplier: clearCustomFat
          ? null
          : (customFatMultiplier ?? this.customFatMultiplier),
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
    'is_sport_active': isSportActive,
    if (customProteinMultiplier != null)
      'custom_protein_multiplier': customProteinMultiplier,
    if (customFatMultiplier != null)
      'custom_fat_multiplier': customFatMultiplier,
  };

  /// Parses from JSON string, returning null if invalid.
  static MacroGoalSettings? fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      return MacroGoalSettings.fromJson(decoded);
    } on Object {
      return null;
    }
  }

  /// Converts to JSON string.
  String toJsonString() => json.encode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacroGoalSettings &&
          runtimeType == other.runtimeType &&
          isSportActive == other.isSportActive &&
          customProteinMultiplier == other.customProteinMultiplier &&
          customFatMultiplier == other.customFatMultiplier;

  @override
  int get hashCode => Object.hash(
    isSportActive,
    customProteinMultiplier,
    customFatMultiplier,
  );
}
