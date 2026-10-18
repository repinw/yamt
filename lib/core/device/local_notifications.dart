import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

part 'local_notifications.g.dart';

/// An Android notification channel. Users can mute each channel in the
/// system settings, so every kind of reminder gets its own.
typedef NotificationChannel = ({String id, String name});

/// Shows notifications at a set time, also while the app is closed.
///
/// Features own their ids: each kind of reminder uses its own id range, so
/// one feature never cancels another's notifications.
abstract interface class LocalNotifications {
  /// Asks for the permission to show notifications; returns whether it is
  /// granted.
  Future<bool> requestPermission();

  /// Shows a notification at [at], or a few minutes later: Android may
  /// delay it to save battery. Replaces a notification with the same [id].
  Future<void> schedule({
    required int id,
    required DateTime at,
    required NotificationChannel channel,
    required String title,
    required String body,
    required String payload,
  });

  /// Removes the scheduled notification [id].
  Future<void> cancel(int id);

  /// Ids of the notifications that are scheduled and not shown yet.
  Future<List<int>> pendingIds();

  /// Payloads of the notifications the user taps, including the one that
  /// launched the app.
  Stream<String> get taps;
}

/// Android and iOS, through flutter_local_notifications.
class PluginLocalNotifications implements LocalNotifications {
  /// Creates the notifications; [plugin] is replaced in tests.
  new({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();
  late final Future<void> _ready = _initialize();
  bool _launchTapHandled = false;

  Future<void> _initialize() async {
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: darwin,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) _taps.add(payload);
      },
    );
  }

  @override
  Future<bool> requestPermission() async {
    await _ready;
    final granted = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission(),
      TargetPlatform.iOS =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true),
      _ => false,
    };
    return granted ?? false;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required NotificationChannel channel,
    required String title,
    required String body,
    required String payload,
  }) async {
    await _ready;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      // A fixed instant needs no time zone database: the local DateTime
      // already knows its offset, also across a clock change.
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(channel.id, channel.name),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _ready;
    await _plugin.cancel(id: id);
  }

  @override
  Future<List<int>> pendingIds() async {
    await _ready;
    final pending = await _plugin.pendingNotificationRequests();
    return [for (final request in pending) request.id];
  }

  @override
  Stream<String> get taps async* {
    await _ready;
    if (!_launchTapHandled) {
      _launchTapHandled = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if ((launch?.didNotificationLaunchApp ?? false) &&
          payload != null &&
          payload.isNotEmpty) {
        yield payload;
      }
    }
    yield* _taps.stream;
  }
}

/// Platforms without notifications: web, desktop, and tests.
class UnavailableLocalNotifications implements LocalNotifications {
  /// Creates the notifications.
  const new();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required NotificationChannel channel,
    required String title,
    required String body,
    required String payload,
  }) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<List<int>> pendingIds() async => const [];

  @override
  Stream<String> get taps => const Stream.empty();
}

/// Notifications of the current platform. Kept alive, so the tap stream
/// and the plugin are set up once.
@Riverpod(keepAlive: true)
LocalNotifications localNotifications(Ref ref) {
  return !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)
      ? PluginLocalNotifications()
      : const UnavailableLocalNotifications();
}
