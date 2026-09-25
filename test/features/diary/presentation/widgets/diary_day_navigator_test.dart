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

  testWidgets('shows Heute, Gestern or the weekday over the date', (
    tester,
  ) async {
    await pumpNavigator(tester, selectedDay: today);
    expect(find.text('HEUTE · MONTAG'), findsOneWidget);
    expect(find.text(DateFormat('d. MMM', 'de').format(today)), findsOne);
    expect(find.text('🏋️'), findsOneWidget);

    await pumpNavigator(tester, selectedDay: DateTime(2026, 4, 26));
    await tester.pumpAndSettle();
    expect(find.text('GESTERN · SONNTAG'), findsOneWidget);

    final earlier = DateTime(2026, 4, 5);
    await pumpNavigator(tester, selectedDay: earlier);
    await tester.pumpAndSettle();
    expect(
      find.text(DateFormat('EEEE', 'de').format(earlier).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(DateFormat('d. MMM', 'de').format(earlier)), findsOne);
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
