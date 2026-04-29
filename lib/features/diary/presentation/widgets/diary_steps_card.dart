import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_card_helpers.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';

/// Provides real step data for one Tagebuch day.
final FutureProvider<DiaryActivitySummary> Function(DateTime)
diaryStepsSummaryProvider =
    FutureProvider.family<DiaryActivitySummary, DateTime>((ref, day) async {
      final normalizedDay = normalizeDiaryDay(day);
      final userHeightCm = ref
          .watch(calorieGoalControllerProvider)
          .asData
          ?.value
          .calculatorProfile
          ?.heightCm;
      final status = await ref.watch(healthConnectionControllerProvider.future);
      if (status.accessState != HealthDataAccessState.ready) {
        return DiaryActivitySummary.locked(
          day: normalizedDay,
          accessState: status.accessState,
        );
      }

      final dayData = await ref
          .watch(diaryHealthServiceProvider)
          .loadDayData(day: normalizedDay, userHeightCm: userHeightCm);
      return buildDiaryActivitySummary(day: normalizedDay, dayData: dayData);
    });

/// Steps card for the Tagebuch page.
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

    final summaryState = ref.watch(
      diaryStepsSummaryProvider(widget.selectedDay),
    );

    final canExpand = widget.expandedContent != null;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: canExpand
                ? () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(24),
            child: DiaryDetailCardShell(
              child: summaryState.when(
                loading: () => _StepsCardSkeleton(
                  showChevron: canExpand,
                  isExpanded: _isExpanded,
                ),
                error: (_, _) => _StepsCardContent(
                  totalSteps: null,
                  stepGoal: diaryActivityStepGoal,
                  progress: 0,
                  showChevron: canExpand,
                  isExpanded: _isExpanded,
                ),
                data: (summary) => _StepsCardContent(
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
            child: _isExpanded && widget.expandedContent != null
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final clampedProgress = progress.clamp(0.0, 1.0);
    final accentColor = isDark
        ? const Color(0xFF818CF8)
        : const Color(0xFF6366F1);

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
                      color: isDark
                          ? const Color(0x1A6366F1)
                          : const Color(0xFFEEF2FF),
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
                      'Schritte',
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
          height: 12,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1F2937)
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 3,
                offset: Offset(0, 1),
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
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x996366F1),
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
