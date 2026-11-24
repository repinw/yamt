import 'dart:developer' show log;
import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';
import 'package:yamt/features/diary/domain/diary_pace_spent.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_shares_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_times_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_marker_controller.dart';

part 'diary_pace_notification_controller.g.dart';

const _logName = 'DiaryPaceNotificationController';
const _onKey = 'diary_pace_notification_on_v1';
const _spentKey = 'diary_pace_notification_spent_v1';
const _tomorrowKey = 'diary_pace_notification_tomorrow_v1';
const _setValue = 'set';

/// Notification ids of the pace notices: this base plus the meal's index
/// in [MealType.sectionOrder] for today's, and [_tomorrowId], apart from
/// today's, for tomorrow's day start.
const _idBase = 300000000;
const int _tomorrowId = _idBase + 50;

/// The debug build's test notice, apart from the real ones, so a sync
/// never cancels it.
const int _debugId = _idBase + 99;

/// The Android notification channel of the pace notices.
const diaryPaceChannelId = 'diary_pace';

/// The localized texts of a pace notice.
typedef DiaryPaceNoticeTexts = ({
  String channelName,
  String Function(int kcal) title,
  String Function(DiaryPaceMacro? macro) body,
});

/// A notice to schedule: when, its kcal, and the macro it points at.
typedef _Planned = ({DateTime at, int freeKcal, DiaryPaceMacro? macro});

