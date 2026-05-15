import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_calendar_strip.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
  });

  testWidgets('calendar strip centers today and emits tapped day', (
    tester,
  ) async {
    final today = DateTime(2026, 4, 27);
    DateTime? selectedDay;

    await _pumpCalendarStrip(
      tester,
      today: today,
      selectedDay: today,
      todayRequest: 0,
      onSelectDay: (day) {
        selectedDay = day;
      },
    );

    expect(find.text('MO'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);

    await tester.tap(find.text('28'));
    await tester.pumpAndSettle();

    expect(selectedDay, DateTime(2026, 4, 28));
  });

  testWidgets('calendar strip reacts to today request updates', (tester) async {
    final today = DateTime(2026, 4, 27);

    await _pumpCalendarStrip(
      tester,
      today: today,
      selectedDay: DateTime(2026, 5, 3),
      todayRequest: 0,
      onSelectDay: (_) {},
    );

    await _pumpCalendarStrip(
      tester,
      today: today,
      selectedDay: DateTime(2026, 5, 3),
      todayRequest: 1,
      onSelectDay: (_) {},
    );

    expect(find.text('27'), findsOneWidget);
  });

  testWidgets('calendar strip colors heart days', (tester) async {
    final today = DateTime(2026, 4, 27);

    await _pumpCalendarStrip(
      tester,
      today: today,
      selectedDay: today,
      todayRequest: 0,
      heartDayKeys: const <String>{'2026-4-28'},
      onSelectDay: (_) {},
    );

    final heartDayText = tester.widget<Text>(find.text('28'));
    final context = tester.element(find.byType(DiaryCalendarStrip));
    final colors = Theme.of(context).colorScheme;
    final expectedHeartColor = MetricAccentColors.of(
      context,
    ).heartFor(colors.brightness);

    expect(heartDayText.style?.color, expectedHeartColor);
  });
}

Future<void> _pumpCalendarStrip(
  WidgetTester tester, {
  required DateTime today,
  required DateTime selectedDay,
  required int todayRequest,
  required ValueChanged<DateTime> onSelectDay,
  Set<String> heartDayKeys = const <String>{},
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 350,
            child: DiaryCalendarStrip(
              today: today,
              selectedDay: selectedDay,
              todayRequest: todayRequest,
              heartDayKeys: heartDayKeys,
              onSelectDay: onSelectDay,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
