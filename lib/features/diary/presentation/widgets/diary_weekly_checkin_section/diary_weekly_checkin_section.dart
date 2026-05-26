import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/activity/presentation/diary_weight_tracking_flow.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_weekly_checkin_dialog_scheduler.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_weekly_checkin_snackbars.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_dialog/diary_weekly_checkin_dialog.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_section/diary_weekly_checkin_hint_host.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_section/diary_weekly_checkin_success_host.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Hosts diary weekly check-in cards and dialog orchestration.
class DiaryWeeklyCheckInSection extends ConsumerStatefulWidget {
  /// Creates diary weekly check-in section.
  const DiaryWeeklyCheckInSection({
    required this.selectedDay,
    super.key,
  });

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
  ProviderSubscription<AsyncValue<DiaryWeeklyCheckInData>>? _subscription;
  AsyncValue<DiaryWeeklyCheckInData> _state =
      const AsyncLoading<DiaryWeeklyCheckInData>();
  String? _hiddenWindowKey;

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
    ref.read(diaryWeeklyCheckInActionsProvider).refreshCheckInData();
  }

  @override
  Widget build(BuildContext context) {
    final checkInData = _visibleCheckInData;
    final weightTrackingFlow = ref.watch(diaryWeightTrackingFlowProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
        const DiaryWeeklyCheckInSuccessHost(),
      ],
    );
  }

  DiaryWeeklyCheckInData? get _visibleCheckInData {
    final rawCheckInData = _state.value ?? _dialogs.lastCheckInData;
    return _isHidden(rawCheckInData) ? null : rawCheckInData;
  }

  void _startSubscription() {
    if (!mounted) {
      return;
    }
    _subscription ??= ref.listenManual(
      diaryWeeklyCheckInDataProvider,
      _cacheCheckInData,
      fireImmediately: true,
    );
  }

  void _cacheCheckInData(
    AsyncValue<DiaryWeeklyCheckInData>? previous,
    AsyncValue<DiaryWeeklyCheckInData> next,
  ) {
    setState(() {
      _state = next;
      _clearStaleHiddenWindow(next.value);
    });

    final checkInData = next.value;
    if (checkInData == null) {
      return;
    }
    final actions = ref.read(diaryWeeklyCheckInActionsProvider);
    _dialogs.cacheAndSchedule(
      checkInData: checkInData,
      isMounted: () => mounted,
      syncLearnedTdeeCache: actions.syncLearnedTdeeCache,
      openDialog: _openDialog,
    );
  }

  Future<void> _openDialog(DiaryWeeklyCheckInData checkInData) async {
    final pending = checkInData.pendingWeeklyCheckIn;
    if (!_dialogs.beginDialog(
      checkInData: checkInData,
      isMounted: () => mounted,
    )) {
      return;
    }

    final actions = ref.read(diaryWeeklyCheckInActionsProvider);
    final resolvedPending = pending!;

    try {
      final action = await showDiaryWeeklyCheckInDialog(
        context,
        checkInData: checkInData,
      );
      if (!mounted) {
        return;
      }
      await _handleDialogAction(
        action: action,
        actions: actions,
        checkInData: checkInData,
        pending: resolvedPending,
      );
    } finally {
      _dialogs.endDialog(isMounted: () => mounted, openDialog: _openDialog);
    }
  }

  Future<void> _handleDialogAction({
    required DiaryWeeklyCheckInDialogAction? action,
    required DiaryWeeklyCheckInActions actions,
    required DiaryWeeklyCheckInData checkInData,
    required PendingCalorieGoalWeeklyCheckIn pending,
  }) async {
    switch (action) {
      case DiaryWeeklyCheckInDialogAction.apply:
        await _applyWeeklyCheckIn(actions, checkInData, pending);
      case DiaryWeeklyCheckInDialogAction.trackMissingWeight:
        if (mounted) {
          _trackMissingWeight(
            checkInData,
            ref.read(diaryWeightTrackingFlowProvider),
          );
        }
      case DiaryWeeklyCheckInDialogAction.later:
      case null:
        await actions.syncLearnedTdeeCache(checkInData);
    }
  }

  Future<void> _applyWeeklyCheckIn(
    DiaryWeeklyCheckInActions actions,
    DiaryWeeklyCheckInData checkInData,
    PendingCalorieGoalWeeklyCheckIn pending,
  ) async {
    _hide(pending);
    final saved = await actions.applyWeeklyCheckIn(checkInData);
    if (!mounted || saved) {
      return;
    }
    _showAgain(pending);
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.caloriesWeeklyCheckInApplyFailed)),
    );
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

  Future<void> _toggleSkippedCalorieIntakeDay({
    required DateTime selectedDay,
    required bool isSkipped,
  }) async {
    final actions = ref.read(diaryWeeklyCheckInActionsProvider);
    final saved = await actions.setSkippedIntakeDay(
      selectedDay: selectedDay,
      isSkipped: isSkipped,
    );
    if (!mounted || saved) {
      return;
    }
    showSkippedCalorieIntakeSaveFailedSnackBar(context);
  }

  void _trackMissingWeight(
    DiaryWeeklyCheckInData checkInData,
    DiaryWeightTrackingFlow weightTrackingFlow,
  ) {
    final day = _firstMissingWeightDay(checkInData);
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

  DateTime? _firstMissingWeightDay(DiaryWeeklyCheckInData checkInData) {
    return checkInData.missingWeightDays.isEmpty
        ? null
        : checkInData.missingWeightDays.first;
  }

  CalorieWeeklyCheckInWindowDay? _windowDayFor(
    DiaryWeeklyCheckInData checkInData,
    DateTime day,
  ) {
    for (final windowDay in checkInData.days) {
      if (DateUtils.isSameDay(windowDay.day, day)) {
        return windowDay;
      }
    }

    return null;
  }

  void _clearStaleHiddenWindow(DiaryWeeklyCheckInData? checkInData) {
    if (_hiddenWindowKey != null &&
        checkInData?.pendingWeeklyCheckIn?.windowKey != _hiddenWindowKey) {
      _hiddenWindowKey = null;
    }
  }

  bool _isHidden(DiaryWeeklyCheckInData? checkInData) {
    final hiddenWindowKey = _hiddenWindowKey;
    if (hiddenWindowKey == null) {
      return false;
    }
    return checkInData?.pendingWeeklyCheckIn?.windowKey == hiddenWindowKey;
  }
}
