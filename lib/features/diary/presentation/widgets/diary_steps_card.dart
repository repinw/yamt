import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/diary/presentation/diary_theme.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_card_helpers.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'diary_steps_card_content.dart';

/// Provides real step data for one diary day.
final FutureProviderFamily<DiaryActivitySummary, DateTime>
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

/// Stable keys for diary steps card tests.
abstract final class DiaryStepsCardKeys {
  /// Steps progress track key.
  static const progressTrack = ValueKey<String>('diary-steps-progress-track');

  /// Steps progress fill key.
  static const progressFill = ValueKey<String>('diary-steps-progress-fill');
}

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
