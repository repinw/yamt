import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/calories/domain/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_metric_stat_card.dart';

const _burnWeekBarTrackHeight = 32.0;
const _burnWeekBarMarkerWidth = 3.0;
const _burnWeekHeaderSideWidth = 104.0;

/// One stat shown inside the Burn Week overview card.
class BurnWeekOverviewStatData {
  /// Creates stat data for Burn Week overview card.
  const BurnWeekOverviewStatData({
    required this.title,
    required this.value,
    required this.borderColor,
    this.key,
  });

  /// Optional key for testing.
  final Key? key;

  /// Card title.
  final String title;

  /// Card value.
  final String value;

  /// Border and accent color.
  final Color borderColor;
}

/// Shared Burn Week card used by mock and live pages.
class BurnWeekOverviewCard extends StatelessWidget {
  /// Creates Burn Week overview card.
  const BurnWeekOverviewCard({
    required this.title,
    required this.metrics,
    required this.numberFormat,
    required this.kcalUnit,
    required this.primaryStat,
    required this.secondaryStat,
    super.key,
    this.barKey,
    this.starCount,
    this.heartCount,
    this.onHeartTap,
    this.onInfoPressed,
    this.infoTooltip,
  });

  /// Center title.
  final String title;

  /// Burn Week metrics.
  final BurnWeekMockMetrics metrics;

  /// Number formatter.
  final NumberFormat numberFormat;

  /// Kcal unit label.
  final String kcalUnit;

  /// First stat card.
  final BurnWeekOverviewStatData primaryStat;

  /// Second stat card.
  final BurnWeekOverviewStatData secondaryStat;

  /// Optional key for the bar.
  final Key? barKey;

  /// Optional star counter.
  final int? starCount;

  /// Optional heart counter.
  final int? heartCount;

  /// Optional heart tap callback.
  final VoidCallback? onHeartTap;

  /// Optional info button callback.
  final VoidCallback? onInfoPressed;

  /// Optional info button tooltip.
  final String? infoTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasStarBadge = starCount != null;
    final hasHeartBadge = heartCount != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _burnWeekHeaderSideWidth,
                  child: hasStarBadge || hasHeartBadge
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasStarBadge)
                                _BurnWeekCounterBadge(
                                  icon: Icons.stars_rounded,
                                  iconColor: colors.error,
                                  label: 'x $starCount',
                                ),
                              if (hasHeartBadge)
                                _BurnWeekCounterBadge(
                                  icon: Icons.favorite,
                                  iconColor: colors.error,
                                  label: 'x $heartCount',
                                  onTap: onHeartTap,
                                ),
                            ],
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: _burnWeekHeaderSideWidth,
                  child: onInfoPressed != null
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: onInfoPressed,
                            icon: const Icon(Icons.info_outline_rounded),
                            tooltip: infoTooltip,
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _BurnWeekOverviewBar(
              key: barKey,
              metrics: metrics,
              numberFormat: numberFormat,
              kcalUnit: kcalUnit,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: CalorieMetricStatCard(
                    key: primaryStat.key,
                    title: primaryStat.title,
                    value: primaryStat.value,
                    borderColor: primaryStat.borderColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: CalorieMetricStatCard(
                    key: secondaryStat.key,
                    title: secondaryStat.title,
                    value: secondaryStat.value,
                    borderColor: secondaryStat.borderColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BurnWeekCounterBadge extends StatelessWidget {
  const _BurnWeekCounterBadge({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AppInkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _BurnWeekOverviewBar extends StatelessWidget {
  const _BurnWeekOverviewBar({
    required this.metrics,
    required this.numberFormat,
    required this.kcalUnit,
    super.key,
  });

  final BurnWeekMockMetrics metrics;
  final NumberFormat numberFormat;
  final String kcalUnit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 88,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final safeLeft = width * metrics.safeZoneStartRatio;
          final safeRight = width * metrics.safeZoneEndRatio;
          final targetLeft = width * metrics.targetRatio;
          final heartLeft = width * metrics.consumedRatio;
          final plannedRight = width * metrics.plannedEndRatio;
          final safeWidth = math.max<double>(0, safeRight - safeLeft);
          final plannedWidth = math.max<double>(0, plannedRight - heartLeft);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: _burnWeekBarTrackHeight,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            _burnWeekBarTrackHeight / 2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      left: safeLeft,
                      width: safeWidth,
                      child: Container(
                        height: _burnWeekBarTrackHeight - 8,
                        decoration: BoxDecoration(
                          color: colors.tertiary.withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(
                            (_burnWeekBarTrackHeight - 8) / 2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: targetLeft - (_burnWeekBarMarkerWidth / 2),
                      child: Container(
                        width: _burnWeekBarMarkerWidth,
                        height: _burnWeekBarTrackHeight + 8,
                        color: colors.secondary,
                      ),
                    ),
                    if (plannedWidth > 0)
                      Positioned(
                        top: 24,
                        left: heartLeft,
                        width: plannedWidth,
                        child: Container(
                          height: _burnWeekBarTrackHeight - 16,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(
                              (_burnWeekBarTrackHeight - 16) / 2,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 17,
                      left:
                          heartLeft.clamp(15.0, math.max(15.0, width - 15)) -
                          15,
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: colors.error,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatKcal(metrics.barMinKcal),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    _formatKcal(metrics.barMaxKcal),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatKcal(double value) {
    return '${numberFormat.format(value.round())} $kcalUnit';
  }
}
