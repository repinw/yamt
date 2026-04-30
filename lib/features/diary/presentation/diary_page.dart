import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/calories/application/'
    'calorie_debug_dump_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_weekly_checkin_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_weekly_checkin_hint_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_health_trends_window_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/domain/diary_intro_preferences.dart';
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
import 'package:yamt/features/diary/presentation/widgets/diary_steps_card.dart';
import 'package:yamt/features/diary/provider/diary_calendar_controller.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/diary_health_service_provider.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/health/provider/health_weight_service_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_repository_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

final _diaryIntroTriggerProvider = Provider.autoDispose<_DiaryIntroTrigger?>((
  ref,
) {
  final weeklyCheckInState = ref.watch(calorieWeeklyCheckInViewModelProvider);
  final weeklyCheckIn = weeklyCheckInState.asData?.value;
  final hasAutoOpeningWeeklyCheckIn =
      weeklyCheckInState.isLoading ||
      (weeklyCheckIn?.pendingWeeklyCheckIn != null &&
          weeklyCheckIn?.shouldAutoOpen == true);
  if (hasAutoOpeningWeeklyCheckIn) {
    return null;
  }

  final settings = ref.watch(calorieGoalControllerProvider).asData?.value;
  final healthConnectionState = ref.watch(healthConnectionControllerProvider);
  if (settings == null || healthConnectionState.isLoading) {
    return null;
  }
  if (settings.hasLearnedTdee || !DiaryIntroData.canBuildFrom(settings)) {
    return null;
  }

  final preferences = ref.watch(appPreferencesProvider);
  if (DiaryIntroPreferences.isSeen(preferences)) {
    return null;
  }

  return _DiaryIntroTrigger(
    preferences: preferences,
    introData: DiaryIntroData.fromSettings(settings),
    healthStatus: healthConnectionState.asData?.value,
  );
});

@immutable
class _DiaryIntroTrigger {
  const _DiaryIntroTrigger({
    required this.preferences,
    required this.introData,
    required this.healthStatus,
  });

  final AppPreferences preferences;
  final DiaryIntroData introData;
  final HealthConnectionStatus? healthStatus;
}

/// Diary content.
class DiaryPage extends ConsumerStatefulWidget {
  /// The diary page.
  const DiaryPage({super.key});

  /// Key used by the shell and later design tests.
  static const pageKey = ValueKey<String>('diary-page');

