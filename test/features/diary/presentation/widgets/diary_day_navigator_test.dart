import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
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

  testWidgets('shows Heute, Gestern or DD.MM', (tester) async {
    await pumpNavigator(tester, selectedDay: today);
    expect(find.text('Heute'), findsOneWidget);
    expect(find.text('🏋️'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsNothing);

    await pumpNavigator(tester, selectedDay: DateTime(2026, 4, 26));
    await tester.pumpAndSettle();
    expect(find.text('Gestern'), findsOneWidget);

    await pumpNavigator(tester, selectedDay: DateTime(2026, 4, 5));
    await tester.pumpAndSettle();
    expect(find.text('05.04'), findsOneWidget);

    await pumpNavigator(tester, selectedDay: DateTime(2026, 5, 3));
    await tester.pumpAndSettle();
    expect(find.text('03.05'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
