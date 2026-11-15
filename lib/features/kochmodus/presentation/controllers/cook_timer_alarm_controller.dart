import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/utils/log_failure.dart';
import 'package:yamt/features/kochmodus/application/cook_run_start_service.dart';
import 'package:yamt/features/kochmodus/application/cook_timer_alarms.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';

part 'cook_timer_alarm_controller.g.dart';

const _logName = 'CookTimerAlarmController';
const _permissionsAskedKey = 'cook_timer_permissions_asked_v2';
const _setValue = 'set';

/// The Android notification channel of the cook timers, which ring like an
/// alarm clock.
const cookTimerChannelId = 'cook_timer_alarm';

/// The Android notification channel of the silent countdown to a running
/// cook timer.
const cookTimerCountdownChannelId = 'cook_timer_countdown';

/// The localized texts of a cook timer notification: the names of the
/// alarm and the countdown channel, the title from the timer's label, the
/// text from the run's name, and the label of the button that stops it.
typedef CookTimerAlarmTexts = ({
  String channelName,
  String countdownChannelName,
  String Function(String label) title,
  String Function(String runName) body,
  String stopLabel,
  String Function(String label) countdownTitle,
});

/// Keeps the notifications of the cook timers this device started in line
/// with the household's cook runs. When the cooking page first opens on this
/// device ([askPermissions]), or else with the first timer it rings, it asks
/// once for the notification permission and, when Android does not allow
/// exact alarms yet, for those.
@riverpod
class CookTimerAlarmController extends _$CookTimerAlarmController {
  @override
  void build() {}

  // The ring times scheduled so far, by notification id: "+1 Min" changes
  // the time of a pending notification.
  final _scheduled = <int, DateTime>{};
  String? _deviceId;
  Future<void> _syncs = Future.value();
  // The runs whose cooking page is open, so a tap never opens one twice.
  final _openRuns = <String>{};
  Future<void>? _asking;

  /// The cooking page of the run [runId] opened.
  void pageOpened(String runId) => _openRuns.add(runId);

  /// The cooking page of the run [runId] closed.
  void pageClosed(String runId) => _openRuns.remove(runId);

  /// Whether a cooking page of the run [runId] is open.
  bool isPageOpen(String runId) => _openRuns.contains(runId);

  /// Opens the system settings of the app's notifications, so timers can
  /// ring; [cookTimerNotificationsBlocked] checks again when the app
  /// returns.
  Future<void> openNotificationSettings() async {
    await _logged(ref.read(localNotificationsProvider).openSettings);
  }

  /// Asks once per device, at the start of cooking, for what the timers need
  /// to ring: notifications and, on Android, exact alarms, which the alarm
  /// clock needs to ring on time. Nothing after the system answered once.
  Future<void> askPermissions() =>
      _askPermissionsOnce(ref.read(localNotificationsProvider));

  /// Opens the system screen that allows exact alarms, then checks again
  /// whether timers ring on time.
  Future<void> allowExactAlarms() async {
    await _logged(ref.read(localNotificationsProvider).requestExactAlarms);
    if (ref.mounted) ref.invalidate(cookTimerExactAllowedProvider);
  }

  /// Schedules the running timers of [runs] that this device started and
  /// cancels the notifications whose timer is gone. Calls run one after the
  /// other, so an older list never lands after a newer one.
  Future<void> sync(List<CookRun> runs, CookTimerAlarmTexts texts) {
    final next = _syncs.then((_) => _sync(runs, texts));
    // A failed sync must not stop the ones after it.
    return _syncs = next.catchError((Object error, StackTrace stackTrace) {
      logFailure(
        'Syncing the cook timer notifications failed.',
        _logName,
        error,
        stackTrace,
      );
    });
  }

