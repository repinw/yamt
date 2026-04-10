import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_day_navigation_card.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildHarness(Locale locale) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CaloriesDayNavigationCard(
        days: <CalorieWeekDayOverview>[
          CalorieWeekDayOverview(
            date: DateTime(2026, 3, 23),
            totalKcal: 1200,
            goalKcal: 2200,
            entryCount: 1,
          ),
        ],
        selectedDay: DateTime(2026, 3, 23),
        onSelectDay: _noopSelectDay,
        onPreviousDay: _noop,
        onNextDay: _noop,
      ),
    ),
  );
}

void _noop() {}

void _noopSelectDay(DateTime _) {}

void main() {
  test('chart max kcal keeps the minimum when all days are zero', () {
    final chartMaxKcal =
        resolveCaloriesDayNavigationChartMaxKcal(<CalorieWeekDayOverview>[
          CalorieWeekDayOverview(
            date: DateTime(2026, 3, 23),
            totalKcal: 0,
            goalKcal: 0,
            entryCount: 0,
          ),
        ]);

    expect(chartMaxKcal, 800);
  });

  test('chart max kcal uses headroom above the highest day value', () {
    final chartMaxKcal =
        resolveCaloriesDayNavigationChartMaxKcal(<CalorieWeekDayOverview>[
          CalorieWeekDayOverview(
            date: DateTime(2026, 3, 23),
            totalKcal: 7200,
            goalKcal: 6400,
            entryCount: 1,
          ),
          CalorieWeekDayOverview(
            date: DateTime(2026, 3, 24),
            totalKcal: 1800,
            goalKcal: 8100,
            entryCount: 1,
          ),
        ]);

    expect(chartMaxKcal, closeTo(8910, 0.001));
  });

  testWidgets('uses localized weekday label in German', (tester) async {
    await tester.pumpWidget(_buildHarness(const Locale('de')));

    expect(find.text('MO'), findsOneWidget);
  });

  testWidgets('uses localized weekday label in English', (tester) async {
    await tester.pumpWidget(_buildHarness(const Locale('en')));

    expect(find.text('MON'), findsOneWidget);
  });
}
