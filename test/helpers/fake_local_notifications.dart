import 'dart:async';

import 'package:yamt/core/device/local_notifications.dart';

/// Keeps scheduled notifications in memory; [tap] plays a user's tap.
class FakeLocalNotifications implements LocalNotifications {
  /// Scheduled notifications by id.
  final scheduled = <int, ({DateTime at, String title, String payload})>{};

  /// How often the permission was requested.
  int permissionRequests = 0;

  final _taps = StreamController<String>.broadcast();

  /// Taps the notification with [payload].
  void tap(String payload) => _taps.add(payload);

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required NotificationChannel channel,
    required String title,
    required String body,
    required String payload,
  }) async => scheduled[id] = (at: at, title: title, payload: payload);

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);

  @override
  Future<List<int>> pendingIds() async => scheduled.keys.toList();

  @override
  Stream<String> get taps => _taps.stream;
}
