// One day field of the week card (#911): its name (K15, K28), the number
// under it (K19, K20) and the colours of the number (K22, K23).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_week_balance.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_day_field.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Monday, the first day of the run.
final DateTime _monday = DateTime(2026, 11, 16);

/// Thursday, today in these tests.
final DateTime _today = addLocalDays(_monday, 3);

WeekBalanceDay _dayOn(
  int index, {
  double goal = 2200,
  double eaten = 0,
  bool hasEntries = true,
  bool isPauseDay = false,
  double carryover = 0,
}) => WeekBalanceDay(
  date: addLocalDays(_monday, index),
  goalKcal: goal,
  eatenKcal: eaten,
  hasEntries: hasEntries,
  isPauseDay: isPauseDay,
  carryoverKcal: carryover,
);

Future<void> _pump(
  WidgetTester tester,
  WeekBalanceDay day, {
  int? index,
  bool showNumber = true,
  CalorieGoalMode weightGoal = CalorieGoalMode.lose,
  WeekBalanceMode mode = WeekBalanceMode.show,
  DateTime? today,
}) {
  final position = index ?? day.date.difference(_monday).inDays;
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 48,
            child: DiaryWeekDayField(
              index: position,
              day: day,
              balance: WeekBalance(
                mode: mode,
                weightGoal: weightGoal,
                days: [day],
              ),
              today: today ?? _today.add(const Duration(hours: 10)),
              isShown: false,
              showNumber: showNumber,
            ),
          ),
        ),
      ),
    ),
  );
}

String? _number(WidgetTester tester, int index) {
  final finder = find.byKey(DiaryWeekCardKeys.dayNumber(index));
  return finder.evaluate().isEmpty ? null : tester.widget<Text>(finder).data;
}

Color? _numberColor(WidgetTester tester, int index) => tester
    .widget<Text>(find.byKey(DiaryWeekCardKeys.dayNumber(index)))
    .style
    ?.color;

Color _error(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(DiaryWeekDayField))).colorScheme.error;

void main() {
  group('K15: day names', () {
    testWidgets('a past day is named by its short weekday', (tester) async {
      await _pump(tester, _dayOn(0, eaten: 2200));

      expect(
        tester.widget<Text>(find.byKey(DiaryWeekCardKeys.dayName(0))).data,
        'Mo',
      );
    });

    testWidgets('today is "Heute" in bold', (tester) async {
      await _pump(tester, _dayOn(3, eaten: 900));

      final name = tester.widget<Text>(
        find.byKey(DiaryWeekCardKeys.dayName(3)),
      );
      expect(name.data, 'Heute');
      expect(name.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('K28: a day of a run before today is never "Heute"', (
      tester,
    ) async {
      await _pump(
        tester,
        _dayOn(3, eaten: 900),
        today: addLocalDays(_today, 7),
      );

      expect(
        tester.widget<Text>(find.byKey(DiaryWeekCardKeys.dayName(3))).data,
        'Do',
      );
    });
  });

  group('K20: the number under a finished day', () {
    final rows = <(String, WeekBalanceDay, String?)>[
      ('2.200 / 3.000', _dayOn(0, eaten: 3000), '+800'),
      ('2.200 / 6.750', _dayOn(0, eaten: 6750), '+4.550'),
      ('2.200 / 1.900', _dayOn(0, eaten: 1900), '−300'),
      ('2.200 / 2.250', _dayOn(0, eaten: 2250), '+50'),
      ('2.200 / 2.150', _dayOn(0, eaten: 2150), '−50'),
      ('2.200 / 2.230', _dayOn(0, eaten: 2230), null),
      ('2.200 / 2.200', _dayOn(0, eaten: 2200), null),
      ('pause day', _dayOn(0, eaten: 3000, isPauseDay: true), 'Pause'),
      ('no entries', _dayOn(0, hasEntries: false), 'leer'),
      (
        'Mit Übertrag 2.260 / 3.000',
        _dayOn(0, eaten: 3000, carryover: 60),
        '+740',
      ),
      (
        'Mit Übertrag 1.850 / 1.850',
        _dayOn(0, eaten: 1850, carryover: -350),
        null,
      ),
      (
        'Mit Übertrag 1.850 / 2.200',
        _dayOn(0, eaten: 2200, carryover: -350),
        '+350',
      ),
    ];
    for (final (row, day, shown) in rows) {
      testWidgets('K20: $row shows ${shown ?? 'nothing'}', (tester) async {
        await _pump(
          tester,
          day,
          mode: day.carryoverKcal == 0
              ? WeekBalanceMode.show
              : WeekBalanceMode.carryover,
        );

        expect(_number(tester, 0), shown);
      });
    }
  });

  group('K19: numbers only with "Details" and only under finished days', () {
    testWidgets('no number while "Details" is closed', (tester) async {
      await _pump(tester, _dayOn(0, eaten: 3000), showNumber: false);

      expect(_number(tester, 0), isNull);
    });

    testWidgets('no number under today', (tester) async {
      await _pump(tester, _dayOn(3, eaten: 3000));

      expect(_number(tester, 3), isNull);
    });

    testWidgets('no number under a coming day', (tester) async {
      await _pump(tester, _dayOn(5, hasEntries: false));

      expect(_number(tester, 5), isNull);
    });
  });

  group('K22/K23: colours follow the weight goal', () {
    for (final goal in [CalorieGoalMode.lose, CalorieGoalMode.maintain]) {
      testWidgets('K22 (${goal.name}): "+800" is red, "−300" is grey', (
        tester,
      ) async {
        await _pump(tester, _dayOn(0, eaten: 3000), weightGoal: goal);
        expect(_numberColor(tester, 0), _error(tester));

        await _pump(tester, _dayOn(0, eaten: 1900), weightGoal: goal);
        expect(_numberColor(tester, 0), isNot(_error(tester)));
        expect(_numberColor(tester, 0), FoodLabelColors.light.muted);
      });
    }

    testWidgets('K23 (gain): "+800" is not red, "−300" is red', (tester) async {
      await _pump(
        tester,
        _dayOn(0, eaten: 3000),
        weightGoal: CalorieGoalMode.gain,
      );
      expect(_numberColor(tester, 0), isNot(_error(tester)));

      await _pump(
        tester,
        _dayOn(0, eaten: 1900),
        weightGoal: CalorieGoalMode.gain,
      );
      expect(_numberColor(tester, 0), _error(tester));
    });
  });
}
