import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';

/// Schedules work after the current frame.
typedef DiaryPostFrameScheduler = void Function(VoidCallback callback);

/// Coordinates auto-open and deferred weekly check-in dialog scheduling.
class DiaryWeeklyCheckInDialogScheduler {
  /// Creates a dialog scheduler.
  DiaryWeeklyCheckInDialogScheduler({
    DiaryPostFrameScheduler? schedulePostFrame,
  }) : _schedulePostFrame = schedulePostFrame ?? _defaultSchedulePostFrame;

  final DiaryPostFrameScheduler _schedulePostFrame;
  CalorieWeeklyCheckInViewModel? _deferredViewModel;
  String? _autoOpenedWindowKey;
  var _isDialogOpen = false;
  var _disposed = false;

  /// Last loaded weekly check-in view model.
  CalorieWeeklyCheckInViewModel? lastViewModel;

  /// Whether a weekly check-in dialog is currently open.
  bool get isDialogOpen => _isDialogOpen;

  /// Caches the latest view model and schedules auto-open work when needed.
  void cacheAndSchedule({
    required CalorieWeeklyCheckInViewModel? viewModel,
    required bool Function() isMounted,
    required Future<void> Function(CalorieWeeklyCheckInViewModel viewModel)
    syncLearnedTdeeCache,
    required Future<void> Function(CalorieWeeklyCheckInViewModel viewModel)
    openDialog,
  }) {
    if (viewModel == null) {
      return;
    }

    lastViewModel = viewModel;
    final pending = viewModel.pendingWeeklyCheckIn;
    final willAutoOpen =
        pending != null &&
        viewModel.shouldAutoOpen &&
        _autoOpenedWindowKey != pending.windowKey;
    if (!willAutoOpen && !_isDialogOpen) {
      unawaited(syncLearnedTdeeCache(viewModel));
    }
    schedule(
      viewModel: viewModel,
      isMounted: isMounted,
      openDialog: openDialog,
    );
  }

  /// Schedules an eligible weekly check-in dialog.
  void schedule({
    required CalorieWeeklyCheckInViewModel? viewModel,
    required bool Function() isMounted,
    required Future<void> Function(CalorieWeeklyCheckInViewModel viewModel)
    openDialog,
  }) {
    final pending = viewModel?.pendingWeeklyCheckIn;
    if (_disposed ||
        !isMounted() ||
        viewModel == null ||
        pending == null ||
        !viewModel.shouldAutoOpen) {
      return;
    }

    if (_autoOpenedWindowKey == pending.windowKey) {
      return;
    }
    if (_isDialogOpen) {
      _deferredViewModel = viewModel;
      return;
    }
    _autoOpenedWindowKey = pending.windowKey;
    _schedulePostFrame(() {
      if (_disposed || !isMounted()) {
        return;
      }
      unawaited(openDialog(viewModel));
    });
  }

  /// Attempts to mark a weekly check-in dialog as opening.
  bool beginDialog({
    required CalorieWeeklyCheckInViewModel viewModel,
    required bool Function() isMounted,
  }) {
    if (_disposed ||
        !isMounted() ||
        viewModel.pendingWeeklyCheckIn == null ||
        _isDialogOpen) {
      return false;
    }

    _isDialogOpen = true;
    return true;
  }

  /// Marks a weekly check-in dialog as closed and schedules deferred work.
  void endDialog({
    required bool Function() isMounted,
    required Future<void> Function(CalorieWeeklyCheckInViewModel viewModel)
    openDialog,
  }) {
    _isDialogOpen = false;
    final deferredViewModel = _deferredViewModel;
    _deferredViewModel = null;
    if (deferredViewModel == null) {
      return;
    }
    schedule(
      viewModel: deferredViewModel,
      isMounted: isMounted,
      openDialog: openDialog,
    );
  }

  /// Disposes pending scheduler work.
  void dispose() {
    _disposed = true;
    _deferredViewModel = null;
  }

  static void _defaultSchedulePostFrame(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) => callback());
  }
}
