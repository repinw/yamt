import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/diary/domain/diary_calendar_bounds.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_calendar_overview_sheet/diary_calendar_overview_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
  });

  final today = DateTime(2026, 4, 27);
  final bounds = DiaryCalendarBounds.resolve(
    today: today,
    planStartDay: DateTime(2026, 3, 10),
  );

  Future<Future<DateTime?>> openSheet(
    WidgetTester tester, {
    DateTime? selectedDay,
  }) async {
    late Future<DateTime?> result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                result = showDiaryCalendarOverviewSheet(
                  context: context,
                  selectedDay: selectedDay ?? today,
                  today: today,
                  bounds: bounds,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('opens on the selected month and returns a tapped day', (
    tester,
  ) async {
    final result = await openSheet(tester);

    expect(find.text('April 2026'), findsOneWidget);

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();

    expect(await result, DateTime(2026, 4, 15));
  });

  testWidgets('month arrows move within the plan range', (tester) async {
    await openSheet(tester);

    await tester.tap(find.byKey(DiaryCalendarOverviewKeys.previousMonth));
    await tester.pumpAndSettle();
    expect(find.text('März 2026'), findsOneWidget);

    final previousButton = tester.widget<IconButton>(
      find.byKey(DiaryCalendarOverviewKeys.previousMonth),
    );
    expect(previousButton.onPressed, isNull);

    await tester.tap(find.byKey(DiaryCalendarOverviewKeys.nextMonth));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryCalendarOverviewKeys.nextMonth));
    await tester.pumpAndSettle();
    expect(find.text('Mai 2026'), findsOneWidget);

    final nextButton = tester.widget<IconButton>(
      find.byKey(DiaryCalendarOverviewKeys.nextMonth),
    );
    expect(nextButton.onPressed, isNull);
  });

  testWidgets('days outside the range are not selectable', (tester) async {
    final result = await openSheet(tester);

    await tester.tap(find.byKey(DiaryCalendarOverviewKeys.previousMonth));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    expect(find.text('März 2026'), findsOneWidget);

    await tester.drag(
      find.byKey(DiaryCalendarOverviewKeys.pageView),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);

    await tester.tap(find.byKey(DiaryCalendarOverviewKeys.today));
    await tester.pumpAndSettle();
    expect(await result, today);
  });
}
