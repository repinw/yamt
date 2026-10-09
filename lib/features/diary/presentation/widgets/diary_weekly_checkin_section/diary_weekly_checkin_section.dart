import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/activity/presentation/diary_weight_tracking_flow.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_controller.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/pending_calorie_goal_weekly_check_in.dart';
import 'package:yamt/features/calories/presentation/widgets/calorie_new_goal_flow.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_weekly_checkin_dialog_scheduler.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_weekly_checkin_snackbars.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_section/diary_weekly_checkin_hint_host.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_section/diary_weekly_checkin_success_host.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_result.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Hosts diary weekly check-in cards and dialog orchestration.
class DiaryWeeklyCheckInSection extends ConsumerStatefulWidget {
  /// Creates diary weekly check-in section.
  const new({required this.selectedDay, super.key});

  /// Selected diary day.
  final DateTime selectedDay;

  @override
  ConsumerState<DiaryWeeklyCheckInSection> createState() =>
      _DiaryWeeklyCheckInSectionState();
}

class _DiaryWeeklyCheckInSectionState
    extends ConsumerState<DiaryWeeklyCheckInSection>
    with WidgetsBindingObserver {
  final DiaryWeeklyCheckInDialogScheduler _dialogs =
      DiaryWeeklyCheckInDialogScheduler();
  ProviderSubscription<AsyncValue<CalorieWeeklyCheckInData>>? _subscription;
  AsyncValue<CalorieWeeklyCheckInData> _state =
      const AsyncLoading<CalorieWeeklyCheckInData>();
  String? _hiddenWindowKey;
  String? _reopenWindowKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _startSubscription();
    });
  }

  @override
  void dispose() {
    _subscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    _dialogs.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    ref.invalidate(calorieWeeklyCheckInDataProvider);
  }

  @override
  Widget build(BuildContext context) {
    final rawCheckInData = _rawCheckInData;
    final checkInData = _visibleCheckInData;
    final dismissedPending = _dismissedPending(rawCheckInData);
    final weightTrackingFlow = ref.watch(diaryWeightTrackingFlowProvider);
    // Keeps the goal settings loaded for the reached-goal check and the
    // check-in controllers alive for the dialog callbacks.
    ref
      ..watch(calorieGoalControllerProvider)
      ..watch(calorieWeeklyCheckInControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (dismissedPending != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: DiaryWeeklyCheckInCardKeys.showAgainButton,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () => _showWeeklyCheckInAgain(dismissedPending),
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: Text(
                AppLocalizations.of(context)!
                    .caloriesWeeklyCheckInShowAgainAction,
              ),
            ),
          ),
        ],
        if (checkInData != null && checkInData.showDiaryHint) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          DiaryWeeklyCheckInHintHost(
            checkInData: checkInData,
            selectedDay: widget.selectedDay,
            onContinue: () => _openDialog(checkInData),
            onTrackMissingWeight: () {
              _trackMissingWeight(checkInData, weightTrackingFlow);
            },
            onToggleSelectedDaySkipped: _toggleSkippedCalorieIntakeDay,
          ),
        ],
        DiaryWeeklyCheckInSuccessHost(
          selectedDay: widget.selectedDay,
          onRedo: _showWeeklyCheckInAgain,
        ),
      ],
    );
  }

  // Read before any await, while the section is mounted.
  CalorieWeeklyCheckInController get _checkIn =>
      ref.read(calorieWeeklyCheckInControllerProvider.notifier);

  CalorieWeeklyCheckInData? get _rawCheckInData {
    return _state.value ?? _dialogs.lastCheckInData;
  }

  CalorieWeeklyCheckInData? get _visibleCheckInData {
    final rawCheckInData = _rawCheckInData;
    return _isHidden(rawCheckInData) ||
            _dismissedPending(rawCheckInData) != null
        ? null
        : rawCheckInData;
  }

  void _startSubscription() {
    if (!mounted) {
      return;
    }
    _subscription ??= ref.listenManual(
      calorieWeeklyCheckInDataProvider,
      _cacheCheckInData,
      fireImmediately: true,
    );
  }

  void _cacheCheckInData(
    AsyncValue<CalorieWeeklyCheckInData>? previous,
    AsyncValue<CalorieWeeklyCheckInData> next,
  ) {
    setState(() {
      _state = next;
      _clearStaleHiddenWindow(next.value);
    });

    final checkInData = next.value;
    if (checkInData == null) {
      return;
    }
    _dialogs.cacheAndSchedule(
      checkInData: checkInData,
      isMounted: () => mounted,
      syncLearnedTdeeCache: _syncLearnedTdeeCache,
      openDialog: _openDialog,
    );
    _openReopenedDialogIfReady(checkInData);
  }

  Future<void> _openDialog(CalorieWeeklyCheckInData checkInData) async {
    final pending = checkInData.pendingWeeklyCheckIn;
    if (!_dialogs.beginDialog(
      checkInData: checkInData,
      isMounted: () => mounted,
    )) {
      return;
    }

    final resolvedPending = pending!;

    try {
      final goalSettings = ref.read(calorieGoalControllerProvider).value;
      final result = await showDiaryWeeklyCheckInSheet(
        context,
        checkInData: checkInData,
        goalReached:
            goalSettings != null &&
            diaryActiveCalorieGoalWasReached(goalSettings, DateTime.now()),
      );
      if (!mounted) {
        return;
      }
      await _handleDialogAction(
        result: result,
        checkInData: checkInData,
        pending: resolvedPending,
      );
    } finally {
      _dialogs.endDialog(isMounted: () => mounted, openDialog: _openDialog);
    }
  }

  Future<void> _handleDialogAction({
    required DiaryWeeklyCheckInSheetResult? result,
    required CalorieWeeklyCheckInData checkInData,
    required PendingCalorieGoalWeeklyCheckIn pending,
  }) async {
    switch (result?.action) {
      case DiaryWeeklyCheckInSheetAction.apply ||
          DiaryWeeklyCheckInSheetAction.reject:
        await _decide(checkInData, pending, result!);
      case DiaryWeeklyCheckInSheetAction.trackMissingWeight:
        if (mounted) {
          _trackMissingWeight(
            checkInData,
            ref.read(diaryWeightTrackingFlowProvider),
          );
        }
      case DiaryWeeklyCheckInSheetAction.newGoal:
        await showCalorieNewGoalSheet(
          context,
          currentWeightKg: latestDiaryCheckInWeightKg(checkInData),
        );
      case DiaryWeeklyCheckInSheetAction.later:
      case null:
        await _syncLearnedTdeeCache(checkInData);
    }
  }

  /// Saves the training days of the next run and the TDEE decision.
  Future<void> _decide(
    CalorieWeeklyCheckInData checkInData,
    PendingCalorieGoalWeeklyCheckIn pending,
    DiaryWeeklyCheckInSheetResult result,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final apply = result.action == DiaryWeeklyCheckInSheetAction.apply;
    _hide(pending);
    final saved = apply
        ? await _checkIn.applyWeeklyCheckIn(
            checkInData,
            training: result.training,
          )
        : await _checkIn.rejectWeeklyCheckIn(
            checkInData,
            training: result.training,
          );
    if (!mounted) {
      return;
    }
    if (saved) {
      _refreshDashboard();
      return;
    }
    _showAgain(pending);
    ScaffoldMessenger.of(context).showAppSnackBar(
      apply
          ? l10n.caloriesWeeklyCheckInApplyFailed
          : l10n.caloriesWeeklyCheckInRejectFailed,
      tone: AppSnackBarTone.error,
    );
  }

  Future<void> _syncLearnedTdeeCache(
    CalorieWeeklyCheckInData checkInData,
  ) async {
    await _checkIn.syncLearnedTdeeCache(checkInData);
    if (!mounted) {
      return;
    }
    _refreshDashboard();
  }

  void _refreshDashboard() {
    final normalizedDay = normalizeDiaryDay(widget.selectedDay);
    ref.invalidate(diaryDayDashboardControllerProvider(normalizedDay));
  }

  void _hide(PendingCalorieGoalWeeklyCheckIn pending) {
    if (_hiddenWindowKey == pending.windowKey) {
      return;
    }
    setState(() {
      _hiddenWindowKey = pending.windowKey;
    });
  }

  void _showAgain(PendingCalorieGoalWeeklyCheckIn pending) {
    if (_hiddenWindowKey != pending.windowKey) {
      return;
    }
    setState(() {
      _hiddenWindowKey = null;
    });
  }

  Future<void> _showWeeklyCheckInAgain(
    PendingCalorieGoalWeeklyCheckIn pending,
  ) async {
    setState(() {
      _reopenWindowKey = pending.windowKey;
      _hiddenWindowKey = null;
    });
    final saved = await _checkIn.showPendingWeeklyCheckInAgain(pending);
    if (!mounted || saved) {
      return;
    }
    setState(() {
      _reopenWindowKey = null;
    });
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showAppSnackBar(
      l10n.caloriesWeeklyCheckInShowAgainFailed,
      tone: AppSnackBarTone.error,
    );
  }

  void _openReopenedDialogIfReady(CalorieWeeklyCheckInData checkInData) {
    final pending = checkInData.pendingWeeklyCheckIn;
    if (pending == null ||
        pending.isDismissed ||
        pending.windowKey != _reopenWindowKey) {
      return;
    }
    _reopenWindowKey = null;
    unawaited(_openDialog(checkInData));
  }

  Future<void> _toggleSkippedCalorieIntakeDay({
    required DateTime selectedDay,
    required bool isSkipped,
  }) async {
    final saved = await ref
        .read(calorieGoalControllerProvider.notifier)
        .setSkippedIntakeDay(day: selectedDay, isSkipped: isSkipped);
    if (!mounted || saved) {
      return;
    }
    showSkippedCalorieIntakeSaveFailedSnackBar(context);
  }

  void _trackMissingWeight(
    CalorieWeeklyCheckInData checkInData,
    DiaryWeightTrackingFlow weightTrackingFlow,
  ) {
    final day = checkInData.missingWeightDays.firstOrNull;
    if (day == null) {
      return;
    }

    ref.read(diaryCalendarControllerProvider.notifier).selectDay(day);
    final windowDay = _windowDayFor(checkInData, day);
    unawaited(
      weightTrackingFlow.showDialogForDay(
        context: context,
        selectedDay: day,
        day: day,
        initialWeightKg: windowDay?.weightKg,
      ),
    );
  }

  CalorieWeeklyCheckInWindowDay? _windowDayFor(
    CalorieWeeklyCheckInData checkInData,
    DateTime day,
  ) {
    for (final windowDay in checkInData.days) {
      if (DateUtils.isSameDay(windowDay.day, day)) {
        return windowDay;
      }
    }

    return null;
  }

  void _clearStaleHiddenWindow(CalorieWeeklyCheckInData? checkInData) {
    if (_hiddenWindowKey != null &&
        checkInData?.pendingWeeklyCheckIn?.windowKey != _hiddenWindowKey) {
      _hiddenWindowKey = null;
    }
  }

  bool _isHidden(CalorieWeeklyCheckInData? checkInData) {
    final hiddenWindowKey = _hiddenWindowKey;
    if (hiddenWindowKey == null) {
      return false;
    }
    return checkInData?.pendingWeeklyCheckIn?.windowKey == hiddenWindowKey;
  }

  PendingCalorieGoalWeeklyCheckIn? _dismissedPending(
    CalorieWeeklyCheckInData? checkInData,
  ) {
    final pending = checkInData?.pendingWeeklyCheckIn;
    return pending?.isDismissed == true ? pending : null;
  }
}
