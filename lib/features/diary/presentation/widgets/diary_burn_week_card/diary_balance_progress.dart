import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yamt/features/calories/domain/burn_week_mock_logic.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';

/// Burn Week safe-zone progress bar.
class DiaryBalanceProgressBar extends StatelessWidget {
  /// Creates a diary balance progress bar.
  const DiaryBalanceProgressBar({required this.metrics, super.key});

  /// Burn Week metrics to render.
  final BurnWeekMockMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: diaryBalanceProgressAreaHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final safeZoneRadiusRatio = _resolveSafeZoneRadiusRatio(metrics);
          const progressTop =
              (diaryBalanceProgressAreaHeight - diaryBalanceProgressHeight) / 2;
          const flameTop =
              progressTop +
              ((diaryBalanceProgressHeight - diaryBalanceFlameIconSize) / 2);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: progressTop,
                child: Container(
                  key: DiaryBalanceCardKeys.progressTrack,
                  height: diaryBalanceProgressHeight,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              _AnimatedBalanceRatio(
                value: metrics.targetRatio,
                builder: (context, targetRatio) {
                  return _AnimatedBalanceRatio(
                    value: safeZoneRadiusRatio,
                    builder: (context, radiusRatio) {
                      final safeCenter = width * targetRatio;
                      final requestedHalfWidth = width * radiusRatio;
                      final availableHalfWidth = math.min(
                        safeCenter,
                        math.max<double>(0, width - safeCenter),
                      );
                      final safeHalfWidth = math.min(
                        requestedHalfWidth,
                        availableHalfWidth,
                      );
                      final safeWidth = safeHalfWidth * 2;

                      if (safeWidth <= 0) {
                        return const SizedBox.shrink();
                      }

                      return Positioned(
                        left: safeCenter - safeHalfWidth,
                        top: progressTop + diaryBalanceSafeZoneVerticalInset,
                        width: safeWidth,
                        child: Container(
                          key: DiaryBalanceCardKeys.safeZone,
                          height:
                              diaryBalanceProgressHeight -
                              (diaryBalanceSafeZoneVerticalInset * 2),
                          decoration: BoxDecoration(
                            color: colors.tertiary.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              _AnimatedBalanceRatio(
                value: metrics.targetRatio,
                builder: (context, targetRatio) {
                  final markerLeft = (width * targetRatio - 1.5).clamp(
                    0.0,
                    math.max<double>(
                      0,
                      width - diaryBalanceTargetMarkerWidth,
                    ),
                  );

                  return Positioned(
                    left: markerLeft,
                    top: progressTop - diaryBalanceTargetMarkerOverflowTop,
                    child: Container(
                      key: DiaryBalanceCardKeys.targetMarker,
                      width: diaryBalanceTargetMarkerWidth,
                      height:
                          diaryBalanceProgressHeight +
                          diaryBalanceTargetMarkerOverflowTop,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                },
              ),
              _AnimatedBalanceRatio(
                value: metrics.consumedRatio,
                builder: (context, consumedRatio) {
                  final flameCenter = width * consumedRatio;
                  final flameLeft =
                      (flameCenter - diaryBalanceFlameIconSize / 2).clamp(
                        0.0,
                        math.max<double>(0, width - diaryBalanceFlameIconSize),
                      );

                  return Positioned(
                    left: flameLeft,
                    top: flameTop,
                    child: const SizedBox.square(
                      key: DiaryBalanceCardKeys.consumedMarker,
                      dimension: diaryBalanceFlameIconSize,
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFD32F2F),
                        size: diaryBalanceFlameIconSize,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedBalanceRatio extends StatelessWidget {
  const _AnimatedBalanceRatio({required this.value, required this.builder});

  final double value;
  final Widget Function(BuildContext context, double value) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 0, end: value),
      builder: (context, value, child) => builder(context, value),
    );
  }
}

double _resolveSafeZoneRadiusRatio(BurnWeekMockMetrics metrics) {
  final span = metrics.barMaxKcal - metrics.barMinKcal;
  if (span <= 0) {
    return 0;
  }

  final lowerRadius = (metrics.targetKcal - metrics.safeZoneMinKcal).abs();
  final upperRadius = (metrics.safeZoneMaxKcal - metrics.targetKcal).abs();
  return (math.max(lowerRadius, upperRadius) / span).clamp(0.0, 0.5);
}
