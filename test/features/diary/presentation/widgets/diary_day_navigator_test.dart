import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/core/widgets/home_shell_menu_button.dart';
import 'package:yamt/core/widgets/home_shell_menu_scope.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_navigator.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_today_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/app_font_test_utils.dart';

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

  group('date line next to the real header tools', () {
    setUpAll(loadAppFonts);

    final todayValue = DateTime(2026, 11, 21);
    // The same tools as diary_home_shell_top_chrome.dart: Menü on the left;
    // on the right Einkauf with a badge on today, Heute on another day.
    Future<void> pumpHeader(
      WidgetTester tester, {
      required double width,
      required double textScale,
      DateTime? selectedDay,
      int badge = 7,
      VoidCallback? onPrevious,
      VoidCallback? onNext,
      VoidCallback? onOpenCalendar,
    }) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final day = selectedDay ?? todayValue;
      final isToday = day == todayValue;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: AppFonts.sans),
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: HomeShellMenuScope(
            openMenu: () {},
            child: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: Builder(
                  builder: (context) => DiaryDayNavigator(
                    selectedDay: day,
                    today: todayValue,
                    canGoBack: true,
                    canGoForward: true,
                    onPrevious: onPrevious ?? () {},
                    onNext: onNext ?? () {},
                    onOpenCalendar: onOpenCalendar ?? () {},
                    reservedTools: [
                      DiaryTodayButton(onPressed: () {}),
                      HomeHeaderTool(
                        symbol: const Icon(Icons.shopping_cart_rounded),
                        label: AppLocalizations.of(context)!.homeShopping,
                        badgeCount: 100,
                        onPressed: null,
                      ),
                    ],
                    leadingActions: const [HomeShellMenuButton()],
                    actions: [
                      if (isToday)
                        HomeHeaderTool(
                          symbol: const Icon(Icons.shopping_cart_rounded),
                          label: AppLocalizations.of(context)!.homeShopping,
                          badgeCount: badge,
                          onPressed: () {},
                        )
                      else
                        DiaryTodayButton(onPressed: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Finder dateOf(DateTime day) => find.text(dateLine(day));

    const dateText = 'Sa, 21. Nov.';

    for (final width in [308.0, 412.0]) {
      testWidgets('the date paints taller at text scale 2.0 than at 1.0: '
          '${width}px', (tester) async {
        await pumpHeader(tester, width: width, textScale: 1);
        final normal = tester.getRect(find.text(dateText)).height;
        await pumpHeader(tester, width: width, textScale: 2);
        final large = tester.getRect(find.text(dateText)).height;

        expect(tester.takeException(), isNull);
        expect(
          large,
          greaterThan(normal * 1.3),
          reason: 'date paints $normal dp at 1.0 and $large dp at 2.0',
        );
      });

      for (final scale in [1.0, 2.0]) {
        testWidgets('the date never paints shorter than the tool words: '
            '${width}px, text scale $scale', (tester) async {
          await pumpHeader(tester, width: width, textScale: scale);

          final date = tester.getRect(find.text(dateText)).height;
          final menu = tester.getRect(find.text('Menü')).height;
          final shop = tester.getRect(find.text('Einkauf')).height;
          expect(tester.takeException(), isNull);
          expect(
            date,
            greaterThanOrEqualTo(menu),
            reason: 'date $date dp, Menü $menu dp',
          );
          expect(
            date,
            greaterThanOrEqualTo(shop),
            reason: 'date $date dp, Einkauf $shop dp',
          );
        });

        testWidgets('the day stays centred without overflow: '
            '${width}px, text scale $scale', (tester) async {
          await pumpHeader(tester, width: width, textScale: scale);

          final row = tester.getRect(find.byType(DiaryDayNavigator));
          final date = tester.getRect(find.text(dateText));
          expect(tester.takeException(), isNull);
          expect(
            date.center.dx,
            closeTo(row.center.dx, 1),
            reason:
                'date centre ${date.center.dx}, row centre '
                '${row.center.dx}',
          );
        });
      }
    }

    final switchedDays = <(String, DateTime)>[
      ('today', todayValue),
      ('yesterday', DateTime(2026, 11, 20)),
      ('vor 12 Tagen', DateTime(2026, 11, 9)),
      ('Monday 28 September', DateTime(2026, 9, 28)),
    ];

    // (width, text scale): both one-row and two-row layouts are in it.
    const layouts = [
      (360.0, 1.15),
      (412.0, 1.5),
      (308.0, 2.0),
      (412.0, 1.0),
      (360.0, 1.0),
    ];

    for (final (width, scale) in layouts) {
      for (final badge in [7, 100]) {
        testWidgets('the header stays put from day to day: ${width}px, '
            'text scale $scale, badge $badge', (tester) async {
          Future<void> show(DateTime day) async {
            await pumpHeader(
              tester,
              width: width,
              textScale: scale,
              selectedDay: day,
              badge: badge,
            );
            await tester.pumpAndSettle();
          }

          await show(switchedDays.first.$2);
          final height = tester.getSize(find.byType(DiaryDayNavigator)).height;
          final menu = tester.getRect(
            find.byKey(HomeShellMenuButton.buttonKey),
          );
          final dateHeight = tester.getRect(dateOf(todayValue)).height;

          for (final (name, day) in switchedDays) {
            await show(day);

            expect(tester.takeException(), isNull, reason: name);
            expect(
              tester.getSize(find.byType(DiaryDayNavigator)).height,
              closeTo(height, 0.01),
              reason: 'navigator height for $name',
            );
            expect(
              tester.getRect(find.byKey(HomeShellMenuButton.buttonKey)),
              menu,
              reason: 'Menü rect for $name (a changed row moves it)',
            );
            expect(
              tester.getRect(dateOf(day)).height,
              closeTo(dateHeight, 0.01),
              reason: 'painted date height for $name',
            );
          }
        });
      }
    }

    // Other years have other weekdays, so other dates are the widest: the
    // reserved width must hold every date of every year.
    final otherYearDays = <(String, DateTime)>[
      ('Monday 30 September 2024', DateTime(2024, 9, 30)),
      ('Monday 20 September 2027', DateTime(2027, 9, 20)),
      ('29 February 2024', DateTime(2024, 2, 29)),
    ];

    for (final (width, scale) in const [(412.0, 1.0), (308.0, 2.0)]) {
      for (final (name, day) in otherYearDays) {
        testWidgets('the date line fits its box and keeps the layout: $name, '
            '${width}px, text scale $scale', (tester) async {
          await pumpHeader(
            tester,
            width: width,
            textScale: scale,
            selectedDay: day,
          );
          await tester.pumpAndSettle();
          final line = dateLine(day);
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(line),
          );
          final text = paragraph.text as TextSpan;
          final painter = TextPainter(
            text: TextSpan(text: line, style: text.style),
            textDirection: paragraph.textDirection,
            textScaler: paragraph.textScaler,
            maxLines: 1,
          )..layout();
          final textWidth = painter.width;
          painter.dispose();
          final box = tester.getSize(
            find
                .ancestor(of: find.text(line), matching: find.byType(SizedBox))
                .first,
          );

          expect(tester.takeException(), isNull);
          expect(
            textWidth,
            lessThanOrEqualTo(box.width + 0.01),
            reason: '"$line" needs $textWidth dp, its box is ${box.width} dp',
          );
          expect(
            paragraph.size.width,
            greaterThanOrEqualTo(textWidth - 0.01),
            reason:
                '"$line" needs $textWidth dp, paragraph is '
                '${paragraph.size.width} dp wide (clipped)',
          );

          final height = tester.getRect(find.text(line)).height;
          await pumpHeader(tester, width: width, textScale: scale);
          await tester.pumpAndSettle();
          final todayHeight = tester.getRect(dateOf(todayValue)).height;
          expect(
            height,
            closeTo(todayHeight, 0.01),
            reason:
                'painted date height $height dp for $name, '
                '$todayHeight dp today',
          );
        });
      }
    }

    testWidgets('the side tools paint at full height and do not touch the '
        'date: 308px, text scale 2.0', (tester) async {
      await pumpHeader(tester, width: 308, textScale: 2);
      final menu = tester.getRect(find.text('Menü'));
      final shop = tester.getRect(find.text('Einkauf'));
      final date = tester.getRect(find.text(dateText));

      // Full size = the size the same tool has when nothing limits it.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: AppFonts.sans),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: HomeHeaderTool(
                symbol: Icon(Icons.menu_rounded),
                label: 'Menü',
                onPressed: null,
              ),
            ),
          ),
        ),
      );
      final fullMenu = tester.getRect(find.text('Menü'));
      final fullIcon = tester.getRect(find.byIcon(Icons.menu_rounded));

      await pumpHeader(tester, width: 308, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(
        menu.height,
        closeTo(fullMenu.height, 0.01),
        reason: 'Menü paints ${menu.height} dp, full ${fullMenu.height} dp',
      );
      expect(menu.width, closeTo(fullMenu.width, 0.01));
      expect(
        shop.height,
        closeTo(fullMenu.height, 0.01),
        reason: 'Einkauf paints ${shop.height} dp, full ${fullMenu.height}',
      );
      expect(
        tester.getRect(find.byIcon(Icons.menu_rounded)).size,
        fullIcon.size,
      );
      expect(menu.overlaps(date), isFalse, reason: '$menu vs $date');
      expect(shop.overlaps(date), isFalse, reason: '$shop vs $date');
    });

    // (width, text scale): 308 dp at 2.0 uses two rows, 412 dp at 1.0 one.
    for (final (width, scale) in const [(308.0, 2.0), (412.0, 1.0)]) {
      testWidgets('arrows and label work: ${width}px, text scale $scale', (
        tester,
      ) async {
        var previous = 0;
        var next = 0;
        var opened = 0;
        await pumpHeader(
          tester,
          width: width,
          textScale: scale,
          onPrevious: () => previous++,
          onNext: () => next++,
          onOpenCalendar: () => opened++,
        );

        await tester.tap(find.byKey(DiaryDayNavigatorKeys.previous));
        await tester.tap(find.byKey(DiaryDayNavigatorKeys.next));
        await tester.tap(find.byKey(DiaryDayNavigatorKeys.next));
        await tester.tap(find.byKey(DiaryDayNavigatorKeys.label));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(previous, 1);
        expect(next, 2);
        expect(opened, 1);
      });

      testWidgets('swiping the day works: ${width}px, text scale $scale', (
        tester,
      ) async {
        var previous = 0;
        var next = 0;
        await pumpHeader(
          tester,
          width: width,
          textScale: scale,
          onPrevious: () => previous++,
          onNext: () => next++,
        );

        await tester.fling(
          find.byKey(DiaryDayNavigatorKeys.label),
          const Offset(-100, 0),
          1000,
        );
        await tester.pumpAndSettle();
        await tester.fling(
          find.byKey(DiaryDayNavigatorKeys.label),
          const Offset(100, 0),
          1000,
        );
        await tester.pumpAndSettle();

        expect(next, 1);
        expect(previous, 1);
      });
    }
  });
}
