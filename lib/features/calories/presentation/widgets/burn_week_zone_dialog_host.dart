import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/burn_week_mock_logic.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'burn_week_live_overview_dialogs.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shared host behavior for live Burn Week zone dialogs.
mixin BurnWeekZoneDialogHost<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  NavigatorState? _zoneDialogNavigator;
  Route<void>? _zoneDialogRoute;
  var _zoneDialogEpoch = 0;
  var _isZoneDialogOpen = false;
  BurnWeekZoneStatus _lastZoneStatus = BurnWeekZoneStatus.inside;

  /// Last remembered zone status, exposed for focused host tests.
  @visibleForTesting
  BurnWeekZoneStatus get debugLastZoneStatus => _lastZoneStatus;

  /// Whether this host can currently show zone dialogs.
  bool get canShowBurnWeekZoneDialogs;

  /// Invalidates queued zone-dialog work and closes any remembered dialog.
  void invalidateBurnWeekZoneDialogs() {
    _zoneDialogEpoch += 1;
    closeBurnWeekZoneDialog();
  }

  /// Resets zone-dialog memory and closes any open zone dialog.
  void resetBurnWeekZoneDialogs() {
    invalidateBurnWeekZoneDialogs();
    _lastZoneStatus = BurnWeekZoneStatus.inside;
    closeBurnWeekZoneDialog();
  }

  /// Closes the currently remembered zone dialog, if one exists.
  void closeBurnWeekZoneDialog() {
    final navigator = _zoneDialogNavigator;
    final route = _zoneDialogRoute;
    if (navigator == null || route == null) {
      return;
    }
    if (!route.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_zoneDialogNavigator != navigator || _zoneDialogRoute != route) {
          return;
        }
        if (!route.isActive) {
          return;
        }
        navigator.removeRoute(route);
        _zoneDialogNavigator = null;
        _zoneDialogRoute = null;
      });
      return;
    }
    navigator.removeRoute(route);
    _zoneDialogNavigator = null;
    _zoneDialogRoute = null;
  }

  /// Queues an out-of-zone dialog after the current frame.
  void queueBurnWeekZoneDialogIfNeeded({
    required BurnWeekMockMetrics metrics,
    required BurnWeekRunState runState,
    bool Function()? shouldSkip,
  }) {
    final expectedEpoch = _zoneDialogEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shouldSkip?.call() ?? false) {
        return;
      }
      if (!_canShowZoneDialogs(expectedEpoch)) {
        return;
      }
      unawaited(
        _maybeShowZoneDialog(
          metrics: metrics,
          runState: runState,
          expectedEpoch: expectedEpoch,
          shouldSkip: shouldSkip,
        ),
      );
    });
  }

  /// Shows the manual heart action dialog when the run has hearts left.
  Future<void> showBurnWeekZoneUseHeartDialog({
    required double dailyGoalKcal,
    required BurnWeekRunState runState,
  }) async {
    if (runState.heartCount <= 0) {
      return;
    }

    final controller = ref.read(burnWeekRunControllerProvider.notifier);
    final action = await showBurnWeekUseHeartDialog(
      context: context,
      dayKcal: dailyGoalKcal.round(),
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case BurnWeekLiveHeartAction.add:
        await controller.usePositiveHeart(dailyGoalKcal);
      case BurnWeekLiveHeartAction.remove:
        await controller.useNegativeHeart(dailyGoalKcal);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _lastZoneStatus = BurnWeekZoneStatus.inside;
    });
  }

  Future<void> _maybeShowZoneDialog({
    required BurnWeekMockMetrics metrics,
    required BurnWeekRunState runState,
    required int expectedEpoch,
    bool Function()? shouldSkip,
  }) async {
    if (shouldSkip?.call() ?? false) {
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    if (shouldSkip?.call() ?? false) {
      return;
    }
    if (!_canShowZoneDialogs(expectedEpoch)) {
      return;
    }

    final zoneDecision = resolveBurnWeekZoneDecision(metrics);
    if (zoneDecision.status == BurnWeekZoneStatus.inside) {
      _lastZoneStatus = BurnWeekZoneStatus.inside;
      return;
    }
    if (_isZoneDialogOpen || zoneDecision.status == _lastZoneStatus) {
      return;
    }

    _lastZoneStatus = zoneDecision.status;
    _isZoneDialogOpen = true;
    switch (zoneDecision.status) {
      case BurnWeekZoneStatus.below:
        await _showBelowZoneDialog(
          metrics: metrics,
          runState: runState,
          decision: zoneDecision,
        );
      case BurnWeekZoneStatus.above:
        await _showAboveZoneDialog(
          metrics: metrics,
          runState: runState,
          decision: zoneDecision,
        );
      case BurnWeekZoneStatus.inside:
        break;
    }
    _zoneDialogNavigator = null;
    _zoneDialogRoute = null;
    _isZoneDialogOpen = false;
  }

  bool _canShowZoneDialogs(int expectedEpoch) {
    if (!mounted ||
        expectedEpoch != _zoneDialogEpoch ||
        !canShowBurnWeekZoneDialogs) {
      return false;
    }
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return false;
    }
    return true;
  }

  void _rememberZoneDialogRoute(NavigatorState navigator, Route<void> route) {
    _zoneDialogNavigator = navigator;
    _zoneDialogRoute = route;
    if (!_canRememberZoneDialogRoute()) {
      closeBurnWeekZoneDialog();
    }
  }

  bool _canRememberZoneDialogRoute() {
    return mounted && canShowBurnWeekZoneDialogs;
  }

  Future<void> _showBelowZoneDialog({
    required BurnWeekMockMetrics metrics,
    required BurnWeekRunState runState,
    required BurnWeekZoneDecision decision,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(burnWeekRunControllerProvider.notifier);
    if (decision.type == BurnWeekZoneDecisionType.belowNeedsHeart) {
      if (runState.heartCount <= 0) {
        await _showRunOverDialog(
          message: l10n.burnWeekZoneBelowRunOverMessage,
        );
        return;
      }
      final shouldUseHeart = await showBurnWeekBelowNeedsHeartDialog(
        context,
        onRouteReady: _rememberZoneDialogRoute,
      );
      if (shouldUseHeart == true && mounted) {
        await controller.usePositiveHeart(metrics.dailyGoalKcal);
        _markZoneInside();
      }
      return;
    }

    final action = await showBurnWeekBelowRecoverDialog(
      context: context,
      hasHearts: runState.heartCount > 0,
      onRouteReady: _rememberZoneDialogRoute,
    );
    if (!mounted) {
      return;
    }
    if (action == BurnWeekLiveBelowZoneAction.useHeart) {
      await controller.usePositiveHeart(metrics.dailyGoalKcal);
      _markZoneInside();
      return;
    }
    await showBurnWeekSimpleDialog(
      context: context,
      title: l10n.burnWeekZoneEatMoreTitle,
      message: l10n.burnWeekZoneEatMoreMessage,
      onRouteReady: _rememberZoneDialogRoute,
    );
  }

  Future<void> _showAboveZoneDialog({
    required BurnWeekMockMetrics metrics,
    required BurnWeekRunState runState,
    required BurnWeekZoneDecision decision,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(burnWeekRunControllerProvider.notifier);
    if (decision.type == BurnWeekZoneDecisionType.aboveFastOnly) {
      await showBurnWeekSimpleDialog(
        context: context,
        title: l10n.burnWeekZoneOutOfSafeZoneTitle,
        message: l10n.burnWeekZoneAboveFastMessage,
        onRouteReady: _rememberZoneDialogRoute,
      );
      return;
    }
    if (runState.heartCount <= 0) {
      await _showRunOverDialog(message: l10n.burnWeekZoneAboveRunOverMessage);
      return;
    }
    final shouldUseHeart = await showBurnWeekAboveNeedsHeartDialog(
      context,
      onRouteReady: _rememberZoneDialogRoute,
    );
    if (shouldUseHeart == true && mounted) {
      await controller.useNegativeHeart(metrics.dailyGoalKcal);
      _markZoneInside();
    }
  }

  Future<void> _showRunOverDialog({required String message}) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(burnWeekRunControllerProvider.notifier);
    await showBurnWeekSimpleDialog(
      context: context,
      title: l10n.burnWeekRunOverTitle,
      message: message,
      onRouteReady: _rememberZoneDialogRoute,
    );
    if (!mounted) {
      return;
    }
    await controller.restartRunFrom(
      weekStartDate: nextDiaryDay(DateTime.now()),
    );
  }

  void _markZoneInside() {
    if (!mounted) {
      return;
    }
    setState(() {
      _lastZoneStatus = BurnWeekZoneStatus.inside;
    });
  }
}
