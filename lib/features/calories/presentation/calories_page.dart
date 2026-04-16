import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/calories_page_logic.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_bundle_details_sheet.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_week_balance_summary_banner.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_weekly_checkin_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_weekly_checkin_hint_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_activity_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_day_navigation_pager.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_meal_section_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_state_views.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_workouts_card.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_health_trends_window_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_visible_window_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CaloriesPage extends ConsumerStatefulWidget {
  const CaloriesPage({super.key, this.referenceNow});

  final DateTime? referenceNow;

  @override
  ConsumerState<CaloriesPage> createState() => _CaloriesPageState();
}

class _CaloriesPageState extends ConsumerState<CaloriesPage> {
  CalorieDayViewData? _lastResolvedDayView;
  CalorieWeeklyCheckInViewModel? _lastWeeklyCheckInViewModel;
  String? _autoOpenedWeeklyCheckInWindowKey;
  var _weeklyCheckInDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(calorieEntriesControllerProvider, _logEntriesLoadErrorOnce);
    ref.listen(calorieDayViewDataProvider, _cacheResolvedDayView);
    ref.listen(calorieWeeklyCheckInViewModelProvider, _cacheWeeklyCheckInView);

    final l10n = AppLocalizations.of(context)!;
    final dayController = ref.read(calorieDayControllerProvider.notifier);
    final selectedDay = ref.watch(calorieDayControllerProvider);
    final visibleWindowEnd = ref.watch(calorieVisibleWindowControllerProvider);
    final dayViewState = ref.watch(calorieDayViewDataProvider);
    final weekOverviewState = ref.watch(calorieWeekOverviewProvider);
    final weeklyCheckInState = ref.watch(calorieWeeklyCheckInViewModelProvider);
    final goalSettings = ref.watch(calorieGoalControllerProvider).asData?.value;
    final referenceNow = widget.referenceNow ?? DateTime.now();
    final dayView = dayViewState.value ?? _lastResolvedDayView;
    if (dayView == null) {
      if (dayViewState.hasError) {
        return CaloriesErrorView(
          onRetry: () {
            ref.read(calorieEntriesControllerProvider.notifier).refresh();
          },
          message: l10n.caloriesLoadFailed,
          retryLabel: l10n.caloriesRetryAction,
        );
      }
      return const CaloriesLoadingView();
    }

