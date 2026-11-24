// Shared setup of the acceptance tests of the free kcal notice (#971,
// P1-P14). Expectations live in the test files; this file only drives
// DiaryPaceNotificationController.sync with a fake clock, fake local
// notifications, and the real German or English texts.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';
import 'package:yamt/features/diary/domain/diary_pace_notices.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_notification_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_pace_notification_listener.dart';
import 'package:yamt/l10n/app_localizations_de.dart';
import 'package:yamt/l10n/app_localizations_en.dart';

import '../../../helpers/fake_local_notifications.dart';
import '../../../helpers/memory_app_preferences.dart';

const _onKey = 'diary_pace_notification_on_v1';
const _markerKey = 'diary_pace_marker_v1';

/// Today in the acceptance tests of the notice.
final DateTime paceToday = DateTime(2026, 11, 12);

/// Tomorrow in the acceptance tests of the notice.
final DateTime paceTomorrow = DateTime(2026, 11, 13);

/// [hour]:[minute] on [day] (default [paceToday]).
DateTime paceAt(int hour, [int minute = 0, DateTime? day]) {
  final d = day ?? paceToday;
  return DateTime(d.year, d.month, d.day, hour, minute);
}

/// The German texts of the notice, as the app builds them.
DiaryPaceNoticeTexts germanTexts() =>
    diaryPaceNoticeTexts(AppLocalizationsDe());

/// The English texts of the notice, as the app builds them.
DiaryPaceNoticeTexts englishTexts() =>
    diaryPaceNoticeTexts(AppLocalizationsEn());

/// A pace day with the example values of the criteria: budget 2.000 kcal,
/// standard shares and times, nothing eaten, no macro.
DiaryPaceDay paceDay({
  double target = 2000,
  double eaten = 0,
  DiaryMealTimes times = DiaryMealTimes.standard,
  DiaryMealShares shares = DiaryMealShares.standard,
  DiaryPaceMacro? macro,
  DateTime? day,
}) => (
  day: day ?? paceToday,
  targetKcal: target,
  eatenKcal: eaten,
  times: times,
  shares: shares,
  macro: macro,
);

class _RecordingNotifications extends FakeLocalNotifications {
  final bodies = <int, String>{};

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
  }) {
    bodies[id] = body;
    return super.schedule(
      id: id,
      at: at,
      channel: channel,
      title: title,
      body: body,
      payload: payload,
      exact: exact,
      alarm: alarm,
    );
  }
}

/// Drives the controller's sync like the app does, on a clock a test moves.
class PaceHarness {
  new({DateTime? now, bool markerOn = true, bool noticesOn = true})
    : now = now ?? paceAt(0, 30) {
    preferences = MemoryAppPreferences(
      initialInts: {if (markerOn) _markerKey: 1},
      initialStrings: {if (noticesOn) _onKey: 'set'},
    );
    container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(() => this.now),
        localNotificationsProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);
    // The switch's state lives in the controller; keep it alive.
    container.listen(diaryPaceNotificationControllerProvider, (_, _) {});
  }

  /// What the clock shows.
  DateTime now;

  late final MemoryAppPreferences preferences;
  final notifications = _RecordingNotifications();
  late final ProviderContainer container;

  DiaryPaceNotificationController get controller =>
      container.read(diaryPaceNotificationControllerProvider.notifier);

  /// Plans the notices like the app does after a change. [tomorrowTarget]
  /// is tomorrow's real budget; null means no notice for tomorrow (pause
  /// day).
  Future<void> sync(
    DiaryPaceDay? pace, {
    double? tomorrowTarget,
    DiaryPaceNoticeTexts? texts,
  }) {
    final t = texts ?? germanTexts();
    if (tomorrowTarget == null) return controller.sync(pace, t);
    // Dynamic until the builder adds the named parameter, so the other
    // tests compile and fail on their own expectations.
    return (controller as dynamic).sync(
      pace,
      t,
      tomorrowTargetKcal: tomorrowTarget,
    ) as Future<void>;
  }

  /// Pending titles planned for exactly [at].
  List<String> titlesAt(DateTime at) => [
    for (final n in notifications.scheduled.values)
      if (n.at == at) n.title,
  ];

  /// The body of the notice planned for exactly [at]; null when none.
  String? bodyAt(DateTime at) => [
    for (final e in notifications.scheduled.entries)
      if (e.value.at == at) notifications.bodies[e.key],
  ].firstOrNull;

  /// Every planned time, sorted.
  List<DateTime> get plannedTimes =>
      notifications.scheduled.values.map((n) => n.at).toList()..sort();

  /// What a fired notice does on a phone: it leaves the pending list and
  /// shows in the tray.
  void fire(DateTime at) {
    final ids = [
      for (final e in notifications.scheduled.entries)
        if (e.value.at == at) e.key,
    ];
    for (final id in ids) {
      notifications.scheduled.remove(id);
      notifications.active.add(id);
    }
  }
}

/// The title the criteria name for [kcal] free kcal.
String germanTitle(String kcal) => 'Hey, du hast wieder $kcal kcal frei';

/// Fails when the title names a meal or a breakdown.
void expectNoMeal(String title) {
  for (final word in ['Frühstück', 'Mittag', 'Abend', 'Snack', 'davon']) {
    expect(title, isNot(contains(word)));
  }
}
