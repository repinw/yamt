import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_calendar_strip.dart';

void main() {
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
}

Future<void> _pumpCalendarStrip(
  WidgetTester tester, {
  required DateTime today,
  required DateTime selectedDay,
  required int todayRequest,
  required ValueChanged<DateTime> onSelectDay,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 350,
            child: DiaryCalendarStrip(
              today: today,
              selectedDay: selectedDay,
              todayRequest: todayRequest,
              onSelectDay: onSelectDay,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
