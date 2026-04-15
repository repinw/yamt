import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/diary_activity_summary.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'diary_health_card_parts.dart';
import 'package:yamt/features/calories/provider/'
    'diary_activity_summary_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CaloriesActivityCard extends ConsumerStatefulWidget {
  const CaloriesActivityCard({super.key});

  @override
  ConsumerState<CaloriesActivityCard> createState() =>
      _CaloriesActivityCardState();
}

class _CaloriesActivityCardState extends ConsumerState<CaloriesActivityCard> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(diaryActivitySummaryProvider);
    final status = ref.watch(healthConnectionControllerProvider).asData?.value;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);
    return summaryAsync.when(
      loading: () => DiaryHealthCardFrame(
        title: l10n.caloriesActivitiesTitle,
        subtitle: l10n.caloriesActivitiesSubtitle,
        child: const LinearProgressIndicator(),
      ),
      error: (_, _) => DiaryHealthCardFrame(
        title: l10n.caloriesActivitiesTitle,
        subtitle: l10n.caloriesActivitiesSubtitle,
        child: Text(l10n.caloriesLoadFailed),
      ),
      data: (summary) {
        if (summary.accessState != HealthDataAccessState.ready) {
          return DiaryHealthCardFrame(
            title: l10n.caloriesActivitiesTitle,
            subtitle: l10n.caloriesActivitiesSubtitle,
            child: DiaryHealthAccessPrompt(
              accessState: summary.accessState,
              isBusy: _isBusy,
              permissionBody: switch (status?.platform) {
                HealthPlatform.ios => l10n.settingsAppleHealthConnectSubtitle,
                _ => l10n.settingsHealthConnectSubtitle,
              },
              historyBody: l10n.settingsHealthHistorySubtitle,
              installBody: l10n.settingsHealthInstallSubtitle,
              unsupportedBody: l10n.healthUnsupportedHint,
              onGrantAccess: _requestHealthAccess,
              onGrantHistoryAccess: _requestHistoryAccess,
              onInstallHealthConnect: _installHealthConnect,
            ),
          );
        }

        final burnedCalories = calculateDiaryBurnedCalories(
          stepsOutsideWorkouts: summary.stepsOutsideWorkouts,
          workoutCalories: summary.workouts.map(
            (workout) => workout.totalCalories,
          ),
        );

        return DiaryHealthCardFrame(
          title: l10n.caloriesActivitiesTitle,
          subtitle: l10n.caloriesActivitiesSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    numberFormat.format(summary.totalSteps ?? 0),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      '/ ${numberFormat.format(summary.stepGoal)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: LinearProgressIndicator(
                  value: summary.progress,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailRow(
                label: l10n.caloriesActivitiesStepsDuringWorkoutsLabel,
                value: summary.stepsDuringWorkouts == null
                    ? '—'
                    : numberFormat.format(summary.stepsDuringWorkouts),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailRow(
                label: l10n.caloriesActivitiesStepsOutsideWorkoutsLabel,
                value: summary.stepsOutsideWorkouts == null
                    ? '—'
                    : numberFormat.format(summary.stepsOutsideWorkouts),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailRow(
                label: l10n.caloriesActivitiesCaloriesBurnedLabel,
                value: burnedCalories == null
                    ? '—'
                    : '${numberFormat.format(burnedCalories)} '
                          '${l10n.caloriesUnitKcal}',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestHealthAccess() async {
    await _runHealthAction(
      () => ref
          .read(healthConnectionControllerProvider.notifier)
          .requestAuthorization(),
    );
  }

  Future<void> _requestHistoryAccess() async {
    await _runHealthAction(
      () => ref
          .read(healthConnectionControllerProvider.notifier)
          .requestHistoryAuthorization(),
    );
  }

  Future<void> _installHealthConnect() async {
    await _runHealthAction(
      () => ref
          .read(healthConnectionControllerProvider.notifier)
          .installHealthConnect(),
      showFailure: false,
    );
  }

  Future<void> _runHealthAction(
    Future<HealthConnectionStatus> Function() action, {
    bool showFailure = true,
  }) async {
    setState(() {
      _isBusy = true;
    });
    try {
      final status = await action();
      ref.invalidate(diaryActivitySummaryProvider);
      if (!mounted || !showFailure) {
        return;
      }
      if (status.accessState == HealthDataAccessState.permissionRequired ||
          status.accessState == HealthDataAccessState.installRequired ||
          status.accessState == HealthDataAccessState.unsupported) {
        _showFailureSnackBar();
      }
    } catch (_) {
      if (mounted && showFailure) {
        _showFailureSnackBar();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _showFailureSnackBar() {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.settingsHealthConnectFailed)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
