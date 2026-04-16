import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
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

  testWidgets('shows the saved summary below the chart', (tester) async {
    final today = normalizeDiaryDay(DateTime.now());
    final days = buildDiaryVisibleDays(anchorDay: today);
    final overview = _overview(
      days: days,
      balanceStartDate: days.first,
      carryoverBeforeTodayKcal: 400,
      remainingKcal: 400,
    );

    await tester.pumpWidget(
      _buildHarness(overview: overview, locale: const Locale('de')),
    );

    expect(
      find.text('Seit Zielstart 400 kcal gespart.'),
      findsOneWidget,
    );
    _expectSummaryAccentColor(
      tester,
      message: 'Seit Zielstart 400 kcal gespart.',
      color: _themeColor(tester).primary,
    );
  });

  testWidgets('shows the overspent summary with warning color', (tester) async {
    final today = normalizeDiaryDay(DateTime.now());
    final days = buildDiaryVisibleDays(anchorDay: today);

    await tester.pumpWidget(
      _buildHarness(
        overview: _overview(
          days: days,
          balanceStartDate: days.first,
          carryoverBeforeTodayKcal: -250,
          remainingKcal: -250,
        ),
      ),
    );

    expect(
      find.text('You went over by 250 kcal since your goal started.'),
      findsOneWidget,
    );
    _expectSummaryAccentColor(
      tester,
      message: 'You went over by 250 kcal since your goal started.',
      color: _themeColor(tester).error,
    );
  });

  testWidgets(
    'uses todays intake for the summary message and warning color',
    (tester) async {
      final today = normalizeDiaryDay(DateTime.now());
      final days = buildDiaryVisibleDays(anchorDay: today);

      await tester.pumpWidget(
        _buildHarness(
          overview: _overview(
            days: days,
            balanceStartDate: days.first,
            carryoverBeforeTodayKcal: 300,
            remainingKcal: -150,
          ),
        ),
      );

      expect(
        find.text('You went over by 150 kcal since your goal started.'),
        findsOneWidget,
      );
      _expectSummaryAccentColor(
        tester,
        message: 'You went over by 150 kcal since your goal started.',
        color: _themeColor(tester).error,
      );
    },
  );

  testWidgets('shows the stable summary with primary color', (tester) async {
    final today = normalizeDiaryDay(DateTime.now());
    final days = buildDiaryVisibleDays(anchorDay: today);

    await tester.pumpWidget(
      _buildHarness(
        overview: _overview(
          days: days,
          balanceStartDate: days.first,
          carryoverBeforeTodayKcal: 0,
          remainingKcal: 0,
        ),
      ),
    );

    expect(
      find.text('Balanced since your goal started.'),
      findsOneWidget,
    );
    _expectSummaryAccentColor(
      tester,
      message: 'Balanced since your goal started.',
      color: _themeColor(tester).primary,
    );
  });

  testWidgets('shows the start-today summary with primary color', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    final days = buildDiaryVisibleDays(anchorDay: today);

    await tester.pumpWidget(
      _buildHarness(
        overview: _overview(
          days: days,
          balanceStartDate: today,
          carryoverBeforeTodayKcal: 0,
          remainingKcal: 0,
        ),
      ),
    );

    expect(
      find.text('Your goal starts today. The balance will build up from here.'),
      findsOneWidget,
    );
    _expectSummaryAccentColor(
      tester,
      message: 'Your goal starts today. The balance will build up from here.',
      color: _themeColor(tester).primary,
    );
  });

  testWidgets('shows the future-start summary for upcoming goals', (
    tester,
  ) async {
    final today = normalizeDiaryDay(DateTime.now());
    final days = buildDiaryVisibleDays(anchorDay: today);
    final nextGoalStartDate = today.add(const Duration(days: 1));

    await tester.pumpWidget(
      _buildHarness(
        overview: CalorieWeekOverview(
          days: List<CalorieWeekDayOverview>.unmodifiable([
            for (final day in days)
              CalorieWeekDayOverview(
                date: day,
                totalKcal: 0,
                goalKcal: 2000,
                entryCount: 0,
              ),
          ]),
          totalConsumedKcal: 0,
          totalGoalKcal: 14000,
          remainingKcal: 14000,
          balanceStartDate: today,
          carryoverBeforeTodayKcal: 0,
          todayFlexibleGoalKcal: 2000,
          goalStartsInFuture: true,
          nextGoalStartDate: nextGoalStartDate,
        ),
      ),
    );

    final expectedDate = DateFormat.yMMMd('en').format(nextGoalStartDate);
    expect(
      find.text(
        'Your goal starts on $expectedDate. '
        'The balance will begin automatically then.',
      ),
      findsOneWidget,
    );
  });

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

CalorieWeekOverview _overview({
  required List<DateTime> days,
  required DateTime balanceStartDate,
  required double carryoverBeforeTodayKcal,
  required double remainingKcal,
}) {
  return CalorieWeekOverview(
    days: List<CalorieWeekDayOverview>.unmodifiable([
      for (final day in days)
        CalorieWeekDayOverview(
          date: day,
          totalKcal: 1800,
          goalKcal: 2000,
          entryCount: 1,
        ),
    ]),
    totalConsumedKcal: 12600,
    totalGoalKcal: 14000,
    remainingKcal: remainingKcal,
    balanceStartDate: balanceStartDate,
    carryoverBeforeTodayKcal: carryoverBeforeTodayKcal,
    todayFlexibleGoalKcal: 2400,
    goalStartsInFuture: false,
    nextGoalStartDate: null,
  );
}

void _expectSummaryAccentColor(
  WidgetTester tester, {
  required String message,
  required Color color,
}) {
  final messageWidget = tester.widget<Text>(find.text(message));
  final icon = tester.widget<Icon>(
    find.byKey(CaloriesPageKeys.weekBalanceSummaryIcon),
  );

  expect(messageWidget.style?.color, color);
  expect(icon.color, color);
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
