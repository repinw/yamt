import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/device/plugin_local_notifications.dart';

part 'local_notifications.g.dart';

/// An Android notification channel. Users can mute each channel in the
/// system settings, so every kind of reminder gets its own.
typedef NotificationChannel = ({String id, String name});

/// How long an alarm notification rings at most when nobody stops it.
const alarmRingLimit = Duration(minutes: 10);

/// What an alarm needs besides its notification: the label of the button
/// that stops it ringing, and on Android the channel and the title of the
/// silent notification that counts down to it.
typedef AlarmStyle = ({
  String stopLabel,
  NotificationChannel countdown,
  String countdownTitle,
});

/// Shows notifications at a set time, also while the app is closed.
///
/// Features own their ids: each kind of reminder uses its own id range, so
/// one feature never cancels another's notifications.
abstract interface class LocalNotifications {
  /// Asks for the permission to show notifications; returns whether it is
  /// granted.
  Future<bool> requestPermission();

  /// Whether the system lets the app show notifications on [channelId]:
  /// the app's switch and, on Android, the channel's own. True when the
  /// platform cannot tell.
  Future<bool> areAllowed(String channelId);

  /// Opens the system settings of the app's notifications. Throws when no
  /// settings screen opens.
  Future<void> openSettings();

  /// Shows a notification at [at]. Android may delay it a few minutes to
  /// save battery, unless [exact] and exact alarms are allowed. Replaces a
  /// scheduled notification with the same [id]; one that already shows stays
  /// until [cancel] removes it or the new one rings.
  ///
  /// With [alarm] it rings like an alarm clock. On Android the system's
  /// alarm clock arms it and the app plays the device's alarm tone on the
  /// alarm stream itself, so it also sounds on a phone set to vibrate or
  /// silent and while a watch mutes the app's notifications; it rings until
  /// the stop button, [cancel] or [alarmRingLimit]. Until then a silent
  /// notification on the alarm's countdown channel counts down to it. On
  /// iOS it sounds with the app open too, but not on a muted iPhone. Android
  /// freezes a channel's settings when it first rings, so one [channel]
  /// takes either alarms or other notifications, never both.
  Future<void> schedule({
    required int id,
    required DateTime at,
    required NotificationChannel channel,
    required String title,
    required String body,
    required String payload,
    bool exact = false,
    AlarmStyle? alarm,
  });

  /// Whether [schedule] can show an exact notification on time. On Android
  /// the user allows this as "Alarms & reminders".
  Future<bool> canScheduleExact();

  /// Opens the system screen that allows exact alarms; returns whether they
  /// are allowed afterwards.
  Future<bool> requestExactAlarms();

  /// Removes the notification [id], scheduled or showing; one that rings
  /// stops.
  Future<void> cancel(int id);

  /// Ids of the notifications that are scheduled and not shown yet.
  Future<List<int>> pendingIds();

  /// Ids of the notifications that show in the tray now.
  Future<List<int>> activeIds();

  /// Payloads of the notifications the user taps. Every listener starts
  /// with the one that launched the app.
  Stream<String> get taps;
}

/// Platforms without notifications: web, desktop, and tests.
class UnavailableLocalNotifications implements LocalNotifications {
  /// Creates the notifications.
  const new();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> areAllowed(String channelId) async => true;

  @override
  Future<void> openSettings() async =>
      throw UnsupportedError('No notification settings on this platform.');

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
  }) async {}

  @override
  Future<bool> canScheduleExact() async => false;

  @override
  Future<bool> requestExactAlarms() async => false;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<List<int>> pendingIds() async => const [];

  @override
  Future<List<int>> activeIds() async => const [];

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

/// Whether the system lets the app show notifications on [channelId].
/// Checks again whenever the app returns to the foreground: the user may
/// have changed it in the system settings.
@riverpod
Future<bool> localNotificationsAllowed(Ref ref, String channelId) {
  final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(lifecycle.dispose);
  return ref.watch(localNotificationsProvider).areAllowed(channelId);
}
