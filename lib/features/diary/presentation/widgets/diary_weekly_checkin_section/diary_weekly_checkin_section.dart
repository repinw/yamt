import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/calorie_page_actions.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_health_trends_window_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_page_action_controller.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_controller.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_weekly_checkin_dialog_scheduler.dart';
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
    required this.onAutoOpeningChanged,
    super.key,
  });

  /// Selected diary day.
  final DateTime selectedDay;

  /// Reports whether weekly check-in should suppress other auto dialogs.
  final ValueChanged<bool> onAutoOpeningChanged;

  @override
  ConsumerState<DiaryWeeklyCheckInSection> createState() =>
      _DiaryWeeklyCheckInSectionState();
}

class _DiaryWeeklyCheckInSectionState
    extends ConsumerState<DiaryWeeklyCheckInSection>
    with WidgetsBindingObserver {
  final DiaryWeeklyCheckInDialogScheduler _dialogs =
      DiaryWeeklyCheckInDialogScheduler();
  ProviderSubscription<AsyncValue<CalorieWeeklyCheckInViewModel>>?
  _subscription;
  AsyncValue<CalorieWeeklyCheckInViewModel> _state =
      const AsyncLoading<CalorieWeeklyCheckInViewModel>();
  String? _hiddenWindowKey;
  bool? _lastAutoOpening;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startSubscription();
      }
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
    ref.invalidate(calorieWeeklyCheckInViewModelProvider);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _visibleViewModel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (viewModel != null && viewModel.showDiaryHint) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          DiaryWeeklyCheckInHintHost(
            viewModel: viewModel,
            selectedDay: widget.selectedDay,
            onContinue: () => _openDialog(viewModel),
            onOpenHealthTrends: () {
              _openHealthTrendsPage(
                visibleWindowEnd: viewModel.pendingWeeklyCheckIn?.windowEndDate,
              );
            },
            onToggleSelectedDaySkipped: _toggleSkippedCalorieIntakeDay,
          ),
        ],
        const DiaryWeeklyCheckInSuccessHost(),
      ],
    );
  }

  CalorieWeeklyCheckInViewModel? get _visibleViewModel {
    final rawViewModel = _state.value ?? _dialogs.lastViewModel;
    return _isHidden(rawViewModel) ? null : rawViewModel;
  }

  void _startSubscription() {
    _subscription ??= ref.listenManual(
      calorieWeeklyCheckInViewModelProvider,
      _cacheViewModel,
      fireImmediately: true,
    );
  }

  void _cacheViewModel(
    AsyncValue<CalorieWeeklyCheckInViewModel>? previous,
    AsyncValue<CalorieWeeklyCheckInViewModel> next,
  ) {
    setState(() {
      _state = next;
      _clearStaleHiddenWindow(next.value);
    });
    _syncAutoOpening();

    final viewModel = next.value;
    if (viewModel == null) {
      return;
    }
    final controller = ref.read(
      calorieWeeklyCheckInControllerProvider.notifier,
    );
    _dialogs.cacheAndSchedule(
      viewModel: viewModel,
      isMounted: () => mounted,
      syncLearnedTdeeCache: controller.syncLearnedTdeeCache,
      openDialog: _openDialog,
    );
  }

  Future<void> _openDialog(CalorieWeeklyCheckInViewModel viewModel) async {
    final pending = viewModel.pendingWeeklyCheckIn;
    if (!_dialogs.beginDialog(viewModel: viewModel, isMounted: () => mounted)) {
      return;
    }

    final controller = ref.read(
      calorieWeeklyCheckInControllerProvider.notifier,
    );
    final resolvedPending = pending!;

    try {
      final action = await showDiaryWeeklyCheckInDialog(
        context,
        viewModel: viewModel,
      );
      if (!mounted) {
        return;
      }
      await _handleDialogAction(
        action: action,
        controller: controller,
        viewModel: viewModel,
        pending: resolvedPending,
      );
    } finally {
      _dialogs.endDialog(isMounted: () => mounted, openDialog: _openDialog);
    }
  }

  Future<void> _handleDialogAction({
    required DiaryWeeklyCheckInDialogAction? action,
    required CalorieWeeklyCheckInController controller,
    required CalorieWeeklyCheckInViewModel viewModel,
    required PendingCalorieGoalWeeklyCheckIn pending,
  }) async {
    switch (action) {
      case DiaryWeeklyCheckInDialogAction.apply:
        await _applyWeeklyCheckIn(controller, viewModel, pending);
      case DiaryWeeklyCheckInDialogAction.openHealthTrends:
        await controller.dismissPendingWeeklyCheckIn(pending);
        if (mounted) {
          _openHealthTrendsPage(visibleWindowEnd: pending.windowEndDate);
        }
      case DiaryWeeklyCheckInDialogAction.later:
      case null:
        await controller.syncLearnedTdeeCache(viewModel);
    }
  }

  Future<void> _applyWeeklyCheckIn(
    CalorieWeeklyCheckInController controller,
    CalorieWeeklyCheckInViewModel viewModel,
    PendingCalorieGoalWeeklyCheckIn pending,
  ) async {
    _hide(pending);
    final saved = await controller.applyWeeklyCheckIn(viewModel);
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
    _syncAutoOpening();
  }

  void _showAgain(PendingCalorieGoalWeeklyCheckIn pending) {
    if (_hiddenWindowKey != pending.windowKey) {
      return;
    }
    setState(() {
      _hiddenWindowKey = null;
    });
    _syncAutoOpening();
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

  void _openHealthTrendsPage({DateTime? visibleWindowEnd}) {
    final resolvedWindowEnd = visibleWindowEnd ?? DateTime.now();
    ref
        .read(calorieHealthTrendsWindowControllerProvider.notifier)
        .setWindowEnd(resolvedWindowEnd);
    unawaited(context.push(AppRoutes.homeStatisticsWeight));
  }

  void _clearStaleHiddenWindow(CalorieWeeklyCheckInViewModel? viewModel) {
    if (_hiddenWindowKey != null &&
        viewModel?.pendingWeeklyCheckIn?.windowKey != _hiddenWindowKey) {
      _hiddenWindowKey = null;
    }
  }

  bool _isHidden(CalorieWeeklyCheckInViewModel? viewModel) {
    final hiddenWindowKey = _hiddenWindowKey;
    if (hiddenWindowKey == null) {
      return false;
    }
    return viewModel?.pendingWeeklyCheckIn?.windowKey == hiddenWindowKey;
  }

  void _syncAutoOpening() {
    final viewModel = _visibleViewModel;
    final next =
        _state.isLoading ||
        (viewModel?.pendingWeeklyCheckIn != null &&
            viewModel?.shouldAutoOpen == true);
    if (_lastAutoOpening == next) {
      return;
    }
    _lastAutoOpening = next;
    widget.onAutoOpeningChanged(next);
  }
}
