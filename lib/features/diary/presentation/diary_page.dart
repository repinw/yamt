import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/activity/presentation/widgets/activity_weight_section/diary_activity_weight_section.dart';
import 'package:yamt/features/calories/application/'
    'inventory_backed_calorie_entry_save_flow.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/diary/application/diary_intro_trigger_provider.dart';
import 'package:yamt/features/diary/application/diary_provider_warmup.dart';
import 'package:yamt/features/diary/application/'
    'diary_quick_eat_inventory_provider.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/domain/diary_intro_data.dart';
import 'package:yamt/features/diary/domain/diary_intro_preferences.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/diary_scroll_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_calendar_strip.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_intro_dialog.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_scroll_shortcut.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_section/diary_weekly_checkin_section.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/provider/health_connection_controller.dart';
import 'package:yamt/features/home/widgets/home_shell_chrome.dart'
    show HomeTabType;
import 'package:yamt/features/home/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/prepared_meals_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Diary content.
@Dependencies([
  diaryProviderWarmup,
  InventoryItemsController,
  PreparedMealsController,
  diaryQuickEatInventory,
  diaryQuickEatInventoryActions,
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

class _DiaryPageState extends ConsumerState<DiaryPage>
    with WidgetsBindingObserver {
  final DiaryScrollController _diaryScrollController = DiaryScrollController();
  ProviderSubscription<DiaryIntroTrigger?>? _diaryIntroSubscription;
  ProviderSubscription<void>? _providerWarmupSubscription;
  bool _didQueueDiaryIntro = false;

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
    _providerWarmupSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    _diaryScrollController.dispose();
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
    final calendarState = ref.watch(diaryCalendarControllerProvider);
    final calendarController = ref.read(
      diaryCalendarControllerProvider.notifier,
    );
    final goalSettings = ref.watch(diaryCalorieGoalSettingsProvider).value;
    final healthConnectionState = ref.watch(healthConnectionControllerProvider);
    final healthStatus = healthConnectionState.value;
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
                    DiaryWeeklyCheckInSection(
                      selectedDay: calendarState.selectedDay,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    DiaryActivityWeightSection(
                      selectedDay: calendarState.selectedDay,
                    ),
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
    _diaryIntroSubscription ??= ref.listenManual<DiaryIntroTrigger?>(
      diaryIntroTriggerProvider,
      _handleDiaryIntroTrigger,
      fireImmediately: true,
    );
    _providerWarmupSubscription ??= ref.listenManual<void>(
      diaryProviderWarmupProvider,
      _keepDiaryProviderWarm,
      fireImmediately: true,
    );
  }

  void _keepDiaryProviderWarm<T>(T? previous, T next) {}

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
}
