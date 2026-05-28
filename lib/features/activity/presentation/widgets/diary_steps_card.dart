import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/activity/application/diary_steps_summary_provider.dart';
import 'package:yamt/features/activity/presentation/widgets/diary_steps_card_content.dart';
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AppInkWell(
            onTap: canExpand
                ? () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: MetricDetailCardShell(
              child: summaryState.when(
                skipLoadingOnReload: true,
                loading: () => StepsCardSkeleton(
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
                data: (summary) => StepsCardContent(
                  totalSteps: summary.totalSteps,
                  stepGoal: summary.stepGoal,
                  progress: summary.progress,
                  showChevron: canExpand,
                  isExpanded: _isExpanded,
                  progressTrackKey: DiaryStepsCardKeys.progressTrack,
                  progressFillKey: DiaryStepsCardKeys.progressFill,
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
