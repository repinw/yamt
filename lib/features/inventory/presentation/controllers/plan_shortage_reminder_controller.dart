import 'dart:developer' show log;

import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/application/inventory_shopping_suggestions.dart';
import 'package:yamt/features/inventory/domain/plan_shortage_reminders.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';

part 'plan_shortage_reminder_controller.g.dart';

const _logName = 'PlanShortageReminderController';
const _offKey = 'plan_shortage_reminder_off_v1';
const _minuteKey = 'plan_shortage_reminder_minute_v1';
const _quietDaysKey = 'plan_shortage_reminder_quiet_days_v1';
const _permissionAskedKey = 'plan_shortage_reminder_permission_asked_v1';
const _setValue = 'set';

/// 17:00, the default time of the day-before reminder.
const int _defaultMinute = 17 * 60;

/// The day-before reminder settings, saved on the device.
typedef PlanShortageReminderSettings = ({
  bool enabled,
  int minuteOfDay,
  Set<DateTime> quietDays,
  bool permissionAsked,
});

/// The localized texts of the reminder notification.
typedef PlanShortageReminderTexts = ({
  String channelName,
  String Function(int count) title,
  String body,
});

/// The day-before reminder for missing plan ingredients. Its state is the
/// settings: on or off (on until the user turns it off), the time of day in
/// minutes after midnight, the plan days the user answered already, and
/// whether the app asked for the notification permission.
@riverpod
class PlanShortageReminderController extends _$PlanShortageReminderController {
  @override
  PlanShortageReminderSettings build() {
    final preferences = ref.watch(appPreferencesProvider);
    return (
      enabled: preferences.getStringSync(_offKey) != _setValue,
      minuteOfDay: preferences.getIntSync(_minuteKey) ?? _defaultMinute,
      quietDays: {
        for (final key
            in (preferences.getStringSync(_quietDaysKey) ?? '').split(','))
          ?parseLocalDayKey(key),
      },
      permissionAsked:
          preferences.getStringSync(_permissionAskedKey) == _setValue,
    );
  }

  /// Turns the reminder on or off. Turning it on asks for the
  /// notification permission, which the user may have denied before.
  Future<void> setEnabled({required bool enabled}) async {
    _update(enabled: enabled);
    final preferences = ref.read(appPreferencesProvider);
    if (enabled) {
      await preferences.remove(_offKey);
      if (!ref.mounted) return;
      await _markPermissionAsked();
      if (!ref.mounted) return;
      await _requestPermission();
    } else {
      await preferences.setString(_offKey, _setValue);
    }
  }

  /// Sets the time of day the reminder fires.
  Future<void> setMinuteOfDay(int minuteOfDay) async {
    _update(minuteOfDay: minuteOfDay);
    await ref.read(appPreferencesProvider).setInt(_minuteKey, minuteOfDay);
  }

  /// Keeps the plan [day] quiet: the user answered its reminder.
  Future<void> quietDay(DateTime day) async {
    final today = normalizeLocalDay(ref.read(clockProvider)());
    // Past days never fire again, so they are dropped.
    final quietDays = {
      for (final quiet in state.quietDays)
        if (!quiet.isBefore(today)) quiet,
      normalizeLocalDay(day),
    };
    _update(quietDays: quietDays);
    await ref
        .read(appPreferencesProvider)
        .setString(_quietDaysKey, quietDays.map(localDayKey).join(','));
  }

  /// Schedules [reminders] and cancels the day-before notifications that
  /// are no longer needed. Asks for the notification permission once, with
  /// the first reminder. Calls run one after the other, so an older list
  /// never lands after a newer one.
  Future<void> sync(
    List<PlanShortageReminder> reminders,
    PlanShortageReminderTexts texts,
  ) {
    final next = _syncs.then((_) => _sync(reminders, texts));
    // A failed sync must not stop the ones after it.
    return _syncs = next.catchError((Object error, StackTrace stackTrace) {
      log(
        'Syncing the day-before reminders failed.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  Future<void> _syncs = Future.value();

  Future<void> _sync(
    List<PlanShortageReminder> reminders,
    PlanShortageReminderTexts texts,
  ) async {
    if (!ref.mounted) return;
    final notifications = ref.read(localNotificationsProvider);
    if (reminders.isNotEmpty && !state.permissionAsked) {
      await _markPermissionAsked();
      if (!ref.mounted) return;
      await _requestPermission();
    }
    final wanted = {
      for (final reminder in reminders)
        planShortageNotificationId(reminder.day): reminder,
    };
    // Each call on its own, so one failure leaves the others in place; the
    // next change of the plans or the stock tries again.
    final pending = await _logFailure(notifications.pendingIds) ?? const [];
    for (final id in pending) {
      if (isPlanShortageNotificationId(id) && !wanted.containsKey(id)) {
        await _logFailure(() => notifications.cancel(id));
      }
    }
    final now = ref.read(clockProvider)();
    for (final MapEntry(key: id, value: reminder) in wanted.entries) {
      // A passed one is pending or shown already; it stays as it is.
      if (!reminder.at.isAfter(now)) continue;
      await _logFailure(
        () => notifications.schedule(
          id: id,
          at: reminder.at,
          channel: (id: 'plan_shortage', name: texts.channelName),
          title: texts.title(reminder.count),
          body: texts.body,
          payload: planShortageReminderPayload(reminder.day),
        ),
      );
    }
  }

  /// The ingredients the plans of [day] still miss and the shopping list
  /// does not hold. Throws when the plans or the stock cannot be read.
  Future<List<ShoppingPlanNeed>> missingFor(DateTime day) async {
    // Plans load once; another device may have changed them since.
    ref.invalidate(openPlansProvider);
    final groups = ref.listen(
      inventoryShoppingPlanNeedGroupsProvider.future,
      (_, _) {},
    );
    try {
      return [
        for (final group in await groups.read())
          if (isSameLocalDay(group.day, day)) ...group.needs,
      ];
    } finally {
      groups.close();
    }
  }

  Future<void> _markPermissionAsked() async {
    _update(permissionAsked: true);
    await ref
        .read(appPreferencesProvider)
        .setString(_permissionAskedKey, _setValue);
  }

  Future<void> _requestPermission() =>
      _logFailure(ref.read(localNotificationsProvider).requestPermission);

  void _update({
    bool? enabled,
    int? minuteOfDay,
    Set<DateTime>? quietDays,
    bool? permissionAsked,
  }) => state = (
    enabled: enabled ?? state.enabled,
    minuteOfDay: minuteOfDay ?? state.minuteOfDay,
    quietDays: quietDays ?? state.quietDays,
    permissionAsked: permissionAsked ?? state.permissionAsked,
  );

  Future<T?> _logFailure<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error, stackTrace) {
      log(
        'A notification call failed.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}

/// The day-before reminders the open plans need now; none while the
/// reminder is off.
@riverpod
Future<List<PlanShortageReminder>> planShortageReminderPlan(Ref ref) async {
  // Not the permission flag: asking for it must not start another sync.
  final settings = ref.watch(
    planShortageReminderControllerProvider.select(
      (settings) => (
        enabled: settings.enabled,
        minuteOfDay: settings.minuteOfDay,
        quietDays: settings.quietDays,
      ),
    ),
  );
  if (!settings.enabled) {
    return const [];
  }
  final now = ref.watch(clockProvider)();
  final groups = await ref.watch(
    inventoryShoppingPlanNeedGroupsProvider.future,
  );
  return planShortageReminders(
    missingByDay(groups),
    now: now,
    minuteOfDay: settings.minuteOfDay,
    quietDays: settings.quietDays,
  );
}
