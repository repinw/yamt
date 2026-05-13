import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_burn_week_card/diary_balance_practice_day_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('practice card renders start date and future goal', (
    tester,
  ) async {
    await _pumpPracticeCard(
      tester,
      startDate: DateTime(2026, 4, 24),
      futureGoalKcal: 1200,
    );

    expect(find.byKey(DiaryBalanceCardKeys.practiceDay), findsOneWidget);
    expect(find.text('Practice day'), findsOneWidget);
    expect(find.textContaining('Burn Week starts on'), findsOneWidget);
    expect(find.text('Goal: 1,200 kcal'), findsOneWidget);
  });

  testWidgets('practice card omits goal when future goal is unknown', (
    tester,
  ) async {
    await _pumpPracticeCard(
      tester,
      startDate: DateTime(2026, 4, 24),
      futureGoalKcal: null,
    );

    expect(find.text('Practice day'), findsOneWidget);
    expect(find.textContaining('Burn Week starts on'), findsOneWidget);
    expect(find.textContaining('Goal:'), findsNothing);
  });

  test('practice card shows for any selected day before future start', () {
    final selectedDay = DateTime(2026, 4, 23);
    final startDate = DateTime(2026, 4, 24);
    final overview = _weekOverview(
      goalStartsInFuture: true,
      nextGoalStartDate: startDate,
    );

    expect(
      shouldShowDiaryBalancePracticeDayCard(
        weekOverview: overview,
        selectedDay: selectedDay,
      ),
      isTrue,
    );
    expect(
      shouldShowDiaryBalancePracticeDayCard(
        weekOverview: overview,
        selectedDay: startDate,
      ),
      isFalse,
    );
    expect(
      shouldShowDiaryBalancePracticeDayCard(
        weekOverview: overview,
        selectedDay: startDate.add(const Duration(days: 1)),
      ),
      isFalse,
    );
  });

  test('practice card stays hidden without future start metadata', () {
    final selectedDay = DateTime(2026, 4, 23);

    expect(
      shouldShowDiaryBalancePracticeDayCard(
        weekOverview: _weekOverview(goalStartsInFuture: false),
        selectedDay: selectedDay,
      ),
      isFalse,
    );
    expect(
      shouldShowDiaryBalancePracticeDayCard(
        weekOverview: _weekOverview(goalStartsInFuture: true),
        selectedDay: selectedDay,
      ),
      isFalse,
    );
  });
}

Future<void> _pumpPracticeCard(
  WidgetTester tester, {
  required DateTime startDate,
  required double? futureGoalKcal,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: DiaryBalancePracticeDayCard(
            startDate: startDate,
            futureGoalKcal: futureGoalKcal,
          ),
        ),
      ),
    ),
  );
}

CalorieWeekOverview _weekOverview({
  required bool goalStartsInFuture,
  DateTime? nextGoalStartDate,
}) {
  return CalorieWeekOverview(
    days: const <CalorieWeekDayOverview>[],
    totalConsumedKcal: 0,
    totalGoalKcal: 0,
    remainingKcal: 0,
    balanceStartDate: DateTime(2026, 4, 23),
    carryoverBeforeTodayKcal: 0,
    todayFlexibleGoalKcal: 0,
    goalStartsInFuture: goalStartsInFuture,
    nextGoalStartDate: nextGoalStartDate,
    futureGoalKcal: 1200,
  );
}
