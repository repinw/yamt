import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/activity/application/diary_steps_summary_provider.dart';
import 'package:yamt/features/activity/presentation/widgets/diary_steps_card_keys.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Steps card for the diary page.
class DiaryStepsCard extends ConsumerStatefulWidget {
  /// Creates a diary steps card.
  const DiaryStepsCard({
    required this.selectedDay,
    this.expandedContent,
    super.key,
  });

  /// The selected diary day.
  final DateTime selectedDay;

  /// Content shown below the card when it is expanded.
  final Widget? expandedContent;

  @override
  ConsumerState<DiaryStepsCard> createState() => _DiaryStepsCardState();
}

class _DiaryStepsCardState extends ConsumerState<DiaryStepsCard>
    with AutomaticKeepAliveClientMixin<DiaryStepsCard> {
  var _isExpanded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final normalizedDay = normalizeDiaryDay(widget.selectedDay);
    final summaryState = ref.watch(
      diaryStepsSummaryProvider(normalizedDay),
    );

    final canExpand = widget.expandedContent != null && !summaryState.hasError;
    final l10n = AppLocalizations.of(context)!;
    final showExpandedContent = canExpand && _isExpanded;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: AppInkWell(
            onTap: canExpand
                ? () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(24),
            child: MetricDetailCardShell(
              child: summaryState.when(
                skipLoadingOnReload: true,
                loading: () => _DiaryStepsCardSkeleton(
                  showChevron: canExpand,
                  isExpanded: _isExpanded,
                ),
                error: (_, _) => MetricErrorRetryContent(
                  message: l10n.diaryStepsLoadFailed,
                  retryLabel: l10n.caloriesRetryAction,
                  retryButtonKey: DiaryStepsCardKeys.retryButton,
                  onRetry: () => ref.invalidate(
                    diaryStepsSummaryProvider(normalizedDay),
                  ),
                ),
                data: (summary) => _DiaryStepsCardContent(
                  totalSteps: summary.totalSteps,
                  stepGoal: summary.stepGoal,
                  progress: summary.progress,
                  showChevron: canExpand,
                  isExpanded: _isExpanded,
                ),
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: showExpandedContent
                ? Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      widget.expandedContent!,
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }
}

class _DiaryStepsCardContent extends StatelessWidget {
  const _DiaryStepsCardContent({
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

class _DiaryStepsCardSkeleton extends StatelessWidget {
  const _DiaryStepsCardSkeleton({
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
