import 'dart:async';

import 'package:yamt/core/device/local_notifications.dart';

/// Keeps scheduled notifications in memory; [tap] plays a user's tap.
class FakeLocalNotifications implements LocalNotifications {
  /// Scheduled notifications by id.
  final scheduled = <int, ({DateTime at, String title, String payload})>{};

  /// How often the permission was requested.
  int permissionRequests = 0;

  /// Whether the system allows notifications.
  bool allowed = true;

  /// Whether the user grants a permission request.
  bool grants = true;

  /// How often the system settings were opened.
  int settingsOpened = 0;

  /// Whether the system settings can open; when not, [openSettings]
  /// throws.
  bool canOpenSettings = true;

  /// Ids scheduled as exact alarms.
  final exactIds = <int>{};

  /// Ids scheduled as alarms, which ring like an alarm clock.
  final alarmIds = <int>{};

  /// The channel each scheduled id was scheduled on.
  final channelIds = <int, String>{};

  /// How each alarm id was scheduled to ring.
  final alarmStyles = <int, AlarmStyle>{};

  /// Ids that show in the tray, as a ringing notification does; tests add
  /// them by hand, [cancel] removes them.
  final active = <int>{};

  /// Whether reading the tray throws.
  bool activeFails = false;

  /// Whether the system allows exact alarms.
  bool exactAllowed = true;

  /// Whether the user allows exact alarms when asked.
  bool grantsExact = true;

  /// How often exact alarms were requested.
  int exactRequests = 0;

  final _taps = StreamController<String>.broadcast();

  /// Taps the notification with [payload].
  void tap(String payload) => _taps.add(payload);

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    if (grants) allowed = true;
    return grants;
  }

  @override
  Future<bool> areAllowed(String channelId) async => allowed;

  @override
  Future<void> openSettings() async {
    if (!canOpenSettings) throw StateError('No settings screen opened.');
    settingsOpened++;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required NotificationChannel channel,
    required String title,
    required String body,
    required String payload,
    bool exact = false,
    AlarmStyle? alarm,
  }) async {
    scheduled[id] = (at: at, title: title, payload: payload);
    channelIds[id] = channel.id;
    if (alarm != null) {
      alarmIds.add(id);
      alarmStyles[id] = alarm;
    } else {
      alarmIds.remove(id);
      alarmStyles.remove(id);
    }
    if (exact) {
      exactIds.add(id);
    } else {
      exactIds.remove(id);
    }
  }

  @override
  Future<bool> canScheduleExact() async => exactAllowed;

  @override
  Future<bool> requestExactAlarms() async {
    exactRequests++;
    if (grantsExact) exactAllowed = true;
    return exactAllowed;
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
    exactIds.remove(id);
    alarmIds.remove(id);
    alarmStyles.remove(id);
    channelIds.remove(id);
    active.remove(id);
  }

  @override
  Future<List<int>> pendingIds() async => scheduled.keys.toList();

  @override
  Future<List<int>> activeIds() async {
    if (activeFails) throw StateError('The tray cannot be read.');
    return active.toList();
  }

  @override
  Stream<String> get taps => _taps.stream;
}
