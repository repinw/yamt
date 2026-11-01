import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_meal_time_button.dart';

import '../../../../../helpers/time_picker_test_utils.dart';

const _buttonKey = ValueKey<String>('time-button');

/// A button for [minute] that collects the minutes picked with it.
Future<List<int>> _pump(
  WidgetTester tester, {
  int minute = 9 * 60,
  bool use24HourClock = false,
}) async {
  final picked = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(alwaysUse24HourFormat: use24HourClock),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: DiaryMealTimeButton(
            key: _buttonKey,
            minute: minute,
            label: (time) => 'by $time',
            onPicked: picked.add,
          ),
        ),
      ),
    ),
  );
  return picked;
}

String? _label(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(_buttonKey), matching: find.byType(Text)),
    )
    .data;

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(_buttonKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('puts the time into the words it is given', (tester) async {
    await _pump(tester);

    expect(_label(tester), 'by 9:00 AM');
  });

  testWidgets('shows the minutes of the day as the time of day', (
    tester,
  ) async {
    await _pump(tester, minute: 13 * 60 + 5);
    expect(_label(tester), 'by 1:05 PM');

    await _pump(tester, minute: 0);
    expect(_label(tester), 'by 12:00 AM');

    await _pump(tester, minute: 24 * 60 - 1);
    expect(_label(tester), 'by 11:59 PM');
  });

  testWidgets("shows the time on the device's 24-hour clock", (tester) async {
    await _pump(tester, minute: 13 * 60 + 5, use24HourClock: true);

    expect(_label(tester), 'by 13:05');
  });

  testWidgets('a tap opens the time picker on its time', (tester) async {
    await _pump(tester, minute: 13 * 60 + 5);
    expect(find.byType(TimePickerDialog), findsNothing);

    await _open(tester);

    expect(
      tester
          .widget<TimePickerDialog>(find.byType(TimePickerDialog))
          .initialTime,
      const TimeOfDay(hour: 13, minute: 5),
    );
  });

  testWidgets('gives the picked time as minutes after midnight', (
    tester,
  ) async {
    final picked = await _pump(tester);
    await _open(tester);

    await pickTimeInOpenPicker(tester, const TimeOfDay(hour: 13, minute: 45));

    expect(picked, [13 * 60 + 45]);
    expect(find.byType(TimePickerDialog), findsNothing);
  });

  testWidgets('takes the first and the last minute of the day', (tester) async {
    final picked = await _pump(tester);

    await _open(tester);
    await pickTimeInOpenPicker(tester, const TimeOfDay(hour: 0, minute: 0));
    await _open(tester);
    await pickTimeInOpenPicker(tester, const TimeOfDay(hour: 23, minute: 59));

    expect(picked, [0, 24 * 60 - 1]);
  });

  testWidgets('a cancelled picker gives nothing', (tester) async {
    final picked = await _pump(tester);
    await _open(tester);

    await cancelOpenTimePicker(tester);

    expect(picked, isEmpty);
    expect(find.byType(TimePickerDialog), findsNothing);
  });
}
