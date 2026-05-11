import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/calories/application/inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/calorie_page_actions.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_weekly_checkin_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_weekly_checkin_hint_card.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_health_trends_window_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_page_action_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_controller.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/domain/diary_intro_preferences.dart';
import 'package:yamt/features/diary/presentation/diary_intro_trigger_provider.dart';
import 'package:yamt/features/diary/presentation/diary_scroll_controller.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_weekly_checkin_dialog_scheduler.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_activity_details_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_activity_weight_cards.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_balance_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_calendar_strip.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_intro_dialog.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_scroll_shortcut.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card.dart';
import 'package:yamt/features/diary/provider/diary_calendar_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/home/widgets/home_shell_chrome.dart'
    show HomeTabType;
import 'package:yamt/features/home/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/inventory/provider/prepared_meals_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Diary content.
@Dependencies([
  InventoryItemsController,
  PreparedMealsController,
  inventoryBackedCalorieEntrySaveFlow,
])
class DiaryPage extends ConsumerStatefulWidget {
  /// The diary page.
  const DiaryPage({super.key, this.includeHomeShellChrome = false});

  /// Key used by the shell and later design tests.
  static const pageKey = ValueKey<String>('diary-page');

  /// Whether to render the shared home shell app bar as a sliver.
  final bool includeHomeShellChrome;

  @override
  ConsumerState<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryWeeklyCheckInHintHost extends ConsumerWidget {
  const _DiaryWeeklyCheckInHintHost({
    required this.viewModel,
    required this.selectedDay,
    required this.onContinue,
    required this.onOpenHealthTrends,
    required this.onToggleSelectedDaySkipped,
  });

  final CalorieWeeklyCheckInViewModel viewModel;
  final DateTime selectedDay;
  final VoidCallback onContinue;
  final VoidCallback onOpenHealthTrends;
  final Future<void> Function({
    required DateTime selectedDay,
    required bool isSkipped,
  })
  onToggleSelectedDaySkipped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDayOverview = ref
        .watch(calorieWeekDayOverviewForDateProvider(selectedDay))
        .value;

    return CalorieWeeklyCheckInHintCard(
      viewModel: viewModel,
      selectedDay: selectedDay,
      selectedDayHasEntries: (selectedDayOverview?.entryCount ?? 0) > 0,
      onContinue: onContinue,
      onOpenHealthTrends: onOpenHealthTrends,
      onToggleSelectedDaySkipped: ({required isSkipped}) {
        return onToggleSelectedDaySkipped(
          selectedDay: selectedDay,
          isSkipped: isSkipped,
        );
      },
    );
  }
}

