part of 'diary_steps_card.dart';

class _StepsCardContent extends StatelessWidget {
  const _StepsCardContent({
    required this.totalSteps,
    required this.stepGoal,
    required this.progress,
    required this.showChevron,
    required this.isExpanded,
  });

  final int? totalSteps;
  final int stepGoal;
  final double progress;
  final bool showChevron;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final l10n = AppLocalizations.of(context)!;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final accentColor = DiaryAccentColors.of(context).stepsFor(
      colors.brightness,
    );

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        accentColor.withValues(alpha: isDark ? 0.16 : 0.1),
                        colors.surfaceContainerLow,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.directions_walk_rounded,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: Text(
                      l10n.diaryStepsTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: totalSteps == null
                          ? '—'
                          : numberFormat.format(totalSteps),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    TextSpan(
                      text: ' / ${numberFormat.format(stepGoal)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: AppSpacing.xs),
              AnimatedRotation(
                turns: isExpanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          key: DiaryStepsCardKeys.progressTrack,
          height: 12,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                tween: Tween<double>(begin: 0, end: clampedProgress),
                builder: (context, value, child) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      key: DiaryStepsCardKeys.progressFill,
                      width: constraints.maxWidth * value,
                      height: constraints.maxHeight,
                      child: child,
                    ),
                  );
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StepsCardSkeleton extends StatelessWidget {
  const _StepsCardSkeleton({
    required this.showChevron,
    required this.isExpanded,
  });

  final bool showChevron;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            DiarySkeletonBlock(
              width: 36,
              height: 36,
              color: colors.surfaceContainerHighest,
            ),
            const SizedBox(width: AppSpacing.md),
            DiarySkeletonBlock(
              width: 86,
              height: 18,
              color: colors.surfaceContainerHighest,
            ),
            const Spacer(),
            DiarySkeletonBlock(
              width: 112,
              height: 24,
              color: colors.surfaceContainerHighest,
            ),
            if (showChevron) ...[
              const SizedBox(width: AppSpacing.xs),
              AnimatedRotation(
                turns: isExpanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                  size: 22,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        DiarySkeletonBlock(height: 12, color: colors.surfaceContainerHighest),
      ],
    );
  }
}
