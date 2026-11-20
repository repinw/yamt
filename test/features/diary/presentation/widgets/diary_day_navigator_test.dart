import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_navigator.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
  });

  final today = DateTime(2026, 4, 27);

  Future<void> pumpNavigator(
    WidgetTester tester, {
    required DateTime selectedDay,
    bool canGoBack = true,
    bool canGoForward = true,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
    VoidCallback? onOpenCalendar,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: DiaryDayNavigator(
              selectedDay: selectedDay,
              today: today,
              canGoBack: canGoBack,
              canGoForward: canGoForward,
              onPrevious: onPrevious ?? () {},
              onNext: onNext ?? () {},
              onOpenCalendar: onOpenCalendar ?? () {},
              actions: [IconButton(onPressed: () {}, icon: const Text('🏋️'))],
            ),
          ),
        ),
      ),
    );
  }

  String dateLine(DateTime day) => [
    DateFormat('ccc', 'de').format(day),
    DateFormat.MMMd('de').format(day),
  ].join(', ');

  testWidgets('shows Heute or Gestern over the date with its weekday', (
    tester,
  ) async {
    await pumpNavigator(tester, selectedDay: today);
    expect(find.text('Heute'), findsOneWidget);
    expect(find.text('Mo, 27. Apr.'), findsOneWidget);
    expect(find.text('🏋️'), findsOneWidget);

    await pumpNavigator(tester, selectedDay: DateTime(2026, 4, 26));
    await tester.pumpAndSettle();
    expect(find.text('Gestern'), findsOneWidget);
    expect(find.text('So, 26. Apr.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows Morgen and Übermorgen, then the number of days', (
    tester,
  ) async {
    await pumpNavigator(tester, selectedDay: DateTime(2026, 4, 28));
    expect(find.text('Morgen'), findsOneWidget);
    expect(find.text('Di, 28. Apr.'), findsOneWidget);

    await pumpNavigator(tester, selectedDay: DateTime(2026, 4, 29));
    await tester.pumpAndSettle();
    expect(find.text('Übermorgen'), findsOneWidget);
    expect(find.text('Mi, 29. Apr.'), findsOneWidget);

    await pumpNavigator(tester, selectedDay: DateTime(2026, 4, 30));
    await tester.pumpAndSettle();
    expect(find.text('in 3 Tagen'), findsOneWidget);
    expect(find.text('Do, 30. Apr.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('days beyond the named ones', () {
    final cases = <(String, DateTime, DateTime, String)>[
      (
        'two days back',
        DateTime(2026, 4, 25),
        DateTime(2026, 4, 27),
        'vor 2 Tagen',
      ),
      (
        'three days back',
        DateTime(2026, 4, 24),
        DateTime(2026, 4, 27),
        'vor 3 Tagen',
      ),
      (
        'three days ahead',
        DateTime(2026, 4, 30),
        DateTime(2026, 4, 27),
        'in 3 Tagen',
      ),
      // Clock change to summer time on 2026-03-29.
      (
        'over the March clock change, ahead',
        DateTime(2026, 4, 3),
        DateTime(2026, 3, 20),
        'in 14 Tagen',
      ),
      (
        'over the March clock change, back',
        DateTime(2026, 3, 20),
        DateTime(2026, 4, 3),
        'vor 14 Tagen',
      ),
      (
        'next to the March clock change',
        DateTime(2026, 3, 30),
        DateTime(2026, 3, 27),
        'in 3 Tagen',
      ),
      // Clock change to winter time on 2026-10-25.
      (
        'over the October clock change, back',
        DateTime(2026, 10, 20),
        DateTime(2026, 10, 30),
        'vor 10 Tagen',
      ),
      (
        'over the October clock change, ahead',
        DateTime(2026, 10, 30),
        DateTime(2026, 10, 20),
        'in 10 Tagen',
      ),
      (
        'next to the October clock change',
        DateTime(2026, 10, 23),
        DateTime(2026, 10, 26),
        'vor 3 Tagen',
      ),
    ];

    for (final (name, day, todayValue, text) in cases) {
      testWidgets('$name: "$text"', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 400,
                child: DiaryDayNavigator(
                  selectedDay: day,
                  today: todayValue,
                  canGoBack: true,
                  canGoForward: true,
                  onPrevious: () {},
                  onNext: () {},
                  onOpenCalendar: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.text(text), findsOneWidget);
        expect(find.text(dateLine(day)), findsOneWidget);
      });
    }
  });

  testWidgets('arrows, swipe and label call their callbacks', (tester) async {
    var previous = 0;
    var next = 0;
    var opened = 0;

    await pumpNavigator(
      tester,
      selectedDay: today,
      onPrevious: () => previous++,
      onNext: () => next++,
      onOpenCalendar: () => opened++,
    );

    await tester.tap(find.byKey(DiaryDayNavigatorKeys.previous));
    await tester.tap(find.byKey(DiaryDayNavigatorKeys.next));
    await tester.tap(find.byKey(DiaryDayNavigatorKeys.label));
    await tester.fling(
      find.byKey(DiaryDayNavigatorKeys.label),
      const Offset(-200, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(previous, 1);
    expect(next, 2);
    expect(opened, 1);
  });

  testWidgets('arrows are disabled at the range limits', (tester) async {
    var calls = 0;
    await pumpNavigator(
      tester,
      selectedDay: today,
      canGoBack: false,
      canGoForward: false,
      onPrevious: () => calls++,
      onNext: () => calls++,
    );

    await tester.tap(find.byKey(DiaryDayNavigatorKeys.previous));
    await tester.tap(find.byKey(DiaryDayNavigatorKeys.next));
    await tester.fling(
      find.byKey(DiaryDayNavigatorKeys.label),
      const Offset(200, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(calls, 0);
  });
}
