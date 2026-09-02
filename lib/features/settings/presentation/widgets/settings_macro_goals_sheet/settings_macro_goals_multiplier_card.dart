import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Card containing a slider to configure an individual macro multiplier (g/kg).
class SettingsMacroGoalsMultiplierCard extends StatelessWidget {
  /// Creates a multiplier slider card.
  const SettingsMacroGoalsMultiplierCard({
    required this.sliderKey,
    required this.label,
    required this.accentColor,
    required this.multiplier,
    required this.grams,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.formatGramPerKg,
    super.key,
  });

  /// Finder key for tests.
  final Key sliderKey;

  /// Display name of the macronutrient.
  final String label;

  /// Macro accent color.
  final Color accentColor;

  /// Current multiplier in g/kg.
  final double multiplier;

  /// Resulting grams of macro for the user's weight.
  final int grams;

  /// Minimum slider value.
  final double min;

  /// Maximum slider value.
  final double max;

  /// Discrete steps on the slider track.
  final int divisions;

  /// Callback when slider changes value.
  final ValueChanged<double> onChanged;

  /// Formatter for the multiplier subtitle (e.g. "2.0 g/kg").
  final String Function(double) formatGramPerKg;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Row(
                children: [
                  Text(
                    '${grams}g ',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '(${formatGramPerKg(multiplier)})',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.15),
            ),
            child: Slider(
              key: sliderKey,
              value: multiplier.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