  @override
  ConsumerState<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends ConsumerState<DiaryPage>
    with WidgetsBindingObserver {
  final DiaryScrollController _diaryScrollController = DiaryScrollController();
  final DiaryWeeklyCheckInDialogScheduler _weeklyCheckInDialogs =
      DiaryWeeklyCheckInDialogScheduler();
  ProviderSubscription<_DiaryIntroTrigger?>? _diaryIntroSubscription;
  bool _didQueueDiaryIntro = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _diaryIntroSubscription = ref.listenManual<_DiaryIntroTrigger?>(
      _diaryIntroTriggerProvider,
      _handleDiaryIntroTrigger,
      fireImmediately: true,
    );
    _diaryScrollController.addListener(_refreshScrollActions);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _diaryScrollController
      ..removeListener(_refreshScrollActions)
      ..dispose();
    _diaryIntroSubscription?.close();
    _weeklyCheckInDialogs.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    ref.read(diaryCalendarControllerProvider.notifier).refreshToday();
    ref.invalidate(healthConnectionControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      calorieWeeklyCheckInViewModelProvider,
      _cacheWeeklyCheckInView,
    );

    final calendarState = ref.watch(diaryCalendarControllerProvider);
    final calendarController = ref.read(
      diaryCalendarControllerProvider.notifier,
    );
    final selectedDayOverview = ref
        .watch(calorieWeekDayOverviewForDateProvider(calendarState.selectedDay))
        .asData
        ?.value;
    final weeklyCheckInState = ref.watch(calorieWeeklyCheckInViewModelProvider);
    final weeklyCheckIn =
        weeklyCheckInState.asData?.value ?? _weeklyCheckInDialogs.lastViewModel;
    final hasAutoOpeningWeeklyCheckIn =
        weeklyCheckInState.isLoading ||
        (weeklyCheckIn?.pendingWeeklyCheckIn != null &&
            weeklyCheckIn?.shouldAutoOpen == true);
    final goalSettings = ref.watch(calorieGoalControllerProvider).asData?.value;
    final latestGoalHistoryEntry = _latestGoalHistoryEntry(goalSettings);
    final referenceNow = DateTime.now();
    final showWeeklySuccessCard =
        latestGoalHistoryEntry?.isWeeklyCheckIn == true &&
        DateUtils.isSameDay(
          latestGoalHistoryEntry?.effectiveDate,
          referenceNow,
        );
    final healthConnectionState = ref.watch(healthConnectionControllerProvider);
    final healthStatus = healthConnectionState.asData?.value;
    final showActivityTrackingWidgets =
        healthStatus?.accessState == HealthDataAccessState.ready;
    final runState = ref.watch(burnWeekRunControllerProvider).asData?.value;
    final showIntroReplayButton =
        runState?.runWeekNumber == burnWeekLearningRunWeekNumber &&
        goalSettings != null &&
        !goalSettings.hasLearnedTdee &&
        DiaryIntroData.canBuildFrom(goalSettings);

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _diaryScrollController.handleScrollNotification,
          child: ListView(
            key: DiaryPage.pageKey,
            controller: _diaryScrollController.scrollController,
            padding: responsivePagePadding(
              context,
              top: AppSpacing.lg,
              bottom: homeShellPageBottomPadding(context),
            ),
            children: [
              DiaryCalendarStrip(
                today: calendarState.today,
                selectedDay: calendarState.selectedDay,
                todayRequest: calendarState.todayRequest,
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
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: Text(
                      AppLocalizations.of(context)!.diaryIntroReplayAction,
                    ),
                  ),
                ),
              ],
              if (weeklyCheckIn != null && weeklyCheckIn.showDiaryHint) ...[
                const SizedBox(height: AppSpacing.md),
                CalorieWeeklyCheckInHintCard(
                  viewModel: weeklyCheckIn,
                  selectedDay: calendarState.selectedDay,
                  selectedDayHasEntries:
                      (selectedDayOverview?.entryCount ?? 0) > 0,
                  onContinue: () => _openWeeklyCheckInDialog(weeklyCheckIn),
                  onOpenHealthTrends: () => _openHealthTrendsPage(
                    visibleWindowEnd:
                        weeklyCheckIn.pendingWeeklyCheckIn?.windowEndDate,
                  ),
                  onToggleSelectedDaySkipped: ({required isSkipped}) {
                    return _toggleSkippedSelectedDay(
                      selectedDay: calendarState.selectedDay,
                      isSkipped: isSkipped,
                    );
                  },
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
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton.tonalIcon(
                  key: CaloriesPageKeys.calorieDebugDumpButton,
                  onPressed: () => unawaited(_printCalorieDebugDump()),
                  icon: const Icon(Icons.table_chart_rounded),
                  label: Text(
                    AppLocalizations.of(context)!.caloriesDebugDumpAction,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              DiaryNutritionBars(selectedDay: calendarState.selectedDay),
              const SizedBox(height: AppSpacing.xl),
              DiaryActivityWeightCards(selectedDay: calendarState.selectedDay),
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
        Positioned(
          left: 0,
          right: 0,
          bottom:
              MediaQuery.paddingOf(context).bottom +
              AppSpacing.xxxxl +
              AppSpacing.xs,
          child: Center(
            child: _DiaryScrollShortcut(
              showJumpToMeals:
                  !_diaryScrollController.isManualScrolling &&
                  _diaryScrollController.showJumpToMeals,
              showScrollToTop:
                  !_diaryScrollController.isManualScrolling &&
                  _diaryScrollController.showScrollToTop,
              onJumpToMeals: _diaryScrollController.scrollToMeals,
              onScrollToTop: _diaryScrollController.scrollToTop,
            ),
          ),
        ),
      ],
    );
  }

  void _cacheWeeklyCheckInView(
    AsyncValue<CalorieWeeklyCheckInViewModel>? previous,
    AsyncValue<CalorieWeeklyCheckInViewModel> next,
  ) {
    final viewModel = next.asData?.value;
    if (viewModel == null) {
      return;
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
      await controller.syncPendingWeeklyCheckIn(resolvedPending);
      if (!mounted) {
        return;
      }

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

  void _refreshScrollActions() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _handleDiaryIntroTrigger(
    _DiaryIntroTrigger? previous,
    _DiaryIntroTrigger? next,
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

  Future<void> _printCalorieDebugDump() async {
    final l10n = AppLocalizations.of(context)!;
    final calorieLogRepository = ref.read(calorieLogRepositoryProvider);
    final diaryHealthService = ref.read(diaryHealthServiceProvider);
    final healthWeightService = ref.read(healthWeightServiceProvider);
    final manualWeightRepository = ref.read(
      manualHealthWeightRepositoryProvider,
    );
    final healthStatusFuture = ref.read(
      healthConnectionControllerProvider.future,
    );
    final settingsFuture = ref.read(calorieGoalControllerProvider.future);

    try {
      final result = await buildCalorieDebugDump(
        calorieLogRepository: calorieLogRepository,
        diaryHealthService: diaryHealthService,
        healthWeightService: healthWeightService,
        manualWeightRepository: manualWeightRepository,
        healthStatusFuture: healthStatusFuture,
        settingsFuture: settingsFuture,
        now: DateTime.now(),
      );
      developer.log(
        'Calorie debug dump\n${result.table}',
        name: 'CalorieDebugDump',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.caloriesDebugDumpPrinted(result.rowCount)),
          ),
        );
    } on Object catch (error, stackTrace) {
      developer.log(
        'Failed to build calorie debug dump.',
        name: 'CalorieDebugDump',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.caloriesDebugDumpFailed)),
        );
    }
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

class _DiaryScrollShortcut extends StatefulWidget {
  const _DiaryScrollShortcut({
    required this.showJumpToMeals,
    required this.showScrollToTop,
    required this.onJumpToMeals,
    required this.onScrollToTop,
  });

  final bool showJumpToMeals;
  final bool showScrollToTop;
  final VoidCallback onJumpToMeals;
  final VoidCallback onScrollToTop;

  @override
  State<_DiaryScrollShortcut> createState() => _DiaryScrollShortcutState();
}

class _DiaryScrollShortcutState extends State<_DiaryScrollShortcut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late bool _showScrollToTopContent;

  @override
  void initState() {
    super.initState();
    _showScrollToTopContent = widget.showScrollToTop;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    unawaited(_pulseController.repeat(reverse: true));
  }

  @override
  void didUpdateWidget(covariant _DiaryScrollShortcut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showJumpToMeals || widget.showScrollToTop) {
      _showScrollToTopContent = widget.showScrollToTop;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showButton = widget.showJumpToMeals || widget.showScrollToTop;
    final icon = _showScrollToTopContent
        ? Icons.keyboard_arrow_up_rounded
        : Icons.keyboard_arrow_down_rounded;
    final label = _showScrollToTopContent
        ? l10n.diaryScrollToTopAction
        : l10n.diaryJumpToMealsAction;
    final onPressed = _showScrollToTopContent
        ? widget.onScrollToTop
        : widget.onJumpToMeals;

    return AnimatedScale(
      scale: showButton ? 1 : 0.82,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: showButton ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: IgnorePointer(
          ignoring: !showButton,
          child: AnimatedBuilder(
            animation: _pulseController,
            child: _DiaryScrollShortcutButton(
              icon: icon,
              label: label,
              onPressed: onPressed,
            ),
            builder: (context, child) {
              final pulse = Curves.easeInOut.transform(_pulseController.value);
              return Transform.translate(
                offset: Offset(0, _showScrollToTopContent ? 0 : pulse * 2),
                child: Transform.scale(
                  scale: _showScrollToTopContent ? 1 : 1 + pulse * 0.025,
                  child: Opacity(
                    opacity: _showScrollToTopContent ? 1 : 0.82 + pulse * 0.18,
                    child: child,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DiaryScrollShortcutButton extends StatelessWidget {
  const _DiaryScrollShortcutButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(icon, color: colors.primary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