/// Whether a notice comes at the start of each part of the day when kcal are
/// free, saved on the device. Off until the user turns it on in the budget
/// card's menu; it only works while the pace marker is on.
@riverpod
class DiaryPaceNotificationController
    extends _$DiaryPaceNotificationController {
  @override
  bool build() =>
      ref.watch(appPreferencesProvider).getStringSync(_onKey) == _setValue;

  /// Turns the notices on or off. Turning them on asks for the
  /// notification permission first.
  Future<void> setEnabled({required bool enabled}) async {
    final preferences = ref.read(appPreferencesProvider);
    if (!enabled) {
      state = false;
      await preferences.remove(_onKey);
      return;
    }
    // A second request while the system asks fails and would turn the
    // notices on before the answer.
    if (_requesting) return;
    _requesting = true;
    try {
      await _logFailure(ref.read(localNotificationsProvider).requestPermission);
    } finally {
      _requesting = false;
    }
    if (ref.mounted) state = true;
    await preferences.setString(_onKey, _setValue);
  }

  bool _requesting = false;

  /// Schedules today's notices for [pace] and tomorrow's day-start notice
  /// for [tomorrowTargetKcal], the budget of [tomorrowDay] (the day after
  /// today when null), and cancels the rest; a null [pace] cancels today's,
  /// a null [tomorrowTargetKcal] (a pause day) tomorrow's. Tomorrow's budget
  /// is not known while [tomorrowLoading] or when [tomorrowDay] is another
  /// day than tomorrow: then the pending notice stays as it is, if it was
  /// planned for tomorrow and the notices are on. One planned for today
  /// goes once today's notices are known, as today's own take over. While
  /// [todayLoading], or when [pace] is of another day than today, the
  /// pending notices of today stay as they are too, and one planned for today
  /// stays. A part of the day whose notice came or was
  /// due before the app opened gets none. Calls run one after the other, so
  /// an older day never lands after a newer one.
  Future<void> sync(
    DiaryPaceDay? pace,
    DiaryPaceNoticeTexts texts, {
    double? tomorrowTargetKcal,
    DateTime? tomorrowDay,
    bool tomorrowLoading = false,
    bool todayLoading = false,
  }) {
    final next = _syncs.then(
      (_) => _sync(
        pace,
        texts,
        tomorrowTargetKcal,
        tomorrowDay,
        tomorrowLoading,
        todayLoading,
      ),
    );
    return _syncs = next.catchError((Object error, StackTrace stackTrace) {
      log(
        'Syncing the pace notices failed.',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  Future<void> _syncs = Future.value();

  Future<void> _sync(
    DiaryPaceDay? pace,
    DiaryPaceNoticeTexts texts,
    double? tomorrowTargetKcal,
    DateTime? tomorrowDay,
    bool tomorrowLoading,
    bool todayLoading,
  ) async {
    if (!ref.mounted) return;
    final notifications = ref.read(localNotificationsProvider);
    final preferences = ref.read(appPreferencesProvider);
    final now = ref.read(clockProvider)();
    final today = normalizeLocalDay(now);
    final spent = decodeDiaryPaceSpent(
      preferences.getStringSync(_spentKey),
      today,
    );
    // What was planned before this sync decides what may be cancelled.
    final planned = Map.of(spent);
    final wanted = <int, _Planned>{};
    if (pace != null && isSameLocalDay(pace.day, now)) {
      for (final notice in diaryPaceNotices(pace)) {
        final came = spent[notice.meal];
        if (came != null && !came.isAfter(now)) continue;
        // Due already while the app is open: the card shows it.
        spent[notice.meal] = notice.at.isAfter(now) ? notice.at : now;
        if (notice.at.isAfter(now)) {
          wanted[_id(notice.meal)] = (
            at: notice.at,
            freeKcal: notice.freeKcal,
            // Nothing eaten: every macro is equally left, so none stands out.
            macro: pace.eatenKcal > 0 ? pace.macro : null,
          );
        }
      }
    }
    // Turned off, none of them stays; while today loads, they all do.
    final off = !state || !ref.read(diaryPaceMarkerControllerProvider);
    // A pace of another day is not today's: the day moved on meanwhile.
    final hold =
        (todayLoading || (pace != null && !isSameLocalDay(pace.day, now))) &&
        !off;
    // Planned notices that no longer come are not spent.
    if (!hold) {
      spent.removeWhere(
        (meal, at) => at.isAfter(now) && !wanted.containsKey(_id(meal)),
      );
    }
    final nextDay = nextLocalDay(today);
    // The notice planned earlier (_tomorrowKey: its day) stays while it is
    // for tomorrow, or for today while today loads, and tomorrow is unknown.
    final plannedFor = preferences.getStringSync(_tomorrowKey);
    final holdsToday = hold && plannedFor == localDayKey(today);
    final unknown =
        !off &&
        (tomorrowLoading ||
            holdsToday ||
            (tomorrowDay != null && !isSameLocalDay(tomorrowDay, nextDay)));
    final tomorrow = off || unknown
        ? null
        : _tomorrow(nextDay, tomorrowTargetKcal);
    final keep = unknown && (holdsToday || plannedFor == localDayKey(nextDay));
    await preferences.setString(_spentKey, encodeDiaryPaceSpent(now, spent));
    // Each call on its own, so one failure leaves the others in place. Only
    // pending notices go; a passed one is shown or held back by Android to
    // save battery, and stays as it is.
    final pending = await _logFailure(notifications.pendingIds) ?? const [];
    for (final meal in MealType.sectionOrder) {
      final id = _id(meal);
      final came = planned[meal];
      if (!hold &&
          pending.contains(id) &&
          !wanted.containsKey(id) &&
          (off || came == null || came.isAfter(now))) {
        await _logFailure(() => notifications.cancel(id));
      }
    }
    if (tomorrow == null && !keep && pending.contains(_tomorrowId)) {
      await _logFailure(() => notifications.cancel(_tomorrowId));
    }
    final toSchedule = <int, _Planned>{...wanted, _tomorrowId: ?tomorrow};
    for (final MapEntry(key: id, value: notice) in toSchedule.entries) {
      await _logFailure(
        () => notifications.schedule(
          id: id,
          at: notice.at,
          channel: (id: diaryPaceChannelId, name: texts.channelName),
          title: texts.title(notice.freeKcal),
          body: texts.body(notice.macro),
          payload: diaryPaceChannelId,
        ),
      );
    }
    if (tomorrow != null) {
      await preferences.setString(_tomorrowKey, localDayKey(nextDay));
    } else if (!keep) {
      await preferences.remove(_tomorrowKey);
    }
  }

  /// The breakfast notice at the start of [day], tomorrow, for tomorrow's
  /// budget with nothing eaten and no macro tip; null when there is none.
  _Planned? _tomorrow(DateTime day, double? targetKcal) {
    if (targetKcal == null) return null;
    final notice = diaryPaceNotices((
      day: day,
      targetKcal: targetKcal,
      eatenKcal: 0,
      times: ref.read(diaryMealTimesControllerProvider),
      shares: ref.read(diaryMealSharesControllerProvider),
      macro: null,
    )).where((notice) => notice.meal == MealType.breakfast).firstOrNull;
    return notice == null
        ? null
        : (at: notice.at, freeKcal: notice.freeKcal, macro: null);
  }

  /// Shows a notice in a few seconds, whatever the pace says, with what
  /// the pace marker stands ahead of the kcal eaten now. Only for the debug
  /// build, so a phone test needs no waiting.
  Future<void> debugShowSoon(
    DiaryPaceDay pace,
    DiaryPaceNoticeTexts texts,
  ) async {
    await _logFailure(ref.read(localNotificationsProvider).requestPermission);
    if (!ref.mounted) return;
    final now = ref.read(clockProvider)();
    final due = pace.times.dueAt(now.hour * 60 + now.minute, pace.shares);
    final kcal = math.max(0, (pace.targetKcal * due - pace.eatenKcal).round());
    await _logFailure(
      () => ref
          .read(localNotificationsProvider)
          .schedule(
            id: _debugId,
            at: now.add(const Duration(seconds: 5)),
            channel: (id: diaryPaceChannelId, name: texts.channelName),
            title: texts.title(kcal),
            body: texts.body(pace.eatenKcal > 0 ? pace.macro : null),
            payload: diaryPaceChannelId,
          ),
    );
  }

  int _id(MealType meal) => _idBase + MealType.sectionOrder.indexOf(meal);

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

/// Whether the system blocks the pace notices while they are on: the app's
/// notifications are off or their channel is muted. False while the check
/// runs or fails: the notices still try to show.
@riverpod
bool diaryPaceNotificationBlocked(Ref ref) {
  if (!ref.watch(diaryPaceNotificationControllerProvider)) return false;
  final allowed = ref.watch(
    localNotificationsAllowedProvider(diaryPaceChannelId),
  );
  return !allowed.hasError && allowed.value == false;
}
