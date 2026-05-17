import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/core/widgets/metric_card_shell/metric_card_skeleton.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/activity/presentation/widgets/activity_card/diary_activity_card.dart';
import 'package:yamt/features/activity/presentation/widgets/activity_weight_section/diary_activity_weight_section_keys.dart';
import 'package:yamt/features/activity/presentation/widgets/diary_activity_details_card.dart';
import 'package:yamt/features/activity/presentation/widgets/diary_steps_card.dart';
import 'package:yamt/features/activity/presentation/widgets/health_connect_metric_card/diary_health_connect_metric_card.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_card.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_details_card.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _activityWeightStartupDelay = Duration(milliseconds: 700);

/// Activity and weight section for the diary page.
class DiaryActivityWeightSection extends ConsumerStatefulWidget {
  /// Creates the activity and weight section.
  const DiaryActivityWeightSection({
    required this.selectedDay,
    super.key,
  });

  /// The selected diary day.
  final DateTime selectedDay;

  @override
  ConsumerState<DiaryActivityWeightSection> createState() {
    return _DiaryActivityWeightSectionState();
  }
}

class _DiaryActivityWeightSectionState
    extends ConsumerState<DiaryActivityWeightSection> {
  DiaryActivityWeightData? _lastData;
  Timer? _startupTimer;
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
    final normalizedDay = normalizeDiaryDay(widget.selectedDay);
    final dataState = _canLoadData
        ? ref.watch(diaryActivityWeightDataProvider(normalizedDay))
        : const AsyncLoading<DiaryActivityWeightData>();
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

    final showActivityTrainings =
        _isActivityExpanded &&
        data?.healthAccessState == HealthDataAccessState.ready;
    final showWeightDetails = _isWeightExpanded && data != null;
    final showStepsCard =
        data?.healthAccessState == HealthDataAccessState.ready;
    final detailsData = data;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: data == null
                  ? const MetricCardSkeleton()
                  : data.healthAccessState == HealthDataAccessState.ready
                  ? DiaryActivityCard(
                      data: data,
                      isExpanded: _isActivityExpanded,
                      onToggleExpanded: () {
                        setState(() {
                          _isActivityExpanded = !_isActivityExpanded;
                        });
                      },
                    )
                  : DiaryHealthConnectMetricCard(
                      accessState: data.healthAccessState,
                    ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: data == null
                  ? const MetricCardSkeleton()
                  : DiaryWeightCard(
                      data: data,
                      selectedDay: widget.selectedDay,
                      isExpanded: _isWeightExpanded,
                      onToggleExpanded: () {
                        setState(() {
                          _isWeightExpanded = !_isWeightExpanded;
                        });
                      },
                    ),
            ),
          ],
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: showActivityTrainings || showWeightDetails
                ? Column(
                    children: [
                      if (showActivityTrainings) ...[
                        const SizedBox(height: AppSpacing.xl),
                        DiaryActivityTrainingsPanel(
                          selectedDay: widget.selectedDay,
                        ),
                      ],
                      if (showWeightDetails && detailsData != null) ...[
                        const SizedBox(height: AppSpacing.xl),
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
        if (showStepsCard) ...[
          const SizedBox(height: AppSpacing.xl),
          DiaryStepsCard(
            selectedDay: widget.selectedDay,
            expandedContent: DiaryActivityDetailsCard(
              selectedDay: widget.selectedDay,
            ),
          ),
        ],
      ],
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
