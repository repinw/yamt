import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Sets [time] in the Material time picker that is open and confirms it
/// with OK.
///
/// It types the time into the picker's text fields, so it does not depend on
/// where the dial puts its numbers. With a 12-hour clock it also picks AM or
/// PM.
Future<void> pickTimeInOpenPicker(WidgetTester tester, TimeOfDay time) async {
  final dialog = find.byType(TimePickerDialog);
  expect(dialog, findsOneWidget);
  final context = tester.element(dialog);
  final material = MaterialLocalizations.of(context);
  final deviceUses24HourClock = MediaQuery.alwaysUse24HourFormatOf(context);
  final twelveHourClock =
      hourFormat(
        of: material.timeOfDayFormat(
          alwaysUse24HourFormat: deviceUses24HourClock,
        ),
      ) ==
      HourFormat.h;
  // The picker reads the typed hour by the device's setting, whatever the
  // language says, so a test has to set it, as a phone of the language does.
  expect(
    twelveHourClock,
    !deviceUses24HourClock,
    reason:
        "Set alwaysUse24HourFormat in the test's MediaQuery to the clock "
        'of the language: true for German.',
  );

  await tester.tap(find.byTooltip(material.inputTimeModeButtonLabel));
  await tester.pumpAndSettle();

  if (twelveHourClock) {
    await tester.tap(
      find.descendant(
        of: dialog,
        matching: find.text(
          time.period == DayPeriod.am
              ? material.anteMeridiemAbbreviation
              : material.postMeridiemAbbreviation,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
  final fields = find.descendant(of: dialog, matching: find.byType(TextField));
  final hour = twelveHourClock
      ? (time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod)
      : time.hour;
  await tester.enterText(fields.first, '$hour');
  await tester.enterText(fields.last, '${time.minute}');
  await tester.tap(
    find.descendant(of: dialog, matching: find.text(material.okButtonLabel)),
  );
  await tester.pumpAndSettle();
}

/// Closes the Material time picker that is open with Cancel.
Future<void> cancelOpenTimePicker(WidgetTester tester) async {
  final dialog = find.byType(TimePickerDialog);
  expect(dialog, findsOneWidget);
  final material = MaterialLocalizations.of(tester.element(dialog));

  await tester.tap(
    find.descendant(
      of: dialog,
      matching: find.text(material.cancelButtonLabel),
    ),
  );
  await tester.pumpAndSettle();
}
