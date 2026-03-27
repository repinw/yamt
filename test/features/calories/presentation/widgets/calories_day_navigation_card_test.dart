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
  testWidgets('uses localized weekday label in German', (tester) async {
    await tester.pumpWidget(_buildHarness(const Locale('de')));

    expect(find.text('MO'), findsOneWidget);
  });

  testWidgets('uses localized weekday label in English', (tester) async {
    await tester.pumpWidget(_buildHarness(const Locale('en')));

    expect(find.text('MON'), findsOneWidget);
  });
}
