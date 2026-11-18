// The strip of the week card (#911) for a run that a new goal cut short:
// K14 and K47 of lib/features/diary/CRITERIA.md.
//
// How fewer than seven fields fill the card is "Phone only" in K47 and
// decided by no criterion. The width test pins the layout that was built
// (01ee64879): each field keeps the width it has in a strip of seven and the
// fields start at the left.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_week_card_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_week_balance.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_card.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Monday, the first day of the run.
final DateTime _monday = DateTime(2026, 11, 16);

/// Tuesday, the shown day.
final DateTime _tuesday = addLocalDays(_monday, 1);

WeekBalance _balance(int dayCount) => WeekBalance(
  mode: WeekBalanceMode.carryover,
  weightGoal: CalorieGoalMode.lose,
  days: [
    for (var index = 0; index < dayCount; index += 1)
      WeekBalanceDay(
        date: addLocalDays(_monday, index),
        goalKcal: 2200,
        eatenKcal: 2200,
        hasEntries: true,
        isPauseDay: false,
        carryoverKcal: 0,
      ),
  ],
);

/// Pumps the week card of Tuesday with [balance] at a width of 360.
Future<void> _pump(WidgetTester tester, WeekBalance balance) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Thursday of the run is today.
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 19, 10)),
        diaryWeekBalanceProvider(_tuesday).overrideWithValue(balance),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 360, child: DiaryWeekCard(day: _tuesday)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Rect _rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

Finder get _row => find.descendant(
  of: find.byKey(DiaryWeekCardKeys.card),
  matching: find.byType(Row),
);

void main() {
  testWidgets('K47: a run cut short to three days has the fields 0 to 2 and '
      'no field 3', (tester) async {
    await _pump(tester, _balance(3));

    for (var index = 0; index < 3; index += 1) {
      expect(find.byKey(DiaryWeekCardKeys.day(index)), findsOneWidget);
    }
    expect(find.byKey(DiaryWeekCardKeys.day(3)), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('K14/K47: each of three fields is one seventh of the row wide '
      'and they start at the left', (tester) async {
    await _pump(tester, _balance(7));
    final seven = [
      for (var index = 0; index < 3; index += 1)
        _rectOf(tester, find.byKey(DiaryWeekCardKeys.day(index))),
    ];

    await _pump(tester, _balance(3));
    final row = _rectOf(tester, _row.first);
    final oneSeventh = (row.width - 6 * AppWeekCard.fieldGap) / 7;

    for (var index = 0; index < 3; index += 1) {
      final field = _rectOf(tester, find.byKey(DiaryWeekCardKeys.day(index)));
      expect(field.width, moreOrLessEquals(oneSeventh), reason: 'field $index');
      expect(field.width, moreOrLessEquals(seven[index].width));
      expect(field.left, moreOrLessEquals(seven[index].left));
    }
    expect(
      _rectOf(tester, find.byKey(DiaryWeekCardKeys.day(0))).left,
      moreOrLessEquals(row.left),
      reason: 'the fields start at the left of the row',
    );
  });
}
