import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/meal_log_time_row.dart';
import 'package:yamt/l10n/app_localizations.dart';

final _today = DateTime(2026, 5, 13, 12, 30);

Widget _app(MealLogTimeRow row) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(child: SizedBox(width: 360, child: row)),
    ),
  );
}

MealLogTimeRow _row({
  DateTime? loggedAt,
  MealType mealType = MealType.breakfast,
  ValueChanged<DateTime>? onDayPicked,
  ValueChanged<MealType>? onMealTypeChanged,
}) {
  return MealLogTimeRow(
    loggedAt: loggedAt ?? _today,
    today: _today,
    mealType: mealType,
    onDayPicked: onDayPicked ?? (_) {},
    onMealTypeChanged: onMealTypeChanged ?? (_) {},
  );
}

void main() {
  testWidgets('shows only the calendar icon for today', (tester) async {
    await tester.pumpWidget(_app(_row()));

    expect(find.byKey(MealLogTimeRow.dayCompactKey), findsOneWidget);
    expect(find.byKey(MealLogTimeRow.dayLabeledKey), findsNothing);
  });

  testWidgets('shows the date for another day', (tester) async {
    await tester.pumpWidget(_app(_row(loggedAt: DateTime(2026, 4, 30, 9))));

    expect(find.byKey(MealLogTimeRow.dayCompactKey), findsNothing);
    expect(find.byKey(MealLogTimeRow.dayLabeledKey), findsOneWidget);
    final context = tester.element(find.byType(MealLogTimeRow));
    expect(
      find.text(
        MaterialLocalizations.of(context)
            .formatMediumDate(DateTime(2026, 4, 30)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('picks a day up to today', (tester) async {
    DateTime? pickedDay;
    await tester.pumpWidget(_app(_row(onDayPicked: (day) => pickedDay = day)));

    await tester.tap(find.byKey(MealLogTimeRow.dayButtonKey));
    await tester.pumpAndSettle();

    final picker = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(picker.lastDate, DateTime(2026, 5, 13));
    expect(picker.firstDate, DateTime(2000));

    await tester.tap(find.text('10'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(pickedDay, DateTime(2026, 5, 10));
  });

  testWidgets('cancelling the date picker keeps the day', (tester) async {
    var pickCount = 0;
    await tester.pumpWidget(_app(_row(onDayPicked: (_) => pickCount += 1)));

    await tester.tap(find.byKey(MealLogTimeRow.dayButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(pickCount, 0);
  });

  testWidgets('reports the selected meal type', (tester) async {
    MealType? selected;
    await tester.pumpWidget(
      _app(_row(onMealTypeChanged: (value) => selected = value)),
    );

    await tester.tap(find.byType(DropdownButton<MealType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinner').last);
    await tester.pumpAndSettle();

    expect(selected, MealType.dinner);
  });
}
