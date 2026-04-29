import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_health_weight_dialog.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/calorie_health_trend_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_today_weight_prompt_dismissal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/application/diary_activity_weight_service.dart';
import 'package:yamt/features/diary/presentation/diary_theme.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_card_helpers.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_workouts_card.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_entries_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

export 'package:yamt/features/diary/application/diary_activity_weight_service.dart'
    show DiaryActivityWeightData, DiaryWeightDayData;

part 'diary_health_connect_metric_card.dart';
part 'diary_weight_details_card.dart';
part 'diary_activity_metric_shells.dart';

/// Provides real activity and weight data for the selected diary day.
final FutureProviderFamily<DiaryActivityWeightData, DateTime>
diaryActivityWeightDataProvider =
    FutureProvider.family<DiaryActivityWeightData, DateTime>((ref, day) async {
      final selectedDay = normalizeDiaryDay(day);
      final goalState = ref.watch(calorieGoalControllerProvider);
      final status = await ref.watch(healthConnectionControllerProvider.future);
      final manualEntries = await ref.watch(
        manualHealthWeightEntriesControllerProvider.future,
      );
      final service = ref.watch(diaryActivityWeightServiceProvider);

      return service.load(
        day: selectedDay,
        goalSettings: goalState.asData?.value,
        healthStatus: status,
        manualEntries: manualEntries,
        diaryHealthService: ref.watch(diaryHealthServiceProvider),
        healthWeightService: ref.watch(healthWeightServiceProvider),
      );
    });

/// Activity and weight cards for the diary page.
class DiaryActivityWeightCards extends ConsumerStatefulWidget {
  /// Creates activity and weight cards.
  const DiaryActivityWeightCards({required this.selectedDay, super.key});

  /// The selected diary day.
  final DateTime selectedDay;

  @override
  ConsumerState<DiaryActivityWeightCards> createState() {
    return _DiaryActivityWeightCardsState();
  }
}

class _DiaryActivityWeightCardsState
    extends ConsumerState<DiaryActivityWeightCards> {
  DiaryActivityWeightData? _lastData;
  var _isActivityExpanded = false;
  var _isWeightExpanded = false;

  @override
  Widget build(BuildContext context) {
    final dataState = ref.watch(
      diaryActivityWeightDataProvider(widget.selectedDay),
    );
    final loadedData = dataState.asData?.value;
    if (loadedData != null) {
      _lastData = loadedData;
    }
    final data = loadedData ?? _lastData;

    final showActivityTrainings =
        _isActivityExpanded &&
        data?.healthAccessState == HealthDataAccessState.ready;
    final showWeightDetails = _isWeightExpanded && data != null;
    final detailsData = data;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: data == null
                  ? const _MetricCardSkeleton()
                  : data.healthAccessState == HealthDataAccessState.ready
                  ? _ActivityMetricCard(
                      data: data,
                      isExpanded: _isActivityExpanded,
                      onToggleExpanded: () {
                        setState(() {
                          _isActivityExpanded = !_isActivityExpanded;
                        });
                      },
                    )
                  : _HealthConnectMetricCard(
                      accessState: data.healthAccessState,
                    ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: data == null
                  ? const _MetricCardSkeleton()
                  : _WeightMetricCard(
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
                        _ActivityTrainingsPanel(
                          selectedDay: widget.selectedDay,
                        ),
                      ],
                      if (showWeightDetails && detailsData != null) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _WeightDetailsCard(
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
}

class _ActivityMetricCard extends StatelessWidget {
  const _ActivityMetricCard({
    required this.data,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  final DiaryActivityWeightData data;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final l10n = AppLocalizations.of(context)!;
    final accentColors = DiaryAccentColors.of(context);
    return _MetricTapShell(
      onTap: onToggleExpanded,
      child: _MetricCardShell(
        accentColor: accentColors.activity,
        watermarkIcon: Icons.local_activity_rounded,
        titleIcon: Icons.local_activity_rounded,
        title: l10n.diaryActivityTitle,
        value: data.activityKcal == null
            ? '—'
            : numberFormat.format(data.activityKcal),
        unit: l10n.caloriesUnitKcal,
        trend: data.activityTrend,
        footer: data.activeMinutes == null
            ? l10n.diaryActivityEmpty
            : l10n.diaryActiveMinutesLabel(
                numberFormat.format(data.activeMinutes),
              ),
        trailing: AnimatedRotation(
          turns: isExpanded ? 0.25 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Icon(
            Icons.chevron_right_rounded,
            color: accentColors.activity,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ActivityTrainingsPanel extends StatelessWidget {
  const _ActivityTrainingsPanel({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    return DiaryWorkoutsCard(selectedDay: selectedDay);
  }
}

class _WeightMetricCard extends ConsumerWidget {
  const _WeightMetricCard({
    required this.data,
    required this.selectedDay,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  final DiaryActivityWeightData data;
  final DateTime selectedDay;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final l10n = AppLocalizations.of(context)!;
    final weightFormat = NumberFormat(
      '0.#',
      Localizations.localeOf(context).toString(),
    );
    final accentColors = DiaryAccentColors.of(context);
    final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
    final dismissalController = ref.watch(
      calorieTodayWeightPromptDismissalControllerProvider.notifier,
    );
    ref.watch(calorieTodayWeightPromptDismissalControllerProvider);
    final showWeightWarning =
        !data.hasSelectedDayWeight &&
        !dismissalController.isDismissedForDay(normalizedSelectedDay);

    if (showWeightWarning) {
      return _WeightMissingPromptCard(
        onTrack: () => unawaited(
          _showWeightDialog(
            context: context,
            ref: ref,
            selectedDay: normalizedSelectedDay,
            day: normalizedSelectedDay,
            initialWeightKg: data.selectedWeightKg,
            canClearWeight: false,
            healthSample: null,
          ),
        ),
        onDismiss: () => unawaited(
          dismissalController.dismissForDay(normalizedSelectedDay),
        ),
      );
    }

    final profileWeightKg = data.profileWeightKg;
    return _MetricTapShell(
      onTap: onToggleExpanded,
      child: _MetricCardShell(
        accentColor: accentColors.weight,
        watermarkIcon: Icons.trending_down_rounded,
        titleIcon: Icons.trending_down_rounded,
        title: l10n.diaryWeightTitle,
        value: data.selectedWeightKg == null
            ? '—'
            : weightFormat.format(data.selectedWeightKg),
        unit: l10n.caloriesUnitKg,
        trend: data.weightTrend,
        footer: profileWeightKg == null
            ? l10n.diarySevenDaysLabel
            : l10n.diaryProfileWeightLabel(
                numberFormat.format(profileWeightKg),
              ),
        trailing: AnimatedRotation(
          turns: isExpanded ? 0.25 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Icon(
            Icons.chevron_right_rounded,
            color: accentColors.weight,
            size: 20,
          ),
        ),
      ),
    );
  }
}