    final weekOverview = resolveDisplayedWeekOverview(
      weekOverviewState,
      goalKcal: dayView.goalKcal,
      visibleWindowEnd: visibleWindowEnd,
    );
    final weeklyCheckIn =
        weeklyCheckInState.asData?.value ?? _lastWeeklyCheckInViewModel;
    final latestGoalEntry = goalSettings?.latestGoalEntry;
    final showWeeklySuccessCard =
        latestGoalEntry?.isWeeklyCheckIn == true &&
        DateUtils.isSameDay(latestGoalEntry?.effectiveDate, referenceNow);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        140,
      ),
      children: <Widget>[
        CaloriesDayNavigationPager(
          selectedDay: selectedDay,
          visibleWindowEnd: visibleWindowEnd,
          goalKcal: dayView.goalKcal,
          visibleDaysOverview: weekOverview.days,
          referenceNow: referenceNow,
          onSelectDay: dayController.setDay,
          onWindowSettled: (windowEnd) =>
              handleVisibleWindowSettled(ref, windowEnd),
        ),
        if (dayViewState.isLoading) ...const <Widget>[
          SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            key: CaloriesPageKeys.reloadProgressIndicator,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        CaloriesSummaryCard(
          consumedKcal: dayView.summary.totalKcal,
          goalKcal: dayView.goalKcal,
          remainingKcal: dayView.remainingKcal,
          progress: dayView.progress,
          totalProtein: dayView.summary.totalProtein,
          totalCarbs: dayView.summary.totalCarbs,
          totalFat: dayView.summary.totalFat,
          consumedLabel: l10n.caloriesConsumedLabel,
          goalLabel: l10n.caloriesGoalLabel,
          remainingLabel: l10n.caloriesRemainingLabel,
          proteinLabel: l10n.caloriesProteinLabel,
          carbsLabel: l10n.caloriesCarbsLabel,
          fatLabel: l10n.caloriesFatLabel,
        ),
        const SizedBox(height: AppSpacing.md),
        CalorieWeekBalanceSummaryBanner(
          overview: weekOverview,
          referenceNow: referenceNow,
        ),
        if (weeklyCheckIn != null && weeklyCheckIn.showDiaryHint) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          CalorieWeeklyCheckInHintCard(
            viewModel: weeklyCheckIn,
            selectedDay: selectedDay,
            selectedDayHasEntries: dayView.summary.entryCount > 0,
            onContinue: () => _openWeeklyCheckInDialog(weeklyCheckIn),
            onOpenHealthTrends: () => _openHealthTrendsPage(
              visibleWindowEnd:
                  weeklyCheckIn.pendingWeeklyCheckIn?.windowEndDate,
            ),
            onToggleSelectedDaySkipped: (isSkipped) {
              return _toggleSkippedSelectedDay(
                selectedDay: selectedDay,
                isSkipped: isSkipped,
              );
            },
          ),
        ],
        if (showWeeklySuccessCard) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          CalorieWeeklyCheckInSuccessCard(
            goalKcal: latestGoalEntry?.dailyKcalGoal ?? dayView.goalKcal,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        ...dayView.sections.map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: CaloriesMealSectionCard(
              section: section,
              title: section.mealType.localizedName(l10n),
              emptyMessage: l10n.caloriesSectionEmptyState,
              onTapEntry: (entry) {
                if (entry.isBundle) {
                  showCalorieBundleDetailsSheet(context, entry: entry);
                  return;
                }
                context.push(AppRoutes.homeCaloriesEntryEditPath(entry.id));
              },
              onDeleteEntry: (entry) =>
                  _deleteEntry(context: context, ref: ref, entry: entry),
            ),
          ),
        ),
        const CaloriesActivityCard(),
        const SizedBox(height: AppSpacing.xl),
        const CaloriesWorkoutsCard(),
      ],
    );
  }

  void _cacheResolvedDayView(
    AsyncValue<CalorieDayViewData>? previous,
    AsyncValue<CalorieDayViewData> next,
  ) {
    final nextValue = next.value;
    if (nextValue == null) {
      return;
    }
    _lastResolvedDayView = nextValue;
  }

  void _cacheWeeklyCheckInView(
    AsyncValue<CalorieWeeklyCheckInViewModel>? previous,
    AsyncValue<CalorieWeeklyCheckInViewModel> next,
  ) {
    final nextValue = next.asData?.value;
    if (nextValue == null) {
      return;
    }
    _lastWeeklyCheckInViewModel = nextValue;
    _maybeOpenWeeklyCheckInDialog(previous, next);
  }

  void _logEntriesLoadErrorOnce(
    AsyncValue<List<CalorieEntry>>? previous,
    AsyncValue<List<CalorieEntry>> next,
  ) {
    final nextError = next.asError;
    if (nextError == null) {
      return;
    }

    final previousError = previous?.asError;
    final sameError = identical(previousError?.error, nextError.error);
    final sameTrace = previousError?.stackTrace == nextError.stackTrace;
    if (sameError && sameTrace) {
      return;
    }

    developer.log(
      'Failed to load calorie entries.',
      name: 'CaloriesPage',
      error: nextError.error,
      stackTrace: nextError.stackTrace,
    );
  }

  Future<void> _deleteEntry({
    required BuildContext context,
    required WidgetRef ref,
    required CalorieEntry entry,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (entry.canReturnPreparedMealToInventory) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.caloriesReturnPreparedMealDialogTitle),
            content: Text(
              l10n.caloriesReturnPreparedMealDialogMessage(entry.name),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => context.pop(false),
                child: Text(l10n.inventoryReceiptReviewCancelAction),
              ),
              TextButton(
                onPressed: () => context.pop(true),
                child: Text(l10n.caloriesReturnPreparedMealConfirmAction),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      final result = await ref
          .read(calorieEntryDeleteFlowProvider)
          .deleteEntry(entry: entry, restoreToInventory: true);
      if (!context.mounted || result.isSuccess) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      late final String message;
      if (result.failureReason ==
          CalorieEntryDeleteFailureReason.restoreFailed) {
        message = l10n.caloriesReturnPreparedMealFailed;
      } else {
        message = l10n.caloriesDeleteFailed;
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final decision = await showDialog<_CalorieEntryDeleteDialogResult>(
      context: context,
      builder: (context) {
        var restoreToInventory = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.caloriesDeleteEntryDialogTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.caloriesDeleteEntryDialogMessage(entry.name)),
                  if (entry.canRestoreToInventory) ...[
                    const SizedBox(height: AppSpacing.md),
                    CheckboxListTile(
                      key: CaloriesPageKeys.deleteRestoreCheckbox(entry.id),
                      value: restoreToInventory,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setState(() {
                          restoreToInventory = value ?? false;
                        });
                      },
                      title: Text(l10n.caloriesDeleteRestoreInventoryQuestion),
                    ),
                  ],
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.inventoryReceiptReviewCancelAction),
                ),
                TextButton(
                  onPressed: () {
                    context.pop(
                      _CalorieEntryDeleteDialogResult(
                        restoreToInventory: restoreToInventory,
                      ),
                    );
                  },
                  child: Text(l10n.caloriesDeleteEntryConfirmAction),
                ),
              ],
            );
          },
        );
      },
    );

    if (decision == null) {
      return;
    }

    final result = await ref
        .read(calorieEntryDeleteFlowProvider)
        .deleteEntry(
          entry: entry,
          restoreToInventory: decision.restoreToInventory,
        );
    if (!context.mounted || result.isSuccess) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final message = switch (result.failureReason) {
      CalorieEntryDeleteFailureReason.restoreFailed =>
        l10n.caloriesDeleteRestoreFailed,
      CalorieEntryDeleteFailureReason.deleteFailed ||
      null => l10n.caloriesDeleteFailed,
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _maybeOpenWeeklyCheckInDialog(
    AsyncValue<CalorieWeeklyCheckInViewModel>? previous,
    AsyncValue<CalorieWeeklyCheckInViewModel> next,
  ) {
    final viewModel = next.asData?.value;
    final pending = viewModel?.pendingWeeklyCheckIn;
    if (!mounted ||
        viewModel == null ||
        pending == null ||
        !viewModel.shouldAutoOpen ||
        _weeklyCheckInDialogOpen) {
      return;
    }

    if (_autoOpenedWeeklyCheckInWindowKey == pending.windowKey) {
      return;
    }
    _autoOpenedWeeklyCheckInWindowKey = pending.windowKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _openWeeklyCheckInDialog(viewModel);
    });
  }

  Future<void> _openWeeklyCheckInDialog(
    CalorieWeeklyCheckInViewModel viewModel,
  ) async {
    final pending = viewModel.pendingWeeklyCheckIn;
    if (!mounted || pending == null || _weeklyCheckInDialogOpen) {
      return;
    }

    _weeklyCheckInDialogOpen = true;
    final controller = ref.read(
      calorieWeeklyCheckInControllerProvider.notifier,
    );
    await controller.syncPendingWeeklyCheckIn(pending);
    if (!mounted) {
      _weeklyCheckInDialogOpen = false;
      return;
    }

    try {
      final action = await showCalorieWeeklyCheckInDialog(
        context,
        viewModel: viewModel,
      );
      if (!mounted) {
        return;
      }

      switch (action) {
        case CalorieWeeklyCheckInDialogAction.apply:
          final saved = await controller.applyWeeklyCheckIn(viewModel);
          if (!mounted || saved) {
            return;
          }
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.caloriesWeeklyCheckInApplyFailed)),
          );
          return;
        case CalorieWeeklyCheckInDialogAction.openHealthTrends:
          await controller.dismissPendingWeeklyCheckIn(pending);
          if (!mounted) {
            return;
          }
          _openHealthTrendsPage(visibleWindowEnd: pending.windowEndDate);
          return;
        case CalorieWeeklyCheckInDialogAction.later:
        case null:
          await controller.dismissPendingWeeklyCheckIn(pending);
          return;
      }
    } finally {
      _weeklyCheckInDialogOpen = false;
    }
  }

  void _openHealthTrendsPage({DateTime? visibleWindowEnd}) {
    final resolvedWindowEnd =
        visibleWindowEnd ?? ref.read(calorieVisibleWindowControllerProvider);
    ref
        .read(calorieHealthTrendsWindowControllerProvider.notifier)
        .setWindowEnd(resolvedWindowEnd);
    context.push(AppRoutes.homeStatisticsWeight);
  }

  Future<void> _toggleSkippedSelectedDay({
    required DateTime selectedDay,
    required bool isSkipped,
  }) async {
    final saved = await ref
        .read(calorieWeeklyCheckInControllerProvider.notifier)
        .setSkippedIntakeDay(day: selectedDay, isSkipped: isSkipped);
    if (!mounted || saved) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.caloriesGoalSaveFailed)));
  }
}

class _CalorieEntryDeleteDialogResult {
  const _CalorieEntryDeleteDialogResult({required this.restoreToInventory});

  final bool restoreToInventory;
}
