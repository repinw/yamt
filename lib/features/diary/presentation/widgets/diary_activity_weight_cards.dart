import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_health_weight_dialog.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/calorie_health_trend_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_today_weight_prompt_dismissal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_card_helpers.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_workouts_card.dart';
import 'package:yamt/features/health/domain/diary_health_day_data.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_entries_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'diary_health_connect_metric_card.dart';
part 'diary_weight_details_card.dart';
part 'diary_activity_metric_shells.dart';

/// Data for the diary activity and weight cards.
class DiaryActivityWeightData {
  /// Creates diary activity and weight data.
  const DiaryActivityWeightData({
    required this.healthAccessState,
    required this.activityKcal,
    required this.activeMinutes,
    required this.profileWeightKg,
    required this.selectedWeightKg,
    required this.hasSelectedDayWeight,
    required this.activityTrend,
    required this.weightTrend,
    required this.weightDays,
  });

  /// Health access state for activity tracking.
  final HealthDataAccessState healthAccessState;

  /// Burned kcal for the selected day.
  final int? activityKcal;

  /// Active workout minutes for the selected day.
  final int? activeMinutes;

  /// Profile weight from the calorie calculator.
  final double? profileWeightKg;

  /// Weight for the selected day, falling back to profile weight.
  final double? selectedWeightKg;

  /// Whether the selected day has a real saved weight point.
  final bool hasSelectedDayWeight;

  /// Seven day burned kcal trend.
  final List<double?> activityTrend;

  /// Seven day weight trend.
  final List<double?> weightTrend;

  /// Seven day weight entries.
  final List<DiaryWeightDayData> weightDays;
}

/// One day of weight data for the selected diary window.
class DiaryWeightDayData {
  /// Creates one weight day.
  const DiaryWeightDayData({
    required this.day,
    required this.weightKg,
    required this.hasManualWeight,
    required this.hasAppOwnedHealthWeight,
    required this.healthSample,
  });

  /// The diary day.
  final DateTime day;

  /// The weight for the day.
  final double? weightKg;

  /// Whether the app owns this day as a manual fallback entry.
  final bool hasManualWeight;

  /// Whether this day has a Health Connect entry from this app.
  final bool hasAppOwnedHealthWeight;

  /// Health sample for the day, when available.
  final HealthWeightSample? healthSample;

  /// Whether this weight can be removed by this app.
  bool get canDeleteWeight => hasManualWeight || hasAppOwnedHealthWeight;
}

