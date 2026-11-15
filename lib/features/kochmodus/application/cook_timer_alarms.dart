import 'package:yamt/features/recipes/domain/cook_run.dart';

/// Notification ids of cook timers: this base plus a stable hash of the
/// timer id below 100000000, so every timer keeps one id on every start
/// of the app.
const cookTimerNotificationIdBase = 200000000;

const _idRange = 100000000;

const _payloadPrefix = 'cook-run:';

/// The notification of a running cook timer. The view words it from the
/// timer's `label` and the run's `runName`.
typedef CookTimerAlarm = ({
  int id,
  DateTime at,
  String label,
  String runName,
  String payload,
});

/// What the device must change to ring exactly its running cook timers.
typedef CookTimerAlarmChanges = ({
  List<CookTimerAlarm> schedule,
  List<int> cancel,
});

/// The notification id of the cook timer [timerId].
int cookTimerNotificationId(String timerId) {
  // FNV-1a, because String.hashCode may differ between app starts.
  var hash = 0x811c9dc5;
  for (final unit in timerId.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return cookTimerNotificationIdBase + hash % _idRange;
}

/// Whether [id] belongs to a cook timer.
bool isCookTimerNotificationId(int id) =>
    id >= cookTimerNotificationIdBase &&
    id < cookTimerNotificationIdBase + _idRange;

/// The tap payload of a timer of the run [runId].
String cookTimerPayload(String runId) => '$_payloadPrefix$runId';

/// The run a tap [payload] names; `null` for other notifications.
String? cookRunIdOfPayload(String payload) => payload.startsWith(_payloadPrefix)
    ? payload.substring(_payloadPrefix.length)
    : null;

/// Lines up the notifications of the device [deviceId] with the timers of
/// [runs]: only the timers this device started ring here.
///
/// [pendingIds] are the notifications scheduled and not shown yet,
/// [activeIds] the ones that show in the tray and may be ringing, [scheduled]
/// the ring times this device scheduled before, by id. A timer that ends
/// after [now] is scheduled when it is not pending or its time changed
/// ("+1 Min"). A cook notification without its timer (stopped, or the run
/// ended) is cancelled, so one that rang stops ringing and leaves the tray,
/// also after a restart of the app. A rung timer that is scheduled again is
/// cancelled first, because scheduling leaves a notification that shows. A
/// timer whose time passed is not scheduled again, because it rings or rang
/// already.
CookTimerAlarmChanges reconcileCookTimerAlarms({
  required List<CookRun> runs,
  required String deviceId,
  required Iterable<int> pendingIds,
  required Iterable<int> activeIds,
  required Map<int, DateTime> scheduled,
  required DateTime now,
}) {
  final pending = pendingIds.where(isCookTimerNotificationId).toSet();
  final active = activeIds.where(isCookTimerNotificationId).toSet();
  final alarms = [
    for (final run in runs)
      for (final timer in run.timers)
        if (timer.deviceId == deviceId)
          (
            id: cookTimerNotificationId(timer.id),
            at: timer.endsAt,
            label: timer.label,
            runName: run.name,
            payload: cookTimerPayload(run.id),
          ),
  ];
  final wanted = {for (final alarm in alarms) alarm.id};
  final schedule = [
    for (final alarm in alarms)
      if (alarm.at.isAfter(now) &&
          (!pending.contains(alarm.id) || scheduled[alarm.id] != alarm.at))
        alarm,
  ];
  return (
    schedule: schedule,
    cancel: [
      for (final id in {...pending, ...active, ...scheduled.keys})
        if (isCookTimerNotificationId(id) && !wanted.contains(id)) id,
      for (final alarm in schedule)
        if (active.contains(alarm.id)) alarm.id,
    ],
  );
}
