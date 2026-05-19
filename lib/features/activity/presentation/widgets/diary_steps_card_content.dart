import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Content for the loaded diary steps card.
class StepsCardContent extends StatelessWidget {
  /// Creates loaded steps card content.
  const StepsCardContent({
    required this.totalSteps,
    required this.stepGoal,
    required this.progress,
    required this.showChevron,
    required this.isExpanded,
    required this.progressTrackKey,
    required this.progressFillKey,
    super.key,
  });

  /// Total steps for selected day.
  final int? totalSteps;

  /// Daily step target.
  final int stepGoal;

  /// Progress from 0 to 1.
  final double progress;

  /// Whether the card can expand.
  final bool showChevron;

  /// Whether the card is expanded.
  final bool isExpanded;

  /// Key for progress track tests.
  final Key progressTrackKey;

  /// Key for progress fill tests.
  final Key progressFillKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final l10n = AppLocalizations.of(context)!;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final accentColor = MetricAccentColors.of(context).stepsFor(
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
                        AppEditorialSurfaces.liftedCard(colors),
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
          key: progressTrackKey,
          height: 12,
          decoration: BoxDecoration(
            color: AppEditorialSurfaces.appBackground(colors),
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
                      key: progressFillKey,
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

/// Loading skeleton for the diary steps card.
class StepsCardSkeleton extends StatelessWidget {
  /// Creates loading skeleton.
  const StepsCardSkeleton({
    required this.showChevron,
    required this.isExpanded,
    super.key,
  });

  /// Whether the card can expand.
  final bool showChevron;

  /// Whether the card is expanded.
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MetricSkeletonBlock(
              width: 36,
              height: 36,
              color: colors.surfaceContainerHighest,
            ),
            const SizedBox(width: AppSpacing.md),
            MetricSkeletonBlock(
              width: 86,
              height: 18,
              color: colors.surfaceContainerHighest,
            ),
            const Spacer(),
            MetricSkeletonBlock(
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
        MetricSkeletonBlock(height: 12, color: colors.surfaceContainerHighest),
      ],
    );
  }
}