  Future<void> _sync(List<CookRun> runs, CookTimerAlarmTexts texts) async {
    if (!ref.mounted) return;
    final notifications = ref.read(localNotificationsProvider);
    final deviceId = _deviceId ??= await ref
        .read(cookRunStartServiceProvider)
        .deviceId();
    final pending = await notifications.pendingIds();
    // Without a look at the tray the timers still ring.
    final active = await _logged(notifications.activeIds) ?? const [];
    if (!ref.mounted) return;
    final changes = reconcileCookTimerAlarms(
      runs: runs,
      deviceId: deviceId,
      pendingIds: pending,
      activeIds: active,
      scheduled: _scheduled,
      now: ref.read(clockProvider)(),
    );
    // Each call on its own, so one failure leaves the others in place; the
    // next change of the runs tries again.
    for (final id in changes.cancel) {
      if (await _succeeded(() => notifications.cancel(id))) {
        _scheduled.remove(id);
      }
    }
    if (changes.schedule.isEmpty) return;
    await _askPermissionsOnce(notifications);
    if (!ref.mounted) return;
    // Without exact alarms, Android may ring a few minutes late.
    final exact = await _logged(notifications.canScheduleExact) ?? false;
    for (final alarm in changes.schedule) {
      final scheduled = await _succeeded(
        () => notifications.schedule(
          id: alarm.id,
          at: alarm.at,
          channel: (id: cookTimerChannelId, name: texts.channelName),
          title: texts.title(alarm.label),
          body: texts.body(alarm.runName),
          payload: alarm.payload,
          exact: exact,
          alarm: (
            stopLabel: texts.stopLabel,
            countdown: (
              id: cookTimerCountdownChannelId,
              name: texts.countdownChannelName,
            ),
            countdownTitle: texts.countdownTitle(alarm.label),
          ),
        ),
      );
      if (scheduled) _scheduled[alarm.id] = alarm.at;
    }
  }

  // One request at a time: two pages may ask at once.
  Future<void> _askPermissionsOnce(LocalNotifications notifications) =>
      _asking ??= _askPermissions(notifications)
          .whenComplete(() => _asking = null);

  // Asked counts only once the system answered, so a failed request asks
  // again with the next timer.
  Future<void> _askPermissions(LocalNotifications notifications) async {
    final preferences = ref.read(appPreferencesProvider);
    if (preferences.getStringSync(_permissionsAskedKey) == _setValue) return;
    final granted = await _logged(notifications.requestPermission);
    if (granted == null) return;
    if (granted && !(await _logged(notifications.canScheduleExact) ?? true)) {
      await _logged(notifications.requestExactAlarms);
      if (ref.mounted) ref.invalidate(cookTimerExactAllowedProvider);
    }
    await preferences.setString(_permissionsAskedKey, _setValue);
    if (ref.mounted) ref.invalidate(cookTimerNotificationsBlockedProvider);
  }

  Future<bool> _succeeded(Future<void> Function() call) async =>
      await _logged(() async {
        await call();
        return true;
      }) ??
      false;

  Future<T?> _logged<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error, stackTrace) {
      logFailure('A notification call failed.', _logName, error, stackTrace);
      return null;
    }
  }
}

/// Whether cook timers ring on time: Android allows exact alarms ("Alarms &
/// reminders"); always on iOS. Checks again whenever the app returns to the
/// foreground, since the user may change it in the system settings.
@riverpod
Future<bool> cookTimerExactAllowed(Ref ref) {
  final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(lifecycle.dispose);
  return ref.watch(localNotificationsProvider).canScheduleExact();
}

/// Whether the system blocks the cook timer notifications: they are off or
/// their channel is muted. Only once this device asked for the permission,
/// since the system has no answer before; false while it checks and when
/// the check fails, so no hint shows then.
@riverpod
bool cookTimerNotificationsBlocked(Ref ref) {
  final preferences = ref.watch(appPreferencesProvider);
  if (preferences.getStringSync(_permissionsAskedKey) != _setValue) {
    return false;
  }
  final allowed = ref.watch(
    localNotificationsAllowedProvider(cookTimerChannelId),
  );
  return !allowed.hasError && allowed.value == false;
}
