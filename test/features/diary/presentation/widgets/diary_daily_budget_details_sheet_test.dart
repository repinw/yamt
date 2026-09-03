import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/application/diary_burn_week_balance/diary_daily_budget_details_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_details_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget(DiaryDailyBudgetDetailsData data) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        extensions: [
          MetricAccentColors.fromColorScheme(
            ColorScheme.fromSeed(seedColor: Colors.teal),
          ),
        ],
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final numberFormat = NumberFormat.decimalPattern('en');
            return Center(
              child: ElevatedButton(
                onPressed: () => showDiaryDailyBudgetDetailsSheet(
                  context: context,
                  data: data,
                  numberFormat: numberFormat,
                ),
                child: const Text('Open Sheet'),
              ),
            );
          },
        ),
      ),
    );
  }

  group('DiaryDailyBudgetDetailsSheet', () {
    testWidgets('renders all calculation rows and previous days breakdown',
        (tester) async {
      final monday = DateTime(2026, 4, 13);
      final tuesday = DateTime(2026, 4, 14);
      final wednesday = DateTime(2026, 4, 15);

      final data = DiaryDailyBudgetDetailsData(
        selectedDay: wednesday,
        baseGoalKcal: 2000,
        carryoverKcal: 150,
        activityBonusKcal: 200,
        targetKcal: 2350,
        eatenKcal: 650,
        dayLeftKcal: 1700,
        isHeartDay: false,
        expectedActivityKcal: 400,
        totalCarryoverBeforeTodayKcal: 300,
        remainingRunDays: 2,
        previousDays: [
          DiaryCarryoverDayDetail(
            date: monday,
            goalKcal: 2000,
            consumedKcal: 1850,
            differenceKcal: 150,
            isHeartDay: false,
          ),
          DiaryCarryoverDayDetail(
            date: tuesday,
            goalKcal: 2000,
            consumedKcal: 1850,
            differenceKcal: 150,
            isHeartDay: false,
          ),
        ],
      );

      await tester.pumpWidget(buildTestWidget(data));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byKey(DiaryBalanceCardKeys.dailyBudgetDetailsSheet),
          findsOneWidget);
      expect(find.text('Daily budget details'), findsOneWidget);
      expect(find.text("Today's calculation"), findsOneWidget);

      // Rows in calculation card
      expect(find.text('Base daily goal (without activity)'), findsOneWidget);
      expect(find.text('1,600 kcal'), findsOneWidget);
      expect(find.text('Expected activity'), findsOneWidget);
      expect(find.text('+400 kcal'), findsOneWidget);
      expect(find.text('Extra activity / workouts'), findsOneWidget);
      expect(find.text('+200 kcal'), findsOneWidget);
      expect(find.text('Carryover from previous days'), findsOneWidget);
      expect(find.text('+150 kcal'), findsOneWidget);
      expect(find.text('Effective daily goal'), findsOneWidget);
      expect(find.text('2,350 kcal'), findsOneWidget);
      expect(find.text('Food eaten so far'), findsOneWidget);
      expect(find.text('-650 kcal'), findsOneWidget);
      expect(find.text('Left today'), findsOneWidget);
      expect(find.text('1,700 kcal'), findsOneWidget);

      // Carryover origin section
      expect(find.text('Carryover origin'), findsOneWidget);
      expect(find.text('Total previous-day balance'), findsOneWidget);
      expect(find.text('+300 kcal'), findsOneWidget);
      expect(
        find.text('+300 kcal spread across 2 remaining days = +150 kcal / day'),
        findsOneWidget,
      );

      // Close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byKey(DiaryBalanceCardKeys.dailyBudgetDetailsSheet),
          findsNothing);
    });

    testWidgets('renders empty state when there are no previous days',
        (tester) async {
      final monday = DateTime(2026, 4, 13);

      final data = DiaryDailyBudgetDetailsData(
        selectedDay: monday,
        baseGoalKcal: 2000,
        carryoverKcal: 0,
        activityBonusKcal: 0,
        targetKcal: 2000,
        eatenKcal: 400,
        dayLeftKcal: 1600,
        isHeartDay: false,
        totalCarryoverBeforeTodayKcal: 0,
        remainingRunDays: 7,
        previousDays: const [],
      );

      await tester.pumpWidget(buildTestWidget(data));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byKey(DiaryBalanceCardKeys.dailyBudgetDetailsSheet),
          findsOneWidget);
      expect(
        find.text(
          'This is the first day of your active run. '
          'There is no carryover yet.',
        ),
        findsOneWidget,
      );
    });
  });
}
