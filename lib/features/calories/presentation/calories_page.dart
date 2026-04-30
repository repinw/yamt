import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/calories/application/calorie_entry_delete_flow.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/calorie_page_actions.dart';
import 'package:yamt/features/calories/presentation/calories_page_logic.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_today_weight_prompt_card.dart';
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
import 'package:yamt/features/calories/provider/'
    'diary_activity_summary_provider.dart';
import 'package:yamt/features/health/provider/'
    'health_connection_controller.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines calories page.
@Dependencies([
  calorieEntryDeleteFlow,
  InventoryItemsController,
  inventoryBackedCalorieEntrySaveFlow,
])
class CaloriesPage extends ConsumerStatefulWidget {
  /// The calories page.
  const CaloriesPage({super.key, this.referenceNow});

  /// The reference now.
  final DateTime? referenceNow;

  @override
  ConsumerState<CaloriesPage> createState() => _CaloriesPageState();
}

class _CaloriesPageState extends ConsumerState<CaloriesPage>
    with WidgetsBindingObserver {
  CalorieDayViewData? _lastResolvedDayView;
  CalorieWeeklyCheckInViewModel? _lastWeeklyCheckInViewModel;
  CalorieWeeklyCheckInViewModel? _deferredWeeklyCheckInViewModel;
  String? _autoOpenedWeeklyCheckInWindowKey;
  var _weeklyCheckInDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    ref
      ..invalidate(healthConnectionControllerProvider)
      ..invalidate(diaryActivitySummaryProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(calorieEntriesControllerProvider, _logEntriesLoadErrorOnce)
      ..listen(calorieDayViewDataProvider, _cacheResolvedDayView)
      ..listen(
        calorieWeeklyCheckInViewModelProvider,
        _cacheWeeklyCheckInView,
      );

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
            unawaited(
              ref.read(calorieEntriesControllerProvider.notifier).refresh(),
            );
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
      key: CaloriesPageKeys.diaryList,
      padding: responsivePagePadding(
        context,
        top: AppSpacing.lg,
        bottom: homeShellPageBottomPadding(context),
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
        CalorieTodayWeightPromptCard(
          selectedDay: selectedDay,
          referenceNow: referenceNow,
          weeklyCheckIn: weeklyCheckIn,
        ),
        if (kDebugMode) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          // Burn Week mock stays debug-only. Real users should only see
          // the live Burn overview.
          FilledButton.tonalIcon(
            key: CaloriesPageKeys.burnWeekMockOpenButton,
            onPressed: () {
              unawaited(context.push<void>(AppRoutes.homeCaloriesBurnWeekMock));
            },
            icon: const Icon(Icons.local_fire_department_rounded),
            label: Text(l10n.caloriesOpenBurnWeekMockAction),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonalIcon(
            key: CaloriesPageKeys.calorieDebugDumpButton,
            onPressed: () {
              unawaited(
                printCalorieDebugDumpFromPage(
                  context: context,
                  ref: ref,
                  now: widget.referenceNow ?? DateTime.now(),
                ),
              );
            },
            icon: const Icon(Icons.table_chart_rounded),
            label: Text(l10n.caloriesDebugDumpAction),
          ),
        ],
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
            onToggleSelectedDaySkipped: ({required isSkipped}) {
              return toggleSkippedCalorieIntakeDay(
                context: context,
                ref: ref,
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
                unawaited(
                  context.push<void>(
                    AppRoutes.homeCaloriesEntryDetailsPath(entry.id),
                  ),
                );
              },
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
    final pending = nextValue.pendingWeeklyCheckIn;
    final willAutoOpen =
        pending != null &&
        nextValue.shouldAutoOpen &&
        _autoOpenedWeeklyCheckInWindowKey != pending.windowKey;
    if (!willAutoOpen && !_weeklyCheckInDialogOpen) {
      final controller = ref.read(
        calorieWeeklyCheckInControllerProvider.notifier,
      );
      unawaited(controller.syncLearnedTdeeCache(nextValue));
    }
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

  void _maybeOpenWeeklyCheckInDialog(
    AsyncValue<CalorieWeeklyCheckInViewModel>? previous,
    AsyncValue<CalorieWeeklyCheckInViewModel> next,
  ) {
    final viewModel = next.asData?.value;
    _scheduleWeeklyCheckInDialog(viewModel);
  }

  void _scheduleWeeklyCheckInDialog(
    CalorieWeeklyCheckInViewModel? viewModel,
  ) {
    final pending = viewModel?.pendingWeeklyCheckIn;
    if (!mounted ||
        viewModel == null ||
        pending == null ||
        !viewModel.shouldAutoOpen) {
      return;
    }

    if (_autoOpenedWeeklyCheckInWindowKey == pending.windowKey) {
      return;
    }
    if (_weeklyCheckInDialogOpen) {
      _deferredWeeklyCheckInViewModel = viewModel;
      return;
    }
    _autoOpenedWeeklyCheckInWindowKey = pending.windowKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_openWeeklyCheckInDialog(viewModel));
    });
  }

  void _scheduleDeferredWeeklyCheckInDialog() {
    final deferredViewModel = _deferredWeeklyCheckInViewModel;
    _deferredWeeklyCheckInViewModel = null;
    if (deferredViewModel == null) {
      return;
    }
    _scheduleWeeklyCheckInDialog(deferredViewModel);
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
          await controller.syncLearnedTdeeCache(viewModel);
          return;
      }
    } finally {
      _weeklyCheckInDialogOpen = false;
      _scheduleDeferredWeeklyCheckInDialog();
    }
  }

  void _openHealthTrendsPage({DateTime? visibleWindowEnd}) {
    final resolvedWindowEnd =
        visibleWindowEnd ?? ref.read(calorieVisibleWindowControllerProvider);
    ref
        .read(calorieHealthTrendsWindowControllerProvider.notifier)
        .setWindowEnd(resolvedWindowEnd);
    unawaited(context.push(AppRoutes.homeStatisticsWeight));
  }
}
