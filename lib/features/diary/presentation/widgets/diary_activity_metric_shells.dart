part of 'diary_activity_weight_cards.dart';

class _MetricTapShell extends StatelessWidget {
  const _MetricTapShell({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: AppInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }
}

class _WeightMissingPromptCard extends StatelessWidget {
  const _WeightMissingPromptCard({
    required this.onTrack,
    required this.onDismiss,
  });

  final VoidCallback onTrack;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final accentColors = DiaryAccentColors.of(context);
    final titleColor = accentColors.activityFor(colors.brightness);
    final textColor = accentColors.activityTextFor(colors.brightness);
    final backgroundColor = Color.alphaBlend(
      titleColor.withValues(alpha: isDark ? 0.16 : 0.08),
      colors.surfaceContainerLow,
    );
    final borderColor = titleColor.withValues(alpha: isDark ? 0.38 : 0.24);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: accentColors.activity.withValues(
              alpha: isDark ? 0.1 : 0.15,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -16,
              right: -16,
              child: Icon(
                Icons.trending_down_rounded,
                size: 82,
                color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.35),
              ),
            ),
            Positioned(
              top: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Icon(Icons.add_rounded, color: titleColor, size: 18),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: titleColor,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          l10n.diaryWeightTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.diaryWeightMissingPrompt,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: onTrack,
                          style: TextButton.styleFrom(
                            foregroundColor: titleColor,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            textStyle: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                          ),
                          child: Text(l10n.diaryWeightTrackNowAction),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      TextButton(
                        onPressed: onDismiss,
                        style: TextButton.styleFrom(
                          foregroundColor: textColor,
                          backgroundColor: accentColors.activity.withValues(
                            alpha: isDark ? 0.18 : 0.12,
                          ),
                          minimumSize: const Size(44, 30),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          textStyle: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(l10n.diaryOkAction),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCardShell extends StatelessWidget {
  const _MetricCardShell({
    required this.accentColor,
    required this.watermarkIcon,
    required this.titleIcon,
    required this.title,
    required this.value,
    required this.unit,
    required this.trend,
    required this.footer,
    this.trailing,
  });

  final Color accentColor;
  final IconData watermarkIcon;
  final IconData titleIcon;
  final String title;
  final String value;
  final String unit;
  final List<double?> trend;
  final String footer;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return DiaryMetricCardFrame(
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -18,
            child: Icon(
              watermarkIcon,
              size: 86,
              color: colors.onSurface.withValues(alpha: isDark ? 0.05 : 0.03),
            ),
          ),
          if (trailing != null)
            Positioned(
              top: AppSpacing.lg,
              right: AppSpacing.lg,
              child: trailing!,
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(titleIcon, color: accentColor, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: value,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        TextSpan(
                          text: ' $unit',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 32,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SparklinePainter(
                        values: trend,
                        color: accentColor,
                        backgroundColor: colors.surfaceContainerLowest,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          footer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.diarySevenDaysLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.backgroundColor,
  });

  final List<double?> values;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final indexedValues = <({int index, double value})>[
      for (var index = 0; index < values.length; index += 1)
        if (values[index] != null) (index: index, value: values[index]!),
    ];
    if (indexedValues.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    final minValue = indexedValues.map((point) => point.value).reduce(math.min);
    final maxValue = indexedValues.map((point) => point.value).reduce(math.max);
    final valueRange = maxValue - minValue == 0 ? 1.0 : maxValue - minValue;
    final path = Path();

    for (
      var pointIndex = 0;
      pointIndex < indexedValues.length;
      pointIndex += 1
    ) {
      final point = indexedValues[pointIndex];
      final x = values.length <= 1
          ? 0.0
          : (point.index / (values.length - 1)) * size.width;
      final y =
          size.height -
          ((point.value - minValue) / valueRange) * (size.height - 8) -
          4;
      if (pointIndex == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final lastPoint = indexedValues.last;
    final lastX = (lastPoint.index / (values.length - 1)) * size.width;
    final lastY =
        size.height -
        ((lastPoint.value - minValue) / valueRange) * (size.height - 8) -
        4;
    final dotFill = Paint()..color = backgroundColor;
    final dotStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas
      ..drawCircle(Offset(lastX, lastY), 3.2, dotFill)
      ..drawCircle(Offset(lastX, lastY), 3.2, dotStroke);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _MetricCardSkeleton extends StatelessWidget {
  const _MetricCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DiaryMetricCardFrame(
      clip: false,
      withShadow: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiarySkeletonBlock(
            width: 86,
            height: 14,
            color: colors.surfaceContainerHighest,
          ),
          const SizedBox(height: AppSpacing.sm),
          DiarySkeletonBlock(
            width: 92,
            height: 24,
            color: colors.surfaceContainerHighest,
          ),
          const SizedBox(height: AppSpacing.md),
          DiarySkeletonBlock(
            height: 32,
            color: colors.surfaceContainerHighest,
          ),
          const SizedBox(height: AppSpacing.md),
          DiarySkeletonBlock(
            width: 74,
            height: 12,
            color: colors.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}
