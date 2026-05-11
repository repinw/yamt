part of 'diary_balance_card.dart';

class _DiaryBalanceProgressBar extends StatelessWidget {
  const _DiaryBalanceProgressBar({required this.metrics});

  final BurnWeekMockMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: _balanceProgressAreaHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final safeZoneRadiusRatio = _resolveSafeZoneRadiusRatio(metrics);
          final progressTop =
              (_balanceProgressAreaHeight - _balanceProgressHeight) / 2;
          final flameTop =
              progressTop +
              ((_balanceProgressHeight - _balanceFlameIconSize) / 2);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: progressTop,
                child: Container(
                  key: DiaryBalanceCardKeys.progressTrack,
                  height: _balanceProgressHeight,
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
                        top: progressTop + _balanceSafeZoneVerticalInset,
                        width: safeWidth,
                        child: Container(
                          key: DiaryBalanceCardKeys.safeZone,
                          height:
                              _balanceProgressHeight -
                              (_balanceSafeZoneVerticalInset * 2),
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
                    math.max<double>(0, width - _balanceTargetMarkerWidth),
                  );

                  return Positioned(
                    left: markerLeft,
                    top: progressTop - _balanceTargetMarkerOverflowTop,
                    child: Container(
                      key: DiaryBalanceCardKeys.targetMarker,
                      width: _balanceTargetMarkerWidth,
                      height:
                          _balanceProgressHeight +
                          _balanceTargetMarkerOverflowTop,
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
                  final flameLeft = (flameCenter - _balanceFlameIconSize / 2)
                      .clamp(
                        0.0,
                        math.max<double>(0, width - _balanceFlameIconSize),
                      );

                  return Positioned(
                    left: flameLeft,
                    top: flameTop,
                    child: const SizedBox.square(
                      key: DiaryBalanceCardKeys.consumedMarker,
                      dimension: _balanceFlameIconSize,
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFD32F2F),
                        size: _balanceFlameIconSize,
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
