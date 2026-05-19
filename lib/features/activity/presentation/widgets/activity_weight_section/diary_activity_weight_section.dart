import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/activity/application/diary_activity_weight_data_provider.dart';
import 'package:yamt/features/activity/application/diary_steps_summary_provider.dart';
import 'package:yamt/features/activity/application/diary_weight_actions.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/activity/presentation/widgets/activity_card/diary_activity_card.dart';
import 'package:yamt/features/activity/presentation/widgets/activity_weight_section/diary_activity_weight_section_keys.dart';
import 'package:yamt/features/activity/presentation/widgets/diary_activity_details_card.dart';
import 'package:yamt/features/activity/presentation/widgets/health_connect_metric_card/diary_health_connect_metric_card.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_details_card.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_dialog.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_missing_prompt_card.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/diary_weight_prompt_dismissal_controller.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/domain/diary_activity_summary.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
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
    final normalizedDay = normalizeDiaryDay(widget.selectedDay);
    final dataState = _canLoadData
        ? ref.watch(diaryActivityWeightDataProvider(normalizedDay))
        : const AsyncLoading<DiaryActivityWeightData>();
    final stepsState = _canLoadData
        ? ref.watch(diaryStepsSummaryProvider(normalizedDay))
        : const AsyncLoading<DiaryActivitySummary>();
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
        dismissedDayKey != diaryDayKey(normalizedDay);
    final hasReadyHealth =
        data?.healthAccessState == HealthDataAccessState.ready;
    final showActivityTrainings = _isActivityExpanded && hasReadyHealth;
    final showWeightDetails =
        _isWeightExpanded && data != null && !showWeightWarning;
    final showStepDetails = _isStepsExpanded && hasReadyHealth;
    final detailsData = data;

    return Column(
      children: [
        if (data == null)
          _CompactActivityWeightSkeleton(header: widget.header)
        else
          _CompactActivityWeightCard(
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
        if (data != null &&
            data.healthAccessState != HealthDataAccessState.ready) ...[
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

class _CompactActivityWeightCard extends StatelessWidget {
  const _CompactActivityWeightCard({
    required this.data,
    required this.header,
    required this.stepsState,
    required this.isStepsExpanded,
    required this.isActivityExpanded,
    required this.isWeightExpanded,
    required this.onToggleSteps,
    required this.onToggleActivity,
    required this.onTapWeight,
  });

  final DiaryActivityWeightData data;
  final Widget? header;
  final AsyncValue<DiaryActivitySummary> stepsState;
  final bool isStepsExpanded;
  final bool isActivityExpanded;
  final bool isWeightExpanded;
  final VoidCallback onToggleSteps;
  final VoidCallback onToggleActivity;
  final VoidCallback onTapWeight;

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(localeName);
    final weightFormat = NumberFormat('0.#', localeName);
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final accents = MetricAccentColors.of(context);
    final summary = stepsState.value;
    final totalSteps = summary?.totalSteps;
    final stepsValue = totalSteps == null
        ? '-'
        : numberFormat.format(totalSteps);
    final activityValue = data.activityKcal == null
        ? '-'
        : '${numberFormat.format(data.activityKcal)} '
              '${l10n.caloriesUnitKcal}';
    final weightValue = data.selectedWeightKg == null
        ? '-'
        : '${weightFormat.format(data.selectedWeightKg)} '
              '${l10n.caloriesUnitKg}';

    return _CompactMetricsFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header case final header?) ...[
            header,
            const SizedBox(height: AppSpacing.xl),
            const _CompactMetricsHorizontalDivider(),
            const SizedBox(height: AppSpacing.xl),
          ],
          Row(
            children: [
              Expanded(
                child: _CompactMetricItem(
                  icon: Icons.directions_walk_rounded,
                  color: accents.stepsFor(colors.brightness),
                  label: l10n.diaryStepsTitle,
                  value: stepsValue,
                  isExpanded: isStepsExpanded,
                  onTap: onToggleSteps,
                ),
              ),
              const _CompactMetricDivider(),
              Expanded(
                child: _CompactMetricItem(
                  icon: Icons.local_fire_department_rounded,
                  color: accents.activityFor(colors.brightness),
                  label: l10n.diaryActivityTitle,
                  value: activityValue,
                  isExpanded: isActivityExpanded,
                  onTap: onToggleActivity,
                ),
              ),
              const _CompactMetricDivider(),
              Expanded(
                child: _CompactMetricItem(
                  icon: Icons.monitor_weight_outlined,
                  color: accents.weight,
                  label: l10n.diaryWeightTitle,
                  value: weightValue,
                  isExpanded: isWeightExpanded,
                  onTap: onTapWeight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactMetricsFrame extends StatelessWidget {
  const _CompactMetricsFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppEditorialSurfaces.liftedCard(colors),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppEditorialSurfaces.solidCardBorder(colors)),
        boxShadow: [
          BoxShadow(
            color: AppEditorialSurfaces.ambientShadow(colors),
            blurRadius: isDark ? 22 : 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    );
  }
}

class _CompactMetricItem extends StatelessWidget {
  const _CompactMetricItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isExpanded,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AppInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: color,
                      size: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactMetricDivider extends StatelessWidget {
  const _CompactMetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(
        alpha: 0.42,
      ),
    );
  }
}

class _CompactMetricsHorizontalDivider extends StatelessWidget {
  const _CompactMetricsHorizontalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(
        alpha: 0.42,
      ),
    );
  }
}

class _CompactActivityWeightSkeleton extends StatelessWidget {
  const _CompactActivityWeightSkeleton({this.header});

  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _CompactMetricsFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header case final header?) ...[
            header,
            const SizedBox(height: AppSpacing.xl),
            const _CompactMetricsHorizontalDivider(),
            const SizedBox(height: AppSpacing.xl),
          ],
          Row(
            children: [
              for (var index = 0; index < 3; index += 1) ...[
                if (index > 0) const _CompactMetricDivider(),
                Expanded(
                  child: Column(
                    children: [
                      MetricSkeletonBlock(
                        width: 74,
                        height: 12,
                        color: colors.surfaceContainerHighest,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      MetricSkeletonBlock(
                        width: 58,
                        height: 18,
                        color: colors.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