/// Provides real activity and weight data for the selected diary day.
final FutureProvider<DiaryActivityWeightData> Function(DateTime)
diaryActivityWeightDataProvider =
    FutureProvider.family<DiaryActivityWeightData, DateTime>((ref, day) async {
      final selectedDay = normalizeDiaryDay(day);
      final days = List<DateTime>.generate(
        7,
        (index) => selectedDay.subtract(Duration(days: 6 - index)),
      );
      final goalState = ref.watch(calorieGoalControllerProvider);
      final calculatorProfile = goalState.asData?.value.calculatorProfile;
      final profileWeightKg = calculatorProfile?.weightKg;
      final userHeightCm = calculatorProfile?.heightCm;
      final status = await ref.watch(healthConnectionControllerProvider.future);
      final manualEntries = await ref.watch(
        manualHealthWeightEntriesControllerProvider.future,
      );
      final healthAccessState = status.accessState;

      final activityTrend = List<double?>.filled(7, null);
      int? selectedActivityKcal;
      int? selectedActiveMinutes;

      if (healthAccessState == HealthDataAccessState.ready) {
        final diaryHealthService = ref.watch(diaryHealthServiceProvider);
        final dayDataList = await Future.wait(
          days.map(
            (trendDay) => diaryHealthService.loadDayData(
              day: trendDay,
              userHeightCm: userHeightCm,
            ),
          ),
        );

        for (var index = 0; index < days.length; index += 1) {
          final summary = buildDiaryActivitySummary(
            day: days[index],
            dayData: dayDataList[index],
          );
          final burnedKcal = _resolveBurnedKcal(summary);
          activityTrend[index] = burnedKcal?.toDouble();

          if (isSameDiaryDay(days[index], selectedDay)) {
            selectedActivityKcal = burnedKcal;
            selectedActiveMinutes = _resolveActiveMinutes(dayDataList[index]);
          }
        }
      }

      final healthWeightByDay = <String, HealthWeightSample>{};
      if (status.accessState == HealthDataAccessState.ready &&
          days.isNotEmpty) {
        final healthWeightService = ref.watch(healthWeightServiceProvider);
        final healthSamples = await healthWeightService.loadWeightSamples(
          startInclusive: days.first,
          endExclusive: nextDiaryDay(days.last),
        );
        healthWeightByDay.addAll(_latestWeightByDay(healthSamples));
      }

      final manualWeightByDay = <String, double>{};
      for (final entry in manualEntries) {
        manualWeightByDay[diaryDayKey(entry.day)] = entry.weightKg;
      }

      final weightByDay = <String, double>{
        for (final entry in healthWeightByDay.entries)
          entry.key: entry.value.weightKg,
        ...manualWeightByDay,
      };
      final selectedDayKey = diaryDayKey(selectedDay);
      final weightDays = days
          .map((trendDay) {
            final dayKey = diaryDayKey(trendDay);
            return DiaryWeightDayData(
              day: trendDay,
              weightKg: weightByDay[dayKey],
              hasManualWeight: manualWeightByDay.containsKey(dayKey),
              hasAppOwnedHealthWeight:
                  healthWeightByDay[dayKey]?.isFromThisApp == true,
              healthSample: healthWeightByDay[dayKey],
            );
          })
          .toList(growable: false);
      final weightTrend = weightDays
          .map((weightDay) => weightDay.weightKg)
          .toList(growable: false);
      final selectedWeightKg = weightByDay[selectedDayKey] ?? profileWeightKg;

      return DiaryActivityWeightData(
        healthAccessState: healthAccessState,
        activityKcal: selectedActivityKcal,
        activeMinutes: selectedActiveMinutes,
        profileWeightKg: profileWeightKg,
        selectedWeightKg: selectedWeightKg,
        hasSelectedDayWeight: weightByDay.containsKey(selectedDayKey),
        activityTrend: activityTrend,
        weightTrend: weightTrend,
        weightDays: weightDays,
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
    return _MetricTapShell(
      onTap: onToggleExpanded,
      child: _MetricCardShell(
        accentColor: const Color(0xFFF97316),
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
          child: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFF97316),
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
        accentColor: const Color(0xFF3B82F6),
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
          child: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF3B82F6),
            size: 20,
          ),
        ),
      ),
    );
  }
}

int? _resolveBurnedKcal(DiaryActivitySummary summary) {
  return calculateDiaryBurnedCalories(
    stepsOutsideWorkouts: summary.stepsOutsideWorkouts,
    workoutCalories: summary.workouts.map((workout) => workout.totalCalories),
  );
}

int _resolveActiveMinutes(DiaryHealthDayData dayData) {
  return dayData.workouts.fold<int>(
    0,
    (sum, workout) => sum + workout.durationMinutes.round(),
  );
}

Map<String, HealthWeightSample> _latestWeightByDay(
  List<HealthWeightSample> samples,
) {
  final latestSampleByDay = <String, HealthWeightSample>{};
  for (final sample in samples) {
    final key = diaryDayKey(sample.recordedAt);
    final previous = latestSampleByDay[key];
    if (previous == null || sample.recordedAt.isAfter(previous.recordedAt)) {
      latestSampleByDay[key] = sample;
    }
  }
  return Map<String, HealthWeightSample>.unmodifiable(latestSampleByDay);
}
