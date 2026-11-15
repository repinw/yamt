import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/household/application/household_data_scope.dart';
import 'package:yamt/features/kochmodus/application/cook_timer_alarms.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/cook_timer_alarm_controller.dart';
import 'package:yamt/features/recipes/application/cook_run_providers.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Wraps the app: keeps the notifications of the cook timers this device
/// started in line with the household's cook runs, and opens the run on a
/// tap. Wraps the app below its `ScaffoldMessenger`.
class CookTimerAlarmListener extends ConsumerStatefulWidget {
  /// Creates the listener around [child].
  const new({required this.child, super.key});

  /// The app.
  final Widget child;

  @override
  ConsumerState<CookTimerAlarmListener> createState() =>
      _CookTimerAlarmListenerState();
}

class _CookTimerAlarmListenerState
    extends ConsumerState<CookTimerAlarmListener> {
  late final GoRouter _router = ref.read(appRouterProvider);
  late final StreamSubscription<String> _taps;
  String? _pendingRunId;

  @override
  void initState() {
    super.initState();
    _router.routerDelegate.addListener(_openWhenHome);
    _taps = ref.read(localNotificationsProvider).taps.listen(
      (payload) {
        _pendingRunId = cookRunIdOfPayload(payload) ?? _pendingRunId;
        _openWhenHome();
      },
      onError: (Object error, StackTrace stackTrace) => log(
        'Reading notification taps failed.',
        name: 'CookTimerAlarmListener',
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_openWhenHome);
    unawaited(_taps.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Keeps the controller, and what it scheduled, as long as the app runs.
    ref.watch(cookTimerAlarmControllerProvider);
    ref.listen(cookRunsProvider, (_, next) {
      // A failed read keeps the scheduled notifications; the next change
      // syncs. Without the household key the runs read empty, which is no
      // reason to cancel them.
      if (ref.read(householdDataScopeProvider) == null) return;
      if (next case AsyncData(value: final runs)) {
        unawaited(
          ref.read(cookTimerAlarmControllerProvider.notifier).sync(runs, (
            channelName: l10n.kochmodusTimerChannelName,
            countdownChannelName: l10n.kochmodusTimerCountdownChannelName,
            title: l10n.kochmodusTimerAlarmTitle,
            body: (runName) => runName.isEmpty
                ? l10n.kochmodusTimerAlarmBodyFree
                : l10n.kochmodusTimerAlarmBody(runName),
            stopLabel: l10n.kochmodusTimerStop,
            countdownTitle: l10n.kochmodusTimerCountdownTitle,
          )),
        );
      }
    });
    return widget.child;
  }

  // A tap that launches the app arrives before sign-in is done.
  void _openWhenHome() {
    final path = _router.routerDelegate.currentConfiguration.uri.path;
    if (_pendingRunId == null || !path.startsWith(AppRoutes.home)) return;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        final runId = _pendingRunId;
        _pendingRunId = null;
        if (runId == null || !mounted) return;
        // Also stops the tap that iOS may hand over twice.
        final alarms = ref.read(cookTimerAlarmControllerProvider.notifier);
        if (alarms.isPageOpen(runId)) return;
        unawaited(_router.push<void>(AppRoutes.homeCookRunPath(runId)));
      })
      // A tap while the app shows and stands still needs a frame too.
      ..scheduleFrame();
  }
}
