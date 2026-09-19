import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/diary/application/diary_provider_warmup.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_home_shell_top_chrome.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_overlay.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_stage.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_macro_strip/diary_macro_strip_trigger.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_page_header.dart';
import 'package:yamt/features/health/application/'
    'health_connection_actions.dart';

/// Diary content.
class DiaryPage extends ConsumerStatefulWidget {
  /// The diary page.
  const new({super.key, this.includeHomeShellChrome = false});

  /// Key used by the shell and later design tests.
  static const pageKey = ValueKey<String>('diary-page');

  /// Whether to render the shared home shell app bar as a sliver.
  final bool includeHomeShellChrome;

  @override
  ConsumerState<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends ConsumerState<DiaryPage>
    with WidgetsBindingObserver {
  ProviderSubscription<void>? _providerWarmupSubscription;
  bool _didStartDeferredSubscriptions = false;
  final _macroStripAnchors = DiaryMacroStripAnchors();
  final ValueNotifier<DiaryMacroStripStage> _macroStripStage = ValueNotifier(
    DiaryMacroStripStage.hidden,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _providerWarmupSubscription?.close();
    _macroStripStage.dispose();
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

    return ColoredBox(
      color: colors.surface,
      child: CustomScrollView(
        key: DiaryPage.pageKey,
        scrollCacheExtent: const ScrollCacheExtent.pixels(0),
        slivers: [
          if (widget.includeHomeShellChrome)
            DiaryHomeShellTopChrome(
              overlay: DiaryMacroStripOverlay(
                selectedDay: calendarState.selectedDay,
                stage: _macroStripStage,
                kcalRowKey: _macroStripAnchors.stripKcalRow,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          if (widget.includeHomeShellChrome)
            DiaryMacroStripTrigger(
              anchors: _macroStripAnchors,
              stage: _macroStripStage,
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPagePadding,
              0,
              horizontalPagePadding,
              AppSpacing.xs,
            ),
            sliver: SliverToBoxAdapter(
              child: _NarrowContent(
                child: DiaryBalanceCard(
                  key: _macroStripAnchors.card,
                  kcalBarKey: _macroStripAnchors.kcalBar,
                  macroBarsKey: _macroStripAnchors.macroBars,
                  selectedDay: calendarState.selectedDay,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPagePadding,
              0,
              horizontalPagePadding,
              bottomPagePadding,
            ),
            sliver: SliverList.list(
              children: [
                DiaryPageHeader(
                  selectedDay: calendarState.selectedDay,
                  dashboardData: dashboardState.data,
                ),
                _NarrowContent(
                  child: DiaryMealsSection(
                    selectedDay: calendarState.selectedDay,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      _startProviderWarmup();
    });
  }

  void _startProviderWarmup() {
    _providerWarmupSubscription ??= ref.listenManual<void>(
      diaryProviderWarmupProvider,
      _keepDiaryProviderWarm,
      fireImmediately: true,
    );
  }

  void _keepDiaryProviderWarm<T>(T? previous, T next) {}
}

/// Centers page content at the narrow content width.
class _NarrowContent extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.narrowContentMaxWidth,
        ),
        // Fills the width up to the maximum instead of shrinking to fit.
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
