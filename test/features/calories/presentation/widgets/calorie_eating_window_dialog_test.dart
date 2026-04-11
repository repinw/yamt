import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_eating_window_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildHarness({
  required Future<bool> Function(int startMinuteOfDay, int endMinuteOfDay)
  onSaveEatingWindow,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: const MediaQueryData(alwaysUse24HourFormat: true),
      child: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () {
                  showCalorieEatingWindowDialog(
                    context: context,
                    initialStartMinuteOfDay: 6 * 60,
                    initialEndMinuteOfDay: 22 * 60,
                    onSaveEatingWindow: onSaveEatingWindow,
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> _pickTime(
  WidgetTester tester, {
  required Key changeButtonKey,
  required String hour,
  required String minute,
}) async {
  await tester.tap(find.byKey(changeButtonKey));
  await tester.pumpAndSettle();

  expect(find.byType(TimePickerDialog), findsOneWidget);

  final keyboardButton = find.byIcon(Icons.keyboard_outlined);
  if (keyboardButton.evaluate().isNotEmpty) {
    await tester.tap(keyboardButton);
    await tester.pumpAndSettle();
  }

  final fields = find.descendant(
    of: find.byType(TimePickerDialog),
    matching: find.byType(TextFormField),
  );
  await tester.enterText(fields.at(0), hour);
  await tester.enterText(fields.at(1), minute);
  await tester.pumpAndSettle();

  await tester.tap(
    find.descendant(of: find.byType(TimePickerDialog), matching: find.text('OK')),
  );
  await tester.pumpAndSettle();
}

String _formattedTime(WidgetTester tester, int minuteOfDay) {
  final context = tester.element(find.byType(AlertDialog));
  return formatMinuteOfDay(context, minuteOfDay: minuteOfDay);
}

void main() {
  testWidgets('save failure shows eating window error message', (tester) async {
    await tester.pumpWidget(
      _buildHarness(onSaveEatingWindow: (_, _) async => false),
    );

    await _openDialog(tester);

    await tester.tap(find.byKey(CalorieEatingWindowDialogKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.text('Could not update the eating window.'), findsOneWidget);
  });

  testWidgets('successful save closes dialog and passes selected values', (
    tester,
  ) async {
    int? savedStartMinuteOfDay;
    int? savedEndMinuteOfDay;

    await tester.pumpWidget(
      _buildHarness(
        onSaveEatingWindow: (startMinuteOfDay, endMinuteOfDay) async {
          savedStartMinuteOfDay = startMinuteOfDay;
          savedEndMinuteOfDay = endMinuteOfDay;
          return true;
        },
      ),
    );

    await _openDialog(tester);

    await tester.tap(find.byKey(CalorieEatingWindowDialogKeys.saveButton));
    await tester.pumpAndSettle();

    expect(find.text('Set eating window'), findsNothing);
    expect(savedStartMinuteOfDay, 6 * 60);
    expect(savedEndMinuteOfDay, 22 * 60);
  });

  testWidgets('change start action opens time picker and updates displayed time', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(onSaveEatingWindow: (_, _) async => true),
    );

    await _openDialog(tester);

    expect(find.text(_formattedTime(tester, 6 * 60)), findsOneWidget);
    expect(find.text(_formattedTime(tester, 22 * 60)), findsOneWidget);

    await _pickTime(
      tester,
      changeButtonKey: CalorieEatingWindowDialogKeys.changeStartButton,
      hour: '08',
      minute: '30',
    );

    expect(find.byType(TimePickerDialog), findsNothing);
    expect(find.text(_formattedTime(tester, (8 * 60) + 30)), findsOneWidget);
    expect(find.text(_formattedTime(tester, 22 * 60)), findsOneWidget);
  });

  testWidgets('change end action opens time picker', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(onSaveEatingWindow: (_, _) async => true),
    );

    await _openDialog(tester);

    await tester.tap(find.byKey(CalorieEatingWindowDialogKeys.changeEndButton));
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerDialog), findsOneWidget);
  });
}
