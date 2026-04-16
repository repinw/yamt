import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_classic_adjustments.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card_classic_gauge.dart';

/// Displays the classic remaining-calories hero.
class ClassicSummaryHero extends StatelessWidget {
  /// Creates the classic remaining-calories hero.
  const ClassicSummaryHero({
    required this.remainingKcal,
    required this.color,
    required this.consumedKcal,
    required this.baseGoalKcal,
    required this.activityDeltaKcal,
    required this.availableActivityDeltaKcal,
    required this.carryoverKcal,
    required this.availableCarryoverKcal,
    required this.label,
    required this.numberFormat,
    super.key,
  });

  /// Remaining calories shown in the center of the hero.
  final double remainingKcal;

  /// Primary accent color for the goal segment and glow.
  final Color color;

  /// Calories consumed so far on the selected day.
  final double consumedKcal;

  /// Base goal calories before optional daily adjustments.
  final double baseGoalKcal;

  /// Activity calories currently included in the classic target.
  final double activityDeltaKcal;

  /// Activity calories available to include in the classic target.
  final double availableActivityDeltaKcal;

  /// Carryover calories currently included in the classic target.
  final double carryoverKcal;

  /// Carryover calories available to include in the classic target.
  final double availableCarryoverKcal;

  /// Uppercase label shown under the remaining value.
  final String label;

  /// Number formatter used for localized calorie values.
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final displayedValue = numberFormat.format(remainingKcal.round());
    final hasAdjustments =
        activityDeltaKcal.round() != 0 || carryoverKcal.round() != 0;
    final borderRadius = BorderRadius.circular(32);

    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 1 / 0.65,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF142033),
                Color(0xFF0F172A),
              ],
            ),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gaugeThickness = (constraints.maxWidth * 0.10).clamp(
                  28.0,
                  42.0,
                );
                final numberFontSize = (constraints.maxWidth * 0.145).clamp(
                  42.0,
                  58.0,
                );

                return Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: constraints.maxHeight * 0.24,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.white.withValues(alpha: 0.04),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      height: constraints.maxHeight * 0.5,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                color.withValues(alpha: 0.14),
                                color.withValues(alpha: 0.05),
                                color.withValues(alpha: 0),
                              ],
                              stops: const <double>[0, 0.45, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: ClassicSummaryGauge(
                        strokeWidth: gaugeThickness,
                        color: color,
                        consumedKcal: consumedKcal,
                        baseGoalKcal: baseGoalKcal,
                        activityDeltaKcal: activityDeltaKcal,
                        availableActivityDeltaKcal: availableActivityDeltaKcal,
                        carryoverKcal: carryoverKcal,
                        availableCarryoverKcal: availableCarryoverKcal,
                        trackColor: const Color(0xFF374151),
                      ),
                    ),
                    Positioned(
                      top: constraints.maxHeight * 0.42,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayedValue,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: numberFontSize,
                              fontWeight: FontWeight.w800,
                              height: 1,
                              letterSpacing: -1.8,
                              shadows: <Shadow>[
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            label.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.6,
                                ),
                          ),
                          if (hasAdjustments) ...[
                            const SizedBox(height: AppSpacing.xl),
                            ClassicSummaryAdjustmentsPill(
                              activityDeltaKcal: activityDeltaKcal,
                              carryoverKcal: carryoverKcal,
                              numberFormat: numberFormat,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
