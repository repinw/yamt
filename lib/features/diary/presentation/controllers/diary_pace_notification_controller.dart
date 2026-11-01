import 'dart:developer' show log;

import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_shares_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_times_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_marker_controller.dart';

part 'diary_pace_notification_controller.g.dart';

const _logName = 'DiaryPaceNotificationController';
const _onKey = 'diary_pace_notification_on_v1';
const _spentKey = 'diary_pace_notification_spent_v1';
const _setValue = 'set';

/// Notification ids of the pace notices: this base plus the meal's index
/// in [MealType.sectionOrder]. Only today's are ever scheduled.
const _idBase = 300000000;

/// The debug build's test notice, apart from the real ones, so a sync
/// never cancels it.
const int _debugId = _idBase + 99;

/// The Android notification channel of the pace notices.
const diaryPaceChannelId = 'diary_pace';

/// The localized texts of a pace notice.
typedef DiaryPaceNoticeTexts = ({
  String channelName,
  String Function(MealType meal, int kcal) title,
  String Function(DiaryPaceMacro? macro) body,
});

/// Whether a notice comes when the pace marker frees a meal's kcal again,
/// saved on the device. Off until the user turns it on in the budget card's
/// menu; it only works while the pace marker is on.
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

  /// Schedules today's notices for [pace] and cancels the rest; null
  /// cancels all. A meal whose notice came already today gets no second
  /// one. Calls run one after the other, so an older day never lands after
  /// a newer one.
  Future<void> sync(DiaryPaceDay? pace, DiaryPaceNoticeTexts texts) {
    final next = _syncs.then((_) => _sync(pace, texts));
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

  Future<void> _sync(DiaryPaceDay? pace, DiaryPaceNoticeTexts texts) async {
    if (!ref.mounted) return;
    final notifications = ref.read(localNotificationsProvider);
    final preferences = ref.read(appPreferencesProvider);
    final now = ref.read(clockProvider)();
    final spent = _readSpent(preferences, normalizeLocalDay(now));
    // What was planned before this sync decides what may be cancelled.
    final planned = Map.of(spent);
    final wanted = <int, DiaryPaceNotice>{};
    if (pace != null && isSameLocalDay(pace.day, now)) {
      for (final notice in diaryPaceNotices(pace)) {
        final came = spent[notice.meal];
        if (came != null && !came.isAfter(now)) continue;
        // Due already while the app is open: the card shows it.
        spent[notice.meal] = notice.at.isAfter(now) ? notice.at : now;
        if (notice.at.isAfter(now)) wanted[_id(notice.meal)] = notice;
      }
    }
    // Planned notices that no longer come are not spent.
    spent.removeWhere(
      (meal, at) => at.isAfter(now) && !wanted.containsKey(_id(meal)),
    );
    // Turned off, none of them stays.
    final off = !state || !ref.read(diaryPaceMarkerControllerProvider);
    await preferences.setString(_spentKey, _encodeSpent(now, spent));
    // Each call on its own, so one failure leaves the others in place. Only
    // pending notices go; a passed one is shown or held back by Android to
    // save battery, and stays as it is.
    final pending = await _logFailure(notifications.pendingIds) ?? const [];
    for (final meal in MealType.sectionOrder) {
      final id = _id(meal);
      final came = planned[meal];
      if (pending.contains(id) &&
          !wanted.containsKey(id) &&
          (off || came == null || came.isAfter(now))) {
        await _logFailure(() => notifications.cancel(id));
      }
    }
    for (final MapEntry(key: id, value: notice) in wanted.entries) {
      await _logFailure(
        () => notifications.schedule(
          id: id,
          at: notice.at,
          channel: (id: diaryPaceChannelId, name: texts.channelName),
          title: texts.title(notice.meal, notice.freeKcal),
          body: texts.body(pace?.macro),
          payload: diaryPaceChannelId,
        ),
      );
    }
  }

  /// Shows the notice of the meal due now in a few seconds, whatever the
  /// pace says. Only for the debug build, so a phone test needs no waiting.
  Future<void> debugShowSoon(
    DiaryPaceDay pace,
    DiaryPaceNoticeTexts texts,
  ) async {
    await _logFailure(ref.read(localNotificationsProvider).requestPermission);
    if (!ref.mounted) return;
    final now = ref.read(clockProvider)();
    final minute = now.hour * 60 + now.minute;
    final index = pace.times.ends.indexWhere((end) => minute < end);
    final meal = MealType.sectionOrder[index < 0 ? 0 : index];
    final kcal = pace.shares.splitKcal(
      pace.targetKcal,
    )[MealType.sectionOrder.indexOf(meal)];
    await _logFailure(
      () => ref
          .read(localNotificationsProvider)
          .schedule(
            id: _debugId,
            at: now.add(const Duration(seconds: 5)),
            channel: (id: diaryPaceChannelId, name: texts.channelName),
            title: texts.title(meal, kcal),
            body: texts.body(pace.macro),
            payload: diaryPaceChannelId,
          ),
    );
  }

  int _id(MealType meal) => _idBase + MealType.sectionOrder.indexOf(meal);

  // Stored as "yyyy-mm-dd|meal=minute,meal=minute" for today only.
  Map<MealType, DateTime> _readSpent(AppPreferences preferences, DateTime day) {
    final stored = preferences.getStringSync(_spentKey)?.split('|');
    if (stored case [final key, final pairs]
        when parseLocalDayKey(key) == day) {
      return {
        for (final pair in pairs.split(','))
          if (pair.split('=') case [final meal, final minute])
            if ((
                  MealType.values.where((m) => m.jsonValue == meal).firstOrNull,
                  int.tryParse(minute),
                )
                case (final MealType type, final int at))
              type: DateTime(day.year, day.month, day.day, 0, at),
      };
    }
    return {};
  }

  String _encodeSpent(DateTime now, Map<MealType, DateTime> spent) {
    final day = normalizeLocalDay(now);
    final pairs = [
      for (final MapEntry(key: meal, value: at) in spent.entries)
        '${meal.jsonValue}=${at.hour * 60 + at.minute}',
    ];
    return '${localDayKey(day)}|${pairs.join(',')}';
  }

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

/// What today's pace notices need; null while they are off, the pace
/// marker is off, today loads, or today is a pause day.
@riverpod
DiaryPaceDay? diaryPaceNoticeDay(Ref ref) {
  if (!ref.watch(diaryPaceNotificationControllerProvider) ||
      !ref.watch(diaryPaceMarkerControllerProvider)) {
    return null;
  }
  final today = ref.watch(diaryTodayProvider);
  final card = ref.watch(diaryBalanceCardProvider(today));
  if (card == null || (card.loadedMetrics?.state.isPauseDay ?? false)) {
    return null;
  }
  // Practice days and the days before a restart show the marker too.
  final daily =
      card.loadedMetrics?.daily ??
      card.practiceDay?.daily ??
      card.scheduledRestart!.daily;
  final nutrition = ref.watch(
    diaryDayDashboardControllerProvider(today)
        .select((s) => s.data?.nutritionBars),
  );
  return (
    day: today,
    targetKcal: daily.targetKcal,
    eatenKcal: daily.eatenKcal,
    times: ref.watch(diaryMealTimesControllerProvider),
    shares: ref.watch(diaryMealSharesControllerProvider),
    macro: nutrition == null
        ? null
        : diaryPaceMacro(
            eaten: (
              protein: nutrition.protein,
              carbs: nutrition.carbs,
              fat: nutrition.fat,
            ),
            targets: (
              protein: nutrition.goals.protein,
              carbs: nutrition.goals.carbs,
              fat: nutrition.goals.fat,
            ),
          ),
  );
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
