import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_balance_summary_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _balanceBarCornerRadius = 4.0;
const _balanceBarCenterLineRadius = 2.0;
const _balanceBarFillInset = 4.0;
const _balanceBarMarkerRadius = 4.0;
const _balanceBarMarkerWidth = 4.0;
const _balanceBarMarkerHeight = 34.0;
const _balanceBarGreenStop = 0.03;
const _balanceBarRedStop = 0.4;
const _balanceColorCurveExponent = 2.0;
const _balanceDangerColor = Color(0xFFB71C1C);
const _balanceDangerColorDark = Color(0xFF991B1B);
const _balanceSafeColor = Color(0xFF006941);
const _balanceSafeColorDark = Color(0xFF0B7A4B);

Color _balanceSafeTone(Brightness brightness) {
  return brightness == Brightness.dark
      ? _balanceSafeColorDark
      : _balanceSafeColor;
}

Color _balanceDangerTone(Brightness brightness) {
  return brightness == Brightness.dark
      ? _balanceDangerColorDark
      : _balanceDangerColor;
}

/// Resolves the balance accent color for a normalized score from 0 to 1.
@visibleForTesting
Color resolveCaloriesBalanceColorForScore(
  double score, {
  required Brightness brightness,
}) {
  final adjustedScore = math.pow(
    score.clamp(0.0, 1.0),
    _balanceColorCurveExponent,
  );
  final safeColor = _balanceSafeTone(brightness);
  final dangerColor = _balanceDangerTone(brightness);

  return Color.lerp(dangerColor, safeColor, adjustedScore.toDouble()) ??
      safeColor;
}

({Color center, Color edge}) _balanceBarGradientColors({
  required Brightness brightness,
}) {
  return (
    center: _balanceSafeTone(brightness),
    edge: _balanceDangerTone(brightness),
  );
}

/// Resolves the visible fill and marker position for the balance bar.
@visibleForTesting
({double barLeft, double barWidth, double markerCenterX, double gradientWidth})
resolveCaloriesBalanceBarLayoutMetrics({
  required double totalWidth,
  required double progress,
  required bool isUnderPace,
  required bool isOverPace,
}) {
  final halfWidth = totalWidth / 2;
  final paddedHalfWidth = math.max(0.0, halfWidth - _balanceBarFillInset);
  final visibleProgress = (isUnderPace || isOverPace)
      ? progress.clamp(0.0, 1.0)
      : 0.0;
  final markerOffset = isUnderPace
      ? -visibleProgress
      : isOverPace
      ? visibleProgress
      : 0.0;
  final markerCenterX = halfWidth + (paddedHalfWidth * markerOffset);

  if (paddedHalfWidth <= 0 || visibleProgress <= 0) {
    return (
      barLeft: halfWidth,
      barWidth: 0.0,
      markerCenterX: markerCenterX,
      gradientWidth: paddedHalfWidth,
    );
  }

  final markerInsetProgress = (_balanceBarMarkerWidth / 2) / paddedHalfWidth;
  final barVisibleProgress = math.max(
    0.0,
    visibleProgress - markerInsetProgress,
  );
  final barWidth = paddedHalfWidth * barVisibleProgress;
  final barLeft = isUnderPace ? halfWidth - barWidth : halfWidth;

  return (
    barLeft: barLeft,
    barWidth: barWidth,
    markerCenterX: markerCenterX,
    gradientWidth: paddedHalfWidth,
  );
}

/// Defines calories balance summary view.
class CaloriesBalanceSummaryView extends StatelessWidget {
  /// The calories balance summary view.
  const CaloriesBalanceSummaryView({
    super.key,
    required this.data,
    required this.numberFormat,
    required this.kcalUnit,
  });

  /// The data.
  final CalorieBalanceSummaryData data;

  /// The number format.
  final NumberFormat numberFormat;

