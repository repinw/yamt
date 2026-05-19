import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/activity/application/diary_steps_summary_provider.dart';
import 'package:yamt/features/activity/application/diary_weight_actions.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/activity/presentation/widgets/activity_card/diary_activity_card.dart';
import 'package:yamt/features/activity/presentation/widgets/activity_weight_section/diary_activity_weight_section_keys.dart';
import 'package:yamt/features/activity/presentation/widgets/activity_weight_section/diary_compact_activity_weight_card.dart';
import 'package:yamt/features/activity/presentation/widgets/diary_activity_details_card.dart';
import 'package:yamt/features/activity/presentation/widgets/health_connect_metric_card/diary_health_connect_metric_card.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_details_card.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_dialog.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_missing_prompt_card.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_prompt_dismissal_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _activityWeightStartupDelay = Duration(milliseconds: 700);

/// Activity and weight section for the diary page.
class DiaryActivityWeightSection extends ConsumerStatefulWidget {
  /// Creates the activity and weight section.
  const DiaryActivityWeightSection({
    required this.selectedDay,
    this.header,
    super.key,
  });

  /// The selected diary day.
  final DateTime selectedDay;

  /// Optional content rendered above the compact metrics inside the same card.
  final Widget? header;

  @override
  ConsumerState<DiaryActivityWeightSection> createState() {
    return _DiaryActivityWeightSectionState();
  }
}

class _DiaryActivityWeightSectionState
    extends ConsumerState<DiaryActivityWeightSection> {
  DiaryActivityWeightData? _lastData;
  Timer? _startupTimer;
  var _isStepsExpanded = false;
  var _isActivityExpanded = false;
  var _isWeightExpanded = false;
  var _canLoadData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _startupTimer ??= Timer(_activityWeightStartupDelay, _allowDataLoad);
    });
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedDay = normalizeLocalDay(widget.selectedDay);
    final dataState = _canLoadData
        ? ref.watch(diaryActivityWeightDataProvider(normalizedDay))
        : const AsyncLoading<DiaryActivityWeightData>();
    final stepsState = _canLoadData
        ? ref
              .watch(diaryStepsSummaryProvider(normalizedDay))
              .whenData((summary) => summary.totalSteps)
        : const AsyncLoading<int?>();
    final loadedData = dataState.value;
    if (loadedData != null) {
      _lastData = loadedData;
    }
    final data = loadedData ?? _lastData;
    if (data == null && dataState.hasError) {
      final l10n = AppLocalizations.of(context)!;
      return MetricDetailCardShell(
        child: MetricErrorRetryContent(
          message: l10n.diaryActivityWeightLoadFailed,
          retryLabel: l10n.caloriesRetryAction,
          retryButtonKey: DiaryActivityWeightSectionKeys.retryButton,
          onRetry: () => ref.invalidate(
            diaryActivityWeightDataProvider(normalizedDay),
          ),
        ),
      );
    }

    final dismissedDayKey = ref.watch(
      diaryWeightPromptDismissalControllerProvider,
    );
    final showWeightWarning =
        data != null &&
        !data.hasSelectedDayWeight &&
        dismissedDayKey != localDayKey(normalizedDay);
    final hasReadyHealth = data?.hasReadyHealthAccess ?? false;
    final showActivityTrainings = _isActivityExpanded && hasReadyHealth;
    final showWeightDetails =
        _isWeightExpanded && data != null && !showWeightWarning;
    final showStepDetails = _isStepsExpanded && hasReadyHealth;
    final detailsData = data;

    return Column(
      children: [
        if (data == null)
          DiaryCompactActivityWeightSkeleton(header: widget.header)
        else
          DiaryCompactActivityWeightCard(
            data: data,
            header: widget.header,
            stepsState: stepsState,
            isStepsExpanded: _isStepsExpanded,
            isActivityExpanded: _isActivityExpanded,
            isWeightExpanded: _isWeightExpanded,
            onToggleSteps: () {
              setState(() {
                _isStepsExpanded = !_isStepsExpanded;
              });
            },
            onToggleActivity: () {
              setState(() {
                _isActivityExpanded = !_isActivityExpanded;
              });
            },
            onTapWeight: () {
              if (showWeightWarning) {
                _openWeightDialog(data, normalizedDay);
                return;
              }
              setState(() {
                _isWeightExpanded = !_isWeightExpanded;
              });
            },
          ),
        if (data != null && data.needsHealthConnection) ...[
          const SizedBox(height: AppSpacing.md),
          DiaryHealthConnectMetricCard(accessState: data.healthAccessState),
        ],
        if (data != null && showWeightWarning) ...[
          const SizedBox(height: AppSpacing.md),
          DiaryWeightMissingPromptCard(
            onTrack: () => _openWeightDialog(data, normalizedDay),
            onDismiss: () => _dismissWeightPrompt(normalizedDay),
          ),
        ],
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: showStepDetails || showActivityTrainings || showWeightDetails
                ? Column(
                    children: [
                      if (showStepDetails) ...[
                        const SizedBox(height: AppSpacing.md),
                        DiaryActivityDetailsCard(
                          selectedDay: widget.selectedDay,
                        ),
                      ],
                      if (showActivityTrainings) ...[
                        const SizedBox(height: AppSpacing.md),
                        DiaryActivityTrainingsPanel(
                          selectedDay: widget.selectedDay,
                        ),
                      ],
                      if (showWeightDetails && detailsData != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        DiaryWeightDetailsCard(
                          data: detailsData,
                          selectedDay: widget.selectedDay,
                        ),
                      ],
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }

  void _openWeightDialog(DiaryActivityWeightData data, DateTime day) {
    final weightActions = ref.read(diaryWeightActionsProvider);
    unawaited(
      showDiaryWeightDialog(
        context: context,
        weightActions: weightActions,
        selectedDay: day,
        day: day,
        initialWeightKg: data.selectedWeightKg,
        hasManualWeight: false,
        canClearWeight: false,
        healthSample: null,
      ),
    );
  }

  void _dismissWeightPrompt(DateTime day) {
    unawaited(
      ref
          .read(diaryWeightPromptDismissalControllerProvider.notifier)
          .dismissForDay(day),
    );
  }

  void _allowDataLoad() {
    if (!mounted || _canLoadData) {
      return;
    }
    setState(() {
      _canLoadData = true;
    });
  }
}
