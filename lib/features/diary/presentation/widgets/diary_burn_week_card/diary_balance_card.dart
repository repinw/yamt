import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_zone_dialog_host.dart';
import 'package:yamt/features/calories/provider/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loaded_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_loading.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_shell.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_card_helpers.dart';
import 'package:yamt/features/diary/provider/diary_entries_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Ticker period for minute-sensitive balance UI updates.
final diaryBalanceTickerPeriodProvider = Provider<Duration>(
  (ref) => diaryBalanceTickerPeriod,
);

/// Optional observer for balance ticker tests.
final diaryBalanceTickerObserverProvider = Provider<VoidCallback?>(
  (ref) => null,
);

/// Weekly calorie balance card for the diary page.
class DiaryBalanceCard extends ConsumerStatefulWidget {
  /// Creates the diary balance card.
  const DiaryBalanceCard({
    required this.selectedDay,
    required this.hasAutoOpeningWeeklyCheckIn,
    super.key,
  });

  /// The selected diary day.
  final DateTime selectedDay;

  /// Whether weekly check-in is about to open and should own dialogs.
  final bool hasAutoOpeningWeeklyCheckIn;

  @override
  ConsumerState<DiaryBalanceCard> createState() => _DiaryBalanceCardState();
}

class _DiaryBalanceCardState extends ConsumerState<DiaryBalanceCard>
    with
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin<DiaryBalanceCard>,
        BurnWeekZoneDialogHost<DiaryBalanceCard> {
  CalorieWeekOverview? _lastWeekOverview;
  Timer? _ticker;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTicker();
  }

  @override
  void didUpdateWidget(covariant DiaryBalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDiaryDay(oldWidget.selectedDay, widget.selectedDay)) {
      resetBurnWeekZoneDialogs();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTicker();
      if (mounted) {
        setState(() {});
      }
      return;
    }
    _stopTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    closeBurnWeekZoneDialog();
    _stopTicker();
    super.dispose();
  }

  @override
  bool get canShowBurnWeekZoneDialogs {
    return !widget.hasAutoOpeningWeeklyCheckIn &&
        _isLiveDay(widget.selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.watch(burnWeekLiveSyncProvider);

    final normalizedSelectedDay = normalizeDiaryDay(widget.selectedDay);
    final isLiveDay = _isLiveDay(widget.selectedDay);
    final weekOverviewState = ref.watch(
      calorieWeekOverviewForWindowProvider(normalizedSelectedDay),
    );
    final dayEntriesState = isLiveDay
        ? ref.watch(diaryEntriesForDayProvider(normalizedSelectedDay))
        : null;
    final dayEntries = dayEntriesState?.value ?? const <CalorieEntry>[];
    final dayEntriesLoaded = !isLiveDay || dayEntriesState?.hasValue == true;
    final runState =
        ref.watch(burnWeekRunControllerProvider).value ??
        const BurnWeekRunState.initial();
    final weekOverview = weekOverviewState.value;

    if (weekOverview != null) {
      final selectedDayOverview = weekOverview.days.last;
      _lastWeekOverview = weekOverview;

      return _buildLoaded(
        context,
        weekOverview: weekOverview,
        selectedDayOverview: selectedDayOverview,
        selectedDayEntries: dayEntries,
        selectedDayEntriesLoaded: dayEntriesLoaded,
        runState: runState,
        isLiveDay: isLiveDay,
      );
    }

    final lastWeekOverview = _lastWeekOverview;
    if (!weekOverviewState.hasError && lastWeekOverview != null) {
      return _buildLoaded(
        context,
        weekOverview: lastWeekOverview,
        selectedDayOverview: lastWeekOverview.days.last,
        selectedDayEntries: dayEntries,
        selectedDayEntriesLoaded: dayEntriesLoaded,
        runState: runState,
        isLiveDay: isLiveDay,
      );
    }

    final hasError =
        weekOverviewState.hasError || dayEntriesState?.hasError == true;
    if (hasError) {
      final l10n = AppLocalizations.of(context)!;
      return DiaryBalanceShell(
        child: DiaryErrorRetryContent(
          message: l10n.diaryBalanceLoadFailed,
          retryLabel: l10n.caloriesRetryAction,
          retryButtonKey: DiaryBalanceCardKeys.retryButton,
          onRetry: () => _retryBalance(normalizedSelectedDay),
        ),
      );
    }

    return const DiaryBalanceLoading();
  }

  void _retryBalance(DateTime normalizedSelectedDay) {
    ref
      ..invalidate(calorieWeekOverviewForWindowProvider(normalizedSelectedDay))
      ..invalidate(diaryEntriesForDayProvider(normalizedSelectedDay));
  }

  Widget _buildLoaded(
    BuildContext context, {
    required CalorieWeekOverview weekOverview,
    required CalorieWeekDayOverview selectedDayOverview,
    required List<CalorieEntry> selectedDayEntries,
    required bool selectedDayEntriesLoaded,
    required BurnWeekRunState runState,
    required bool isLiveDay,
  }) {
    return DiaryBalanceLoadedCard(
      weekOverview: weekOverview,
      selectedDayOverview: selectedDayOverview,
      selectedDayEntries: selectedDayEntries,
      selectedDayEntriesLoaded: selectedDayEntriesLoaded,
      runState: runState,
      isLiveDay: isLiveDay,
      hasAutoOpeningWeeklyCheckIn: widget.hasAutoOpeningWeeklyCheckIn,
      onQueueZoneDialog: queueBurnWeekZoneDialogIfNeeded,
      onShowUseHeartDialog: showBurnWeekZoneUseHeartDialog,
      onUnmarkHeartDay: _unmarkHeartDay,
    );
  }

  bool _isLiveDay(DateTime day) {
    return isSameDiaryDay(day, DateTime.now());
  }

  void _unmarkHeartDay(DateTime day) {
    unawaited(
      ref.read(burnWeekRunControllerProvider.notifier).unmarkHeartDay(day),
    );
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(ref.read(diaryBalanceTickerPeriodProvider), (_) {
      ref.read(diaryBalanceTickerObserverProvider)?.call();
      if (!mounted) {
        _stopTicker();
        return;
      }
      setState(() {});
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}
