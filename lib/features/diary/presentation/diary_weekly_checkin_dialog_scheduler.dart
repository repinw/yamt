import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';

/// Schedules work after the current frame.
typedef DiaryPostFrameScheduler = void Function(VoidCallback callback);

/// Coordinates auto-open and deferred weekly check-in dialog scheduling.
class DiaryWeeklyCheckInDialogScheduler {
  /// Creates a dialog scheduler.
  DiaryWeeklyCheckInDialogScheduler({
    DiaryPostFrameScheduler? schedulePostFrame,
  }) : _schedulePostFrame = schedulePostFrame ?? _defaultSchedulePostFrame;

  final DiaryPostFrameScheduler _schedulePostFrame;
  DiaryWeeklyCheckInData? _deferredCheckInData;
  String? _autoOpenedWindowKey;
  var _isDialogOpen = false;
  var _disposed = false;

  /// Last loaded weekly check-in data.
  DiaryWeeklyCheckInData? lastCheckInData;

  /// Whether a weekly check-in dialog is currently open.
  bool get isDialogOpen => _isDialogOpen;

  /// Caches the latest data and schedules auto-open work when needed.
  void cacheAndSchedule({
    required DiaryWeeklyCheckInData? checkInData,
    required bool Function() isMounted,
    required Future<void> Function(DiaryWeeklyCheckInData checkInData)
    syncLearnedTdeeCache,
    required Future<void> Function(DiaryWeeklyCheckInData checkInData)
    openDialog,
  }) {
    if (checkInData == null) {
      return;
    }

    lastCheckInData = checkInData;
    if (!_isDialogOpen) {
      unawaited(syncLearnedTdeeCache(checkInData));
    }
    schedule(
      checkInData: checkInData,
      isMounted: isMounted,
      openDialog: openDialog,
    );
  }

  /// Schedules an eligible weekly check-in dialog.
  void schedule({
    required DiaryWeeklyCheckInData? checkInData,
    required bool Function() isMounted,
    required Future<void> Function(DiaryWeeklyCheckInData checkInData)
    openDialog,
  }) {
    final pending = checkInData?.pendingWeeklyCheckIn;
    if (_disposed ||
        !isMounted() ||
        checkInData == null ||
        pending == null ||
        !checkInData.shouldAutoOpen) {
      return;
    }

    if (_autoOpenedWindowKey == pending.windowKey) {
      return;
    }
    if (_isDialogOpen) {
      _deferredCheckInData = checkInData;
      return;
    }
    _autoOpenedWindowKey = pending.windowKey;
    _schedulePostFrame(() {
      if (_disposed || !isMounted()) {
        return;
      }
      unawaited(openDialog(checkInData));
    });
  }

  /// Attempts to mark a weekly check-in dialog as opening.
  bool beginDialog({
    required DiaryWeeklyCheckInData checkInData,
    required bool Function() isMounted,
  }) {
    if (_disposed ||
        !isMounted() ||
        checkInData.pendingWeeklyCheckIn == null ||
        _isDialogOpen) {
      return false;
    }

    _isDialogOpen = true;
    return true;
  }

  /// Marks a weekly check-in dialog as closed and schedules deferred work.
  void endDialog({
    required bool Function() isMounted,
    required Future<void> Function(DiaryWeeklyCheckInData checkInData)
    openDialog,
  }) {
    _isDialogOpen = false;
    final deferredCheckInData = _deferredCheckInData;
    _deferredCheckInData = null;
    if (deferredCheckInData == null) {
      return;
    }
    schedule(
      checkInData: deferredCheckInData,
      isMounted: isMounted,
      openDialog: openDialog,
    );
  }

  /// Disposes pending scheduler work.
  void dispose() {
    _disposed = true;
    _deferredCheckInData = null;
  }

  static void _defaultSchedulePostFrame(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) => callback());
  }
}
