import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart'
    show DiaryWeeklyCheckInData;
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_hint_card/diary_weekly_checkin_hint_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('hides when no diary hint should be shown', (tester) async {
    await tester.pumpWidget(
      _App(
        child: DiaryWeeklyCheckInHintCard(
          checkInData: _checkInData(
            freshness: CalorieLearnedTdeeFreshness.none,
          ),
          selectedDay: DateTime(2026, 4, 3),
          selectedDayHasEntries: false,
          onContinue: () {},
          onOpenHealthTrends: () {},
          onToggleSelectedDaySkipped: ({required isSkipped}) async {},
        ),
      ),
    );

    expect(find.byKey(DiaryWeeklyCheckInCardKeys.hintCard), findsNothing);
  });

  testWidgets('pending ready hint wires continue and skip actions', (
    tester,
  ) async {
    var continued = false;
    bool? skipped;
    final selectedDay = DateTime(2026, 4, 3);

    await tester.pumpWidget(
      _App(
        child: DiaryWeeklyCheckInHintCard(
          checkInData: _checkInData(
            pendingWeeklyCheckIn: _pendingWeeklyCheckIn(),
            days: [
              _windowDay(day: selectedDay),
            ],
          ),
          selectedDay: selectedDay,
          selectedDayHasEntries: false,
          onContinue: () => continued = true,
          onOpenHealthTrends: () {},
          onToggleSelectedDaySkipped: ({required isSkipped}) async {
            skipped = isSkipped;
          },
        ),
      ),
    );

    expect(find.byKey(DiaryWeeklyCheckInCardKeys.hintCard), findsOneWidget);

    await tester.tap(find.byKey(DiaryWeeklyCheckInCardKeys.continueButton));
    await tester.tap(find.byKey(DiaryWeeklyCheckInCardKeys.skipDayButton));

    expect(continued, isTrue);
    expect(skipped, isTrue);
  });

  testWidgets('blocked weight hint opens trends and can unskip day', (
    tester,
  ) async {
    var openedTrends = false;
    bool? skipped;
    final selectedDay = DateTime(2026, 4, 3);

    await tester.pumpWidget(
      _App(
        child: DiaryWeeklyCheckInHintCard(
          checkInData: _checkInData(
            pendingWeeklyCheckIn: _pendingWeeklyCheckIn(),
            blockedReason:
                CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight,
            missingWeightDays: [
              DateTime(2026, 4, 6),
              DateTime(2026, 4, 7),
            ],
            days: [
              _windowDay(day: selectedDay, isSkippedIntakeDay: true),
            ],
          ),
          selectedDay: selectedDay,
          selectedDayHasEntries: true,
          onContinue: () {},
          onOpenHealthTrends: () => openedTrends = true,
          onToggleSelectedDaySkipped: ({required isSkipped}) async {
            skipped = isSkipped;
          },
        ),
      ),
    );

    await tester.tap(
      find.byKey(DiaryWeeklyCheckInCardKeys.openTrendsButton),
    );
    await tester.tap(find.byKey(DiaryWeeklyCheckInCardKeys.skipDayButton));

    expect(openedTrends, isTrue);
    expect(skipped, isFalse);
  });

  testWidgets('cache-only freshness hints render without pending actions', (
    tester,
  ) async {
    for (final freshness in [
      CalorieLearnedTdeeFreshness.stale,
      CalorieLearnedTdeeFreshness.urgent,
    ]) {
      await tester.pumpWidget(
        _App(
          child: DiaryWeeklyCheckInHintCard(
            checkInData: _checkInData(freshness: freshness),
            selectedDay: DateTime(2026, 4, 3),
            selectedDayHasEntries: false,
            onContinue: () {},
            onOpenHealthTrends: () {},
            onToggleSelectedDaySkipped: ({required isSkipped}) async {},
          ),
        ),
      );

      expect(
        find.byKey(DiaryWeeklyCheckInCardKeys.hintCard),
        findsOneWidget,
      );
      expect(
        find.byKey(DiaryWeeklyCheckInCardKeys.continueButton),
        findsNothing,
      );
    }
  });
}

PendingCalorieGoalWeeklyCheckIn _pendingWeeklyCheckIn() {
  return PendingCalorieGoalWeeklyCheckIn(
    windowStartDate: DateTime(2026, 4),
    windowEndDate: DateTime(2026, 4, 7),
    dueDate: DateTime(2026, 4, 8),
  );
}

CalorieWeeklyCheckInWindowDay _windowDay({
  required DateTime day,
  bool isSkippedIntakeDay = false,
}) {
  return CalorieWeeklyCheckInWindowDay(
    day: day,
    hasEntries: !isSkippedIntakeDay,
    loggedIntakeKcal: isSkippedIntakeDay ? 0 : 2100,
    resolvedIntakeKcal: isSkippedIntakeDay ? null : 2100,
    isSkippedIntakeDay: isSkippedIntakeDay,
    isHeartDay: false,
    activeKcal: 300,
    weightKg: 80,
  );
}

DiaryWeeklyCheckInData _checkInData({
  PendingCalorieGoalWeeklyCheckIn? pendingWeeklyCheckIn,
  CalorieWeeklyCheckInBlockedReason? blockedReason,
  List<DateTime> missingWeightDays = const <DateTime>[],
  List<CalorieWeeklyCheckInWindowDay> days =
      const <CalorieWeeklyCheckInWindowDay>[],
  CalorieLearnedTdeeFreshness freshness = CalorieLearnedTdeeFreshness.fresh,
}) {
  return DiaryWeeklyCheckInData(
    pendingWeeklyCheckIn: pendingWeeklyCheckIn,
    shouldAutoOpen: pendingWeeklyCheckIn != null,
    days: days,
    calculation: blockedReason == null && pendingWeeklyCheckIn != null
        ? const CalorieWeeklyCheckInCalculation(
            trendWeightChangePerDay: -0.05,
            averageIntakeKcal: 2150,
            measuredTrueTdeeKcal: 2500,
            calculatedTrueTdeeKcal: 2450,
            newGoalKcal: 2200,
            lastWeekAverageActiveKcal: 300,
            todayActiveKcal: 350,
            activityDeltaKcal: 25,
            dynamicGoalTodayKcal: 2225,
          )
        : null,
    blockedReason: blockedReason,
    missingIntakeDays: const <DateTime>[],
    missingWeightDays: missingWeightDays,
    freshness: freshness,
    latestLearnedTdeeAt: null,
    lowConfidence: false,
  );
}

class _App extends StatelessWidget {
  const _App({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}
