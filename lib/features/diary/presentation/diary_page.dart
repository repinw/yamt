import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/diary/application/diary_intro_trigger_provider.dart';
import 'package:yamt/features/diary/application/diary_provider_warmup.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/domain/diary_intro_data.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_intro_banner_dismissal_controller.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/diary_page_intro_coordinator.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_food_log_feedback/diary_food_log_feedback_host.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_home_shell_top_chrome.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_page_header.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_page_meals_content.dart';
import 'package:yamt/features/health/application/'
    'health_connection_actions.dart';

/// Diary content.
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
  ProviderSubscription<DiaryIntroTrigger?>? _diaryIntroSubscription;
  ProviderSubscription<void>? _providerWarmupSubscription;
  bool _didQueueDiaryIntro = false;
  bool _didStartDeferredSubscriptions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _diaryIntroSubscription?.close();
    _providerWarmupSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    ref.read(diaryCalendarControllerProvider.notifier).refreshToday();
    ref.invalidate(healthConnectionStatusProvider);
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPagePadding = responsivePageHorizontalPadding(context);
    final bottomPagePadding = homeShellPageBottomPadding(context);
    final colors = Theme.of(context).colorScheme;
    final calendarState = ref.watch(diaryCalendarControllerProvider);
    final dashboardState = ref.watch(
      diaryDayDashboardControllerProvider(calendarState.selectedDay),
    );
    if (dashboardState.data != null) {
      _queueDeferredDiarySubscriptions();
    }
    final goalSettings = dashboardState.data == null
        ? null
        : ref.watch(diaryCalorieGoalSettingsProvider).value;
    final runState = dashboardState.data?.runState;
    final isIntroBannerDismissed = ref.watch(
      diaryIntroBannerDismissalControllerProvider,
    );
    final showIntroBanner =
        !isIntroBannerDismissed &&
        runState?.runWeekNumber == burnWeekLearningRunWeekNumber &&
        goalSettings != null &&
        !goalSettings.hasLearnedTdee &&
        DiaryIntroData.canBuildFrom(goalSettings);

    return DiaryFoodLogFeedbackHost(
      child: ColoredBox(
        color: colors.surface,
        child: CustomScrollView(
          key: DiaryPage.pageKey,
          cacheExtent: 0,
          slivers: [
            if (widget.includeHomeShellChrome) const DiaryHomeShellTopChrome(),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPagePadding,
                AppSpacing.md,
                horizontalPagePadding,
                0,
              ),
              sliver: SliverList.list(
                children: [
                  DiaryPageHeader(
                    selectedDay: calendarState.selectedDay,
                    dashboardData: dashboardState.data,
                    showIntroBanner: showIntroBanner,
                    onOpenIntro: () {
                      final introData = DiaryIntroData.fromSettings(
                        goalSettings!,
                      );
                      final healthStatus = ref
                          .read(healthConnectionStatusProvider)
                          .value;
                      unawaited(
                        runDiaryIntroFlow(
                          context: context,
                          ref: ref,
                          introData: introData,
                          healthStatus: healthStatus,
                        ),
                      );
                    },
                    onDismissIntro: () {
                      final notifier = ref.read(
                        diaryIntroBannerDismissalControllerProvider.notifier,
                      );
                      unawaited(notifier.dismiss());
                    },
                  ),
                ],
              ),
            ),
            buildDiaryPageMealsContent(
              selectedDay: calendarState.selectedDay,
              horizontalPadding: horizontalPagePadding,
              bottomPadding: bottomPagePadding,
            ),
          ],
        ),
      ),
    );
  }

  void _queueDeferredDiarySubscriptions() {
    if (_didStartDeferredSubscriptions) {
      return;
    }
    _didStartDeferredSubscriptions = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _startDeferredDiarySubscriptions();
    });
  }

  void _startDeferredDiarySubscriptions() {
    _diaryIntroSubscription ??= ref.listenManual<DiaryIntroTrigger?>(
      diaryIntroTriggerProvider,
      _handleDiaryIntroTrigger,
      fireImmediately: true,
    );
    _startProviderWarmup();
  }

  void _startProviderWarmup() {
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
        runDiaryIntroFlow(
          context: context,
          ref: ref,
          introData: next.introData,
          healthStatus: next.healthStatus,
        ),
      );
    });
  }
}
