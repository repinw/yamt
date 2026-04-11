import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_day_navigation_card.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildHarness({
  required Locale locale,
  List<CalorieWeekDayOverview>? days,
  DateTime? selectedDay,
  DateTime? referenceNow,
}) {
  final resolvedDays =
      days ??
      <CalorieWeekDayOverview>[
        CalorieWeekDayOverview(
          date: DateTime(2026, 3, 23),
          totalKcal: 1200,
          goalKcal: 2200,
          entryCount: 1,
        ),
      ];

  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CaloriesDayNavigationCard(
        days: resolvedDays,
        selectedDay: selectedDay ?? resolvedDays.first.date,
        referenceNow: referenceNow,
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
    await tester.pumpWidget(_buildHarness(locale: const Locale('de')));

    expect(find.text('MO'), findsOneWidget);
  });

  testWidgets('uses localized weekday label in English', (tester) async {
    await tester.pumpWidget(_buildHarness(locale: const Locale('en')));

    expect(find.text('MON'), findsOneWidget);
  });

  testWidgets('uses the theme primary color for todays preview bar', (
    tester,
  ) async {
    final day = DateTime(2026, 3, 23);

    await tester.pumpWidget(
      _buildHarness(
        locale: const Locale('en'),
        referenceNow: day,
        days: [
          CalorieWeekDayOverview(
            date: day,
            totalKcal: 1200,
            goalKcal: 2200,
            entryCount: 1,
          ),
        ],
      ),
    );

    final barFinder = find.byKey(
      CaloriesPageKeys.dayNavigationPreviewBar(_dayKey(day)),
    );
    final bar = tester.widget<DecoratedBox>(barFinder);
    final decoration = bar.decoration as BoxDecoration;
    final colors = Theme.of(tester.element(barFinder)).colorScheme;

    expect(decoration.color, colors.primary);
  });

  testWidgets('uses the warning color for days above the goal', (tester) async {
    final day = DateTime(2026, 3, 23);

    await tester.pumpWidget(
      _buildHarness(
        locale: const Locale('en'),
        referenceNow: day.add(const Duration(days: 1)),
        days: [
          CalorieWeekDayOverview(
            date: day,
            totalKcal: 2300,
            goalKcal: 2200,
            entryCount: 1,
          ),
        ],
      ),
    );

    final bar = tester.widget<DecoratedBox>(
      find.byKey(CaloriesPageKeys.dayNavigationPreviewBar(_dayKey(day))),
    );
    final decoration = bar.decoration as BoxDecoration;
    final colors = Theme.of(
      tester.element(
        find.byKey(CaloriesPageKeys.dayNavigationPreviewBar(_dayKey(day))),
      ),
    ).colorScheme;

    expect(decoration.color, colors.error);
  });

  testWidgets('renders the goal line inside the preview chart', (tester) async {
    final day = DateTime(2026, 3, 23);

    await tester.pumpWidget(
      _buildHarness(
        locale: const Locale('en'),
        days: [
          CalorieWeekDayOverview(
            date: day,
            totalKcal: 1200,
            goalKcal: 2200,
            entryCount: 1,
          ),
        ],
      ),
    );

    final goalLineFinder = find.byKey(
      CaloriesPageKeys.dayNavigationPreviewGoalLine(_dayKey(day)),
    );
    final goalLine = tester.widget<DecoratedBox>(goalLineFinder);
    final decoration = goalLine.decoration as BoxDecoration;
    final colors = Theme.of(tester.element(goalLineFinder)).colorScheme;

    expect(goalLineFinder, findsOneWidget);
    expect(decoration.color, colors.outlineVariant);
  });
}

String _dayKey(DateTime day) {
  return '${day.year}-${day.month}-${day.day}';
}
