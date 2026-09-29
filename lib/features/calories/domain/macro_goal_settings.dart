import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:yamt/features/calories/domain/macro_budget_calculator.dart';

/// Recommended macro multipliers based on sex and activity.
///
/// The multipliers apply to the macro reference weight, not to the full body
/// weight (see `macroReferenceWeightKg`).
abstract final class MacroCalculationDefaults {
  /// Default protein multiplier in g/kg.
  ///
  /// 1.6 g/kg covers muscle gain and retention for people who train; more
  /// brings no measurable benefit for most. Without training 1.2 g/kg is
  /// enough. While losing weight the body breaks down more protein, so the
  /// values go up to 2.0 and 1.6 g/kg.
  static double defaultProteinMultiplier({
    required bool isSportActive,
    required bool isLosingWeight,
  }) {
    if (isLosingWeight) {
      return isSportActive ? 2.0 : 1.6;
    }
    return isSportActive ? 1.6 : 1.2;
  }

  /// Smallest share of the daily kcal that protein gets while losing weight.
  ///
  /// Protein fills up more than carbs or fat, so a diet keeps at least this
  /// share even when the g/kg rule gives less.
  static const double deficitProteinMinKcalShare = 0.30;

  /// Largest share of the daily kcal that protein gets while losing weight,
  /// so a small budget keeps room for carbs.
  static const double deficitProteinMaxKcalShare = 0.35;

  /// Default fat multiplier in g/kg.
  ///
  /// Fat needs do not depend on training; women get a little more for their
  /// hormone balance.
  static double defaultFatMultiplier({required bool isMale}) {
    return isMale ? 0.8 : 0.9;
  }
}

/// User-configured settings for macro targets calculation.
@immutable
class MacroGoalSettings {
  /// Creates macro goal settings.
  const new({
    this.isSportActive,
    this.customProteinMultiplier,
    this.customFatMultiplier,
  });

  /// Parses from JSON map.
  factory fromJson(Map<String, dynamic> json) {
    return MacroGoalSettings(
      isSportActive: json['is_sport_active'] as bool?,
      customProteinMultiplier: (json['custom_protein_multiplier'] as num?)
          ?.toDouble(),
      customFatMultiplier: (json['custom_fat_multiplier'] as num?)?.toDouble(),
    );
  }

  /// Whether the user engages in regular sport/workouts.
  ///
  /// `null` until the user sets it in the macro settings. Until then the
  /// training days of the calorie profile decide, so nobody has to know what
  /// a g/kg multiplier is.
  final bool? isSportActive;

  /// Whether the sport defaults apply, given whether the profile has
  /// [hasTrainingDays].
  bool resolveSportActive({required bool hasTrainingDays}) {
    return isSportActive ?? hasTrainingDays;
  }

  /// Custom protein multiplier in g/kg if overridden by user.
  final double? customProteinMultiplier;

  /// Custom fat multiplier in g/kg if overridden by user.
  final double? customFatMultiplier;

  /// Resolves the effective protein multiplier in g/kg.
  double effectiveProteinMultiplier({
    required bool hasTrainingDays,
    required bool isLosingWeight,
  }) {
    return customProteinMultiplier ??
        MacroCalculationDefaults.defaultProteinMultiplier(
          isSportActive: resolveSportActive(hasTrainingDays: hasTrainingDays),
          isLosingWeight: isLosingWeight,
        );
  }

  /// Resolves the protein target in grams for [referenceWeightKg].
  ///
  /// While losing weight the default target stays between
  /// [MacroCalculationDefaults.deficitProteinMinKcalShare] and
  /// [MacroCalculationDefaults.deficitProteinMaxKcalShare] of
  /// [baseGoalKcal], the daily average of the week. Using the average keeps
  /// protein the same on training and rest days. A custom multiplier is the
  /// user's own choice and is used as it is.
  double resolveProteinGrams({
    required double referenceWeightKg,
    required double baseGoalKcal,
    required bool hasTrainingDays,
    required bool isLosingWeight,
  }) {
    final byWeightGrams =
        referenceWeightKg *
        effectiveProteinMultiplier(
          hasTrainingDays: hasTrainingDays,
          isLosingWeight: isLosingWeight,
        );
    if (customProteinMultiplier != null ||
        !isLosingWeight ||
        baseGoalKcal <= 0) {
      return byWeightGrams;
    }
    const kcalPerGram = MacroBudgetCalculator.standardProteinKcalPerGram;
    return byWeightGrams.clamp(
      baseGoalKcal *
          MacroCalculationDefaults.deficitProteinMinKcalShare /
          kcalPerGram,
      baseGoalKcal *
          MacroCalculationDefaults.deficitProteinMaxKcalShare /
          kcalPerGram,
    );
  }

  /// Resolves the effective fat multiplier in g/kg.
  double effectiveFatMultiplier({required bool isMale}) {
    return customFatMultiplier ??
        MacroCalculationDefaults.defaultFatMultiplier(isMale: isMale);
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
    'is_sport_active': ?isSportActive,
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
  int get hashCode =>
      Object.hash(isSportActive, customProteinMultiplier, customFatMultiplier);
}