  /// The kcal unit.
  final String kcalUnit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final statusColor = resolveCaloriesBalanceColorForScore(
      resolveCalorieBalanceScore(data),
      brightness: colors.brightness,
    );
    final statusMessage = _statusMessage(l10n);
    final statusDetail = _statusDetailMessage(context, l10n);
    final semanticStatus = switch (statusDetail) {
      final String detail => '$statusMessage. $detail',
      null => statusMessage,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BalanceBar(data: data, semanticLabel: semanticStatus),
        const SizedBox(height: AppSpacing.md),
        _BalanceScaleLabels(
          leftLabel: l10n.caloriesBalanceScaleBufferLabel,
          middleLabel: l10n.caloriesBalanceScaleOnTrackLabel,
          rightLabel: l10n.caloriesBalanceScaleOverLabel,
          leftValue:
              '-${numberFormat.format(data.rangeKcal.round())} $kcalUnit',
          rightValue:
              '+${numberFormat.format(data.rangeKcal.round())} $kcalUnit',
        ),
        const SizedBox(height: AppSpacing.lg),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppInventoryEditorialSurfaces.ghostBorder(colors),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (statusDetail case final String detail) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _statusMessage(AppLocalizations l10n) {
    final delta = data.deltaKcal.round().abs();
    if (data.isCurrentDay) {
      if (data.recommendsFastingToday) {
        return l10n.caloriesBalanceStatusRecommendFast;
      }
      if (data.recommendsFastingRestOfDay) {
        return l10n.caloriesBalanceStatusRecommendFastRestOfDay;
      }
      if (data.isWithinDeadZone) {
        return l10n.caloriesBalanceStatusBalancedNow;
      }
      if (data.isUnderPace) {
        return l10n.caloriesBalanceStatusEatNow(delta);
      }
      return l10n.caloriesBalanceStatusWaitNow;
    }

    if (data.isWithinDeadZone) {
      return l10n.caloriesBalanceStatusFinishedOnTrack;
    }
    if (data.isUnderPace) {
      return _finishedUnderPaceMessage(l10n, delta);
    }
    return _finishedOverPaceMessage(l10n, delta);
  }

  String _finishedUnderPaceMessage(AppLocalizations l10n, int delta) {
    return switch (data.goalMode) {
      CalorieGoalMode.lose => l10n.caloriesBalanceStatusFinishedLoseUnder(
        delta,
      ),
      CalorieGoalMode.maintain => l10n.caloriesBalanceStatusFinishedBuffer(
        delta,
      ),
      CalorieGoalMode.gain => l10n.caloriesBalanceStatusFinishedGainUnder(
        delta,
      ),
    };
  }

  String _finishedOverPaceMessage(AppLocalizations l10n, int delta) {
    return switch (data.goalMode) {
      CalorieGoalMode.lose => l10n.caloriesBalanceStatusFinishedLoseOver(delta),
      CalorieGoalMode.maintain => l10n.caloriesBalanceStatusFinishedOver(delta),
      CalorieGoalMode.gain => l10n.caloriesBalanceStatusFinishedGainOver(delta),
    };
  }

  String? _statusDetailMessage(BuildContext context, AppLocalizations l10n) {
    if (data.recommendsFastingToday) {
      return null;
    }

    if (data.recommendsFastingRestOfDay) {
      return l10n.caloriesBalanceStatusWaitRestOfDay;
    }

    if (!data.isCurrentDay || !data.isOverPace) {
      return null;
    }

    final recoveryTime = resolveCalorieBalanceRecoveryTime(data);
    if (recoveryTime == null) {
      return l10n.caloriesBalanceStatusWaitRestOfDay;
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    final formattedTime = DateFormat.Hm(locale).format(recoveryTime.toLocal());
    return l10n.caloriesBalanceStatusWaitUntil(formattedTime);
  }
}

class _BalanceBar extends StatelessWidget {
  const _BalanceBar({required this.data, required this.semanticLabel});

  final CalorieBalanceSummaryData data;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final gradientColors = _balanceBarGradientColors(
      brightness: colors.brightness,
    );
    final centerColor = gradientColors.center;
    final edgeColor = gradientColors.edge;
    final markerColor = resolveCaloriesBalanceColorForScore(
      resolveCalorieBalanceScore(data),
      brightness: colors.brightness,
    );

    return Semantics(
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layoutMetrics = resolveCaloriesBalanceBarLayoutMetrics(
            totalWidth: constraints.maxWidth,
            progress: data.barProgress,
            isUnderPace: data.isUnderPace,
            isOverPace: data.isOverPace,
          );

          return SizedBox(
            key: CaloriesPageKeys.summaryBalanceBar,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(
                      _balanceBarCornerRadius,
                    ),
                    border: Border.all(
                      color: AppInventoryEditorialSurfaces.ghostBorder(colors),
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
                if (layoutMetrics.barWidth > 0)
                  Positioned(
                    top: _balanceBarFillInset,
                    bottom: _balanceBarFillInset,
                    left: layoutMetrics.barLeft,
                    width: layoutMetrics.barWidth,
                    child: ClipRect(
                      child: OverflowBox(
                        minWidth: layoutMetrics.gradientWidth,
                        maxWidth: layoutMetrics.gradientWidth,
                        alignment: data.isUnderPace
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            _balanceBarCornerRadius,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: data.isUnderPace
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                end: data.isUnderPace
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                colors: [centerColor, centerColor, edgeColor],
                                stops: const [
                                  0.0,
                                  _balanceBarGreenStop,
                                  _balanceBarRedStop,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(
                      _balanceBarCenterLineRadius,
                    ),
                  ),
                  child: const SizedBox(width: 2, height: 32),
                ),
                Positioned(
                  left:
                      layoutMetrics.markerCenterX -
                      (_balanceBarMarkerWidth / 2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        _balanceBarMarkerRadius,
                      ),
                      border: Border.all(color: markerColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: colors.onSurface.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const SizedBox(
                      width: _balanceBarMarkerWidth,
                      height: _balanceBarMarkerHeight,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BalanceScaleLabels extends StatelessWidget {
  const _BalanceScaleLabels({
    required this.leftLabel,
    required this.middleLabel,
    required this.rightLabel,
    required this.leftValue,
    required this.rightValue,
  });

  final String leftLabel;
  final String middleLabel;
  final String rightLabel;
  final String leftValue;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.05,
    );
    final valueStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leftLabel.toUpperCase(), style: labelStyle),
              const SizedBox(height: AppSpacing.xxs),
              Text(leftValue, style: valueStyle),
            ],
          ),
        ),
        Expanded(
          child: Text(
            middleLabel.toUpperCase(),
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rightLabel.toUpperCase(), style: labelStyle),
              const SizedBox(height: AppSpacing.xxs),
              Text(rightValue, style: valueStyle),
            ],
          ),
        ),
      ],
    );
  }
}
