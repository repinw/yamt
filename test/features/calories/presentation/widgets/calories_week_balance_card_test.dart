import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_week_balance_card.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'renders seven day slots and only shows bars from the balance start date',
    (tester) async {
      final today = normalizeDiaryDay(DateTime.now());
      final days = buildDiaryVisibleDays(anchorDay: today);
      final balanceStartDate = today.subtract(const Duration(days: 2));
      final overview = CalorieWeekOverview(
        days: List<CalorieWeekDayOverview>.unmodifiable([
          for (var index = 0; index < days.length; index += 1)
            CalorieWeekDayOverview(
              date: days[index],
              totalKcal: 1500 + (index * 100),
              goalKcal: 2000,
              entryCount: 1,
            ),
        ]),
        totalConsumedKcal: 0,
        totalGoalKcal: 0,
        remainingKcal: 0,
        balanceStartDate: balanceStartDate,
        carryoverBeforeTodayKcal: 400,
        todayFlexibleGoalKcal: 2400,
        goalStartsInFuture: false,
        nextGoalStartDate: null,
        futureGoalKcal: null,
      );

      await tester.pumpWidget(_buildHarness(overview: overview));

      for (final day in days) {
        expect(
          find.byKey(CaloriesPageKeys.weekBalanceDayColumn(_dayKey(day))),
          findsOneWidget,
        );
      }

      expect(
        find.byKey(CaloriesPageKeys.weekBalanceBar(_dayKey(days[0]))),
        findsNothing,
      );
      expect(
        find.byKey(CaloriesPageKeys.weekBalanceBar(_dayKey(balanceStartDate))),
        findsOneWidget,
      );
      expect(
        find.byKey(CaloriesPageKeys.weekBalanceBar(_dayKey(today))),
        findsOneWidget,
      );
    },
  );

  testWidgets('renders warning color for a day above goal', (tester) async {
    final today = normalizeDiaryDay(DateTime.now());
    final days = buildDiaryVisibleDays(anchorDay: today);
    final overGoalDay = days[3];

    await tester.pumpWidget(
      _buildHarness(
        overview: CalorieWeekOverview(
          days: List<CalorieWeekDayOverview>.unmodifiable([
            for (final day in days)
              CalorieWeekDayOverview(
                date: day,
                totalKcal: day == overGoalDay ? 2300 : 1800,
                goalKcal: 2000,
                entryCount: 1,
              ),
          ]),
          totalConsumedKcal: 0,
          totalGoalKcal: 0,
          remainingKcal: 0,
          balanceStartDate: days.first,
          carryoverBeforeTodayKcal: 0,
          todayFlexibleGoalKcal: 2000,
          goalStartsInFuture: false,
          nextGoalStartDate: null,
          futureGoalKcal: null,
        ),
      ),
    );

    final bar = tester.widget<DecoratedBox>(
      find.byKey(CaloriesPageKeys.weekBalanceBar(_dayKey(overGoalDay))),
    );
    final decoration = bar.decoration as BoxDecoration;

    expect(decoration.color, _themeColor(tester).error);
  });
}

Widget _buildHarness({
  required CalorieWeekOverview overview,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: CaloriesWeekBalanceCard(overview: overview)),
  );
}

String _dayKey(DateTime day) {
  final normalized = normalizeDiaryDay(day);
  return '${normalized.year}-${normalized.month}-${normalized.day}';
}

ColorScheme _themeColor(WidgetTester tester) {
  return Theme.of(
    tester.element(find.byType(CaloriesWeekBalanceCard)),
  ).colorScheme;
}