class _DiaryPageState extends ConsumerState<DiaryPage>
    with WidgetsBindingObserver {
  final DiaryScrollController _diaryScrollController = DiaryScrollController();
  final DiaryWeeklyCheckInDialogScheduler _weeklyCheckInDialogs =
      DiaryWeeklyCheckInDialogScheduler();
  ProviderSubscription<AsyncValue<CalorieWeeklyCheckInViewModel>>?
  _weeklyCheckInSubscription;
  ProviderSubscription<DiaryIntroTrigger?>? _diaryIntroSubscription;
  AsyncValue<CalorieWeeklyCheckInViewModel> _weeklyCheckInState =
      const AsyncLoading<CalorieWeeklyCheckInViewModel>();
  bool _didQueueDiaryIntro = false;
  String? _hiddenWeeklyCheckInWindowKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _startDeferredDiarySubscriptions();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _diaryIntroSubscription?.close();
    _weeklyCheckInSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    _diaryScrollController.dispose();
    _weeklyCheckInDialogs.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    ref.read(diaryCalendarControllerProvider.notifier).refreshToday();
    ref
      ..invalidate(healthConnectionControllerProvider)
      ..invalidate(calorieWeeklyCheckInViewModelProvider);
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(diaryCalendarControllerProvider);
    final calendarController = ref.read(
      diaryCalendarControllerProvider.notifier,
    );
    final weeklyCheckInState = _weeklyCheckInState;
    final rawWeeklyCheckIn =
        weeklyCheckInState.value ?? _weeklyCheckInDialogs.lastViewModel;
    final weeklyCheckIn = _isHiddenWeeklyCheckIn(rawWeeklyCheckIn)
        ? null
        : rawWeeklyCheckIn;
    final hasAutoOpeningWeeklyCheckIn =
        weeklyCheckInState.isLoading ||
        (weeklyCheckIn?.pendingWeeklyCheckIn != null &&
            weeklyCheckIn?.shouldAutoOpen == true);
    final goalSettings = ref.watch(calorieGoalControllerProvider).value;
    final latestGoalHistoryEntry = _latestGoalHistoryEntry(goalSettings);
    final referenceNow = DateTime.now();
    final showWeeklySuccessCard =
        latestGoalHistoryEntry?.isWeeklyCheckIn == true &&
        DateUtils.isSameDay(
          latestGoalHistoryEntry?.effectiveDate,
          referenceNow,
        );
    final healthConnectionState = ref.watch(healthConnectionControllerProvider);
    final healthStatus = healthConnectionState.value;
    final showActivityTrackingWidgets =
        healthStatus?.accessState == HealthDataAccessState.ready;
    final runState = ref.watch(burnWeekRunControllerProvider).value;
    final showIntroReplayButton =
        runState?.runWeekNumber == burnWeekLearningRunWeekNumber &&
        goalSettings != null &&
        !goalSettings.hasLearnedTdee &&
        DiaryIntroData.canBuildFrom(goalSettings);

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _diaryScrollController.handleScrollNotification,
          child: CustomScrollView(
            key: DiaryPage.pageKey,
            controller: _diaryScrollController.scrollController,
            cacheExtent: 0,
            slivers: [
              if (widget.includeHomeShellChrome)
                const HomeShellTabTopChrome(tab: HomeTabType.diary),
              SliverPadding(
                padding: responsivePagePadding(
                  context,
                  top: AppSpacing.lg,
                  bottom: homeShellPageBottomPadding(context),
                ),
                sliver: SliverList.list(
                  children: [
                    DiaryCalendarStrip(
                      today: calendarState.today,
                      selectedDay: calendarState.selectedDay,
                      todayRequest: calendarState.todayRequest,
                      heartDayKeys:
                          runState?.heartDayKeys.toSet() ?? const <String>{},
                      onSelectDay: calendarController.selectDay,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    DiaryBalanceCard(
                      selectedDay: calendarState.selectedDay,
                      hasAutoOpeningWeeklyCheckIn: hasAutoOpeningWeeklyCheckIn,
                    ),
                    if (showIntroReplayButton) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          key: DiaryIntroDialogKeys.replayButton,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _openDiaryIntroReplay(
                            goalSettings: goalSettings,
                            healthStatus: healthStatus,
                          ),
                          icon: const Icon(
                            Icons.help_outline_rounded,
                            size: 18,
                          ),
                          label: Text(
                            AppLocalizations.of(
                              context,
                            )!.diaryIntroReplayAction,
                          ),
                        ),
                      ),
                    ],
                    if (weeklyCheckIn != null &&
                        weeklyCheckIn.showDiaryHint) ...[
                      const SizedBox(height: AppSpacing.md),
                      _DiaryWeeklyCheckInHintHost(
                        viewModel: weeklyCheckIn,
                        selectedDay: calendarState.selectedDay,
                        onContinue: () =>
                            _openWeeklyCheckInDialog(weeklyCheckIn),
                        onOpenHealthTrends: () => _openHealthTrendsPage(
                          visibleWindowEnd:
                              weeklyCheckIn.pendingWeeklyCheckIn?.windowEndDate,
                        ),
                        onToggleSelectedDaySkipped:
                            _toggleSkippedCalorieIntakeDay,
                      ),
                    ],
                    if (showWeeklySuccessCard) ...[
                      const SizedBox(height: AppSpacing.md),
                      CalorieWeeklyCheckInSuccessCard(
                        goalKcal:
                            latestGoalHistoryEntry?.dailyKcalGoal ??
                            goalSettings?.dailyKcalGoal ??
                            0,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    DiaryNutritionBars(selectedDay: calendarState.selectedDay),
                    const SizedBox(height: AppSpacing.xl),
                    DiaryActivityWeightCards(
                      selectedDay: calendarState.selectedDay,
                    ),
                    if (showActivityTrackingWidgets) ...[
                      const SizedBox(height: AppSpacing.xl),
                      DiaryStepsCard(
                        selectedDay: calendarState.selectedDay,
                        expandedContent: DiaryActivityDetailsCard(
                          selectedDay: calendarState.selectedDay,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    KeyedSubtree(
                      key: _diaryScrollController.mealsSectionKey,
                      child: DiaryMealsSection(
                        selectedDay: calendarState.selectedDay,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom:
              MediaQuery.paddingOf(context).bottom +
              AppSpacing.xxxxl +
              AppSpacing.xs +
              (widget.includeHomeShellChrome
                  ? AppSizes.homeShellBottomBarClearance
                  : 0),
          child: Center(
            child: ListenableBuilder(
              listenable: _diaryScrollController,
              builder: (context, _) {
                return DiaryScrollShortcut(
                  showJumpToMeals:
                      !_diaryScrollController.isManualScrolling &&
                      _diaryScrollController.showJumpToMeals,
                  showScrollToTop:
                      !_diaryScrollController.isManualScrolling &&
                      _diaryScrollController.showScrollToTop,
                  onJumpToMeals: _diaryScrollController.scrollToMeals,
                  onScrollToTop: _diaryScrollController.scrollToTop,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _startDeferredDiarySubscriptions() {
    _weeklyCheckInSubscription ??= ref.listenManual(
      calorieWeeklyCheckInViewModelProvider,
      _cacheWeeklyCheckInView,
      fireImmediately: true,
    );
    _diaryIntroSubscription ??= ref.listenManual<DiaryIntroTrigger?>(
      diaryIntroTriggerProvider,
      _handleDiaryIntroTrigger,
      fireImmediately: true,
    );
  }

  void _cacheWeeklyCheckInView(
    AsyncValue<CalorieWeeklyCheckInViewModel>? previous,
    AsyncValue<CalorieWeeklyCheckInViewModel> next,
  ) {
    if (mounted) {
      setState(() {
        _weeklyCheckInState = next;
      });
    } else {
      _weeklyCheckInState = next;
    }
    final viewModel = next.value;
    if (viewModel == null) {
      return;
    }
    if (_hiddenWeeklyCheckInWindowKey != null &&
        viewModel.pendingWeeklyCheckIn?.windowKey !=
            _hiddenWeeklyCheckInWindowKey) {
      _hiddenWeeklyCheckInWindowKey = null;
    }
    final controller = ref.read(
      calorieWeeklyCheckInControllerProvider.notifier,
    );
    _weeklyCheckInDialogs.cacheAndSchedule(
      viewModel: viewModel,
      isMounted: () => mounted,
      syncLearnedTdeeCache: controller.syncLearnedTdeeCache,
      openDialog: _openWeeklyCheckInDialog,
    );
  }

  Future<void> _openWeeklyCheckInDialog(
    CalorieWeeklyCheckInViewModel viewModel,
  ) async {
    final pending = viewModel.pendingWeeklyCheckIn;
    if (!_weeklyCheckInDialogs.beginDialog(
      viewModel: viewModel,
      isMounted: () => mounted,
    )) {
      return;
    }

    final controller = ref.read(
      calorieWeeklyCheckInControllerProvider.notifier,
    );
    final resolvedPending = pending!;

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
          _hideWeeklyCheckInHint(resolvedPending);
          final saved = await controller.applyWeeklyCheckIn(viewModel);
          if (!mounted || saved) {
            return;
          }
          _showWeeklyCheckInHintAgain(resolvedPending);
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.caloriesWeeklyCheckInApplyFailed)),
          );
          return;
        case CalorieWeeklyCheckInDialogAction.openHealthTrends:
          await controller.dismissPendingWeeklyCheckIn(resolvedPending);
          if (!mounted) {
            return;
          }
          _openHealthTrendsPage(
            visibleWindowEnd: resolvedPending.windowEndDate,
          );
          return;
        case CalorieWeeklyCheckInDialogAction.later:
        case null:
          await controller.syncLearnedTdeeCache(viewModel);
          return;
      }
    } finally {
      _weeklyCheckInDialogs.endDialog(
        isMounted: () => mounted,
        openDialog: _openWeeklyCheckInDialog,
      );
    }
  }

  bool _isHiddenWeeklyCheckIn(CalorieWeeklyCheckInViewModel? viewModel) {
    final hiddenWindowKey = _hiddenWeeklyCheckInWindowKey;
    if (hiddenWindowKey == null) {
      return false;
    }
    return viewModel?.pendingWeeklyCheckIn?.windowKey == hiddenWindowKey;
  }

  void _hideWeeklyCheckInHint(
    PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  ) {
    if (_hiddenWeeklyCheckInWindowKey == pendingWeeklyCheckIn.windowKey) {
      return;
    }
    setState(() {
      _hiddenWeeklyCheckInWindowKey = pendingWeeklyCheckIn.windowKey;
    });
  }

  void _showWeeklyCheckInHintAgain(
    PendingCalorieGoalWeeklyCheckIn pendingWeeklyCheckIn,
  ) {
    if (_hiddenWeeklyCheckInWindowKey != pendingWeeklyCheckIn.windowKey) {
      return;
    }
    setState(() {
      _hiddenWeeklyCheckInWindowKey = null;
    });
  }

  Future<void> _toggleSkippedCalorieIntakeDay({
    required DateTime selectedDay,
    required bool isSkipped,
  }) async {
    final controller = ref.read(caloriePageActionControllerProvider.notifier);
    final saved = await controller.setSkippedIntakeDay(
      selectedDay: selectedDay,
      isSkipped: isSkipped,
    );
    if (!mounted || saved) {
      return;
    }
    showSkippedCalorieIntakeSaveFailedSnackBar(context);
  }

  void _handleDiaryIntroTrigger(
    DiaryIntroTrigger? previous,
    DiaryIntroTrigger? next,
  ) {
    if (_didQueueDiaryIntro || next == null) {
      return;
    }
    _didQueueDiaryIntro = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        _showDiaryIntro(
          next.preferences,
          next.introData,
          _resolveDiaryIntroHealthAction(next.healthStatus),
        ),
      );
    });
  }

  Future<void> _showDiaryIntro(
    AppPreferences preferences,
    DiaryIntroData introData,
    DiaryIntroHealthAction? healthAction,
  ) async {
    final completed = await showDiaryIntroDialog(
      context: context,
      data: introData,
      healthAction: healthAction,
    );
    if (!mounted || completed != true) {
      return;
    }
    await DiaryIntroPreferences.markSeen(preferences);
  }

  void _openDiaryIntroReplay({
    required CalorieGoalSettings goalSettings,
    required HealthConnectionStatus? healthStatus,
  }) {
    final introData = DiaryIntroData.fromSettings(goalSettings);
    final healthAction = _resolveDiaryIntroHealthAction(healthStatus);
    final preferences = ref.read(appPreferencesProvider);
    unawaited(_showDiaryIntro(preferences, introData, healthAction));
  }

  DiaryIntroHealthAction? _resolveDiaryIntroHealthAction(
    HealthConnectionStatus? status,
  ) {
    if (status == null) {
      return null;
    }
    final hasConnectionError = status.errorMessage != null;
    final needsAppPermissionSettings =
        status.errorMessage == healthActivityRecognitionPermissionErrorMessage;
    final controller = ref.read(healthConnectionControllerProvider.notifier);
    final action = switch (status.accessState) {
      HealthDataAccessState.permissionRequired ||
      HealthDataAccessState.historyRequired =>
        hasConnectionError
            ? needsAppPermissionSettings
                  ? controller.openAppPermissionSettings
                  : controller.openHealthPermissionSettings
            : controller.connect,
      HealthDataAccessState.installRequired => controller.installHealthConnect,
      HealthDataAccessState.ready || HealthDataAccessState.unsupported => null,
    };
    if (action == null) {
      return null;
    }
    return DiaryIntroHealthAction(
      accessState: status.accessState,
      hasConnectionError: hasConnectionError,
      onPressed: () => unawaited(action()),
    );
  }

  void _openHealthTrendsPage({DateTime? visibleWindowEnd}) {
    final resolvedWindowEnd = visibleWindowEnd ?? DateTime.now();
    ref
        .read(calorieHealthTrendsWindowControllerProvider.notifier)
        .setWindowEnd(resolvedWindowEnd);
    unawaited(context.push(AppRoutes.homeStatisticsWeight));
  }

  CalorieGoalHistoryEntry? _latestGoalHistoryEntry(
    CalorieGoalSettings? settings,
  ) {
    final history = settings?.sortedGoalHistory;
    if (history == null || history.isEmpty) {
      return null;
    }
    for (final entry in history.reversed) {
      if (entry.hasGoal) {
        return entry;
      }
    }
    return null;
  }
}
