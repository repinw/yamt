// The field of one day in the week card (#911): kcal bar of a finished day
// (K16), coming day (K17), pause day (K18), empty day (K25), the pieces of
// the carryover (K21), the frame (K15) and the colours (K23).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_week_card_constants.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_week_balance.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_day_bar.dart';

final DateTime _monday = DateTime(2026, 11, 16);

/// Thursday, today in these tests.
final DateTime _today = addLocalDays(_monday, 3);

const _width = 100.0;
const _barKey = ValueKey<String>('bar');

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
  CalorieGoalMode weightGoal = CalorieGoalMode.lose,
  WeekBalanceMode mode = WeekBalanceMode.show,
  bool isShown = false,
  double width = _width,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          height: 14,
          child: DiaryWeekDayBar(
            key: _barKey,
            day: day,
            balance: WeekBalance(
              mode: mode,
              weightGoal: weightGoal,
              days: [day],
            ),
            today: _today.add(const Duration(hours: 10)),
            isShown: isShown,
          ),
        ),
      ),
    ),
  ),
);

double _widthOf(WidgetTester tester, Key key) =>
    tester.getSize(find.byKey(key)).width;

Color _error(WidgetTester tester) =>
    Theme.of(tester.element(find.byKey(_barKey))).colorScheme.error;

/// The colours that boxes inside the field are filled with.
Iterable<Color?> _fills(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byKey(_barKey),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((box) => (box.decoration as BoxDecoration).color);

void main() {
  group('K16: a finished day is its kcal bar', () {
    testWidgets('a day under its budget keeps an empty tip and no red', (
      tester,
    ) async {
      await _pump(tester, _dayOn(1, eaten: 1900));

      expect(
        _widthOf(tester, DiaryWeekCardKeys.eatenPart),
        closeTo(_width * 1900 / 2200, 0.5),
      );
      expect(find.byKey(DiaryWeekCardKeys.overPart), findsNothing);
      expect(_fills(tester), isNot(contains(_error(tester))));
    });

    testWidgets('a day over its budget shows the whole day, only the part '
        'above the budget red', (tester) async {
      await _pump(tester, _dayOn(1, eaten: 6750));

      // About two thirds red (6.750 eaten at 2.200).
      final over = _widthOf(tester, DiaryWeekCardKeys.overPart);
      expect(over / _width, closeTo(4550 / 6750, 0.01));
      expect(
        _widthOf(tester, DiaryWeekCardKeys.eatenPart),
        closeTo(_width * 2200 / 6750, 0.5),
      );
      final overBox = tester.widget<DecoratedBox>(
        find.byKey(DiaryWeekCardKeys.overPart),
      );
      expect((overBox.decoration as BoxDecoration).color, _error(tester));
    });

    testWidgets('a training day is measured against its own budget', (
      tester,
    ) async {
      await _pump(tester, _dayOn(1, goal: 2450, eaten: 2450));

      expect(
        _widthOf(tester, DiaryWeekCardKeys.eatenPart),
        closeTo(_width, 0.5),
      );
      expect(find.byKey(DiaryWeekCardKeys.overPart), findsNothing);
    });
  });

  testWidgets('K17: a coming day is an empty dashed outline', (tester) async {
    await _pump(tester, _dayOn(5, hasEntries: false));

    expect(find.byKey(DiaryWeekCardKeys.comingOutline), findsOneWidget);
    expect(find.byKey(DiaryWeekCardKeys.eatenPart), findsNothing);
    expect(find.byKey(DiaryWeekCardKeys.overPart), findsNothing);
  });

  testWidgets('K18: a pause day is hatched, without a bar and without red', (
    tester,
  ) async {
    await _pump(tester, _dayOn(1, eaten: 3000, isPauseDay: true));

    expect(find.byKey(DiaryWeekCardKeys.pauseHatch), findsOneWidget);
    expect(find.byKey(DiaryWeekCardKeys.eatenPart), findsNothing);
    expect(find.byKey(DiaryWeekCardKeys.overPart), findsNothing);
    expect(_fills(tester), isNot(contains(_error(tester))));
  });

  testWidgets('K25: an empty day is an empty track, without fill or red', (
    tester,
  ) async {
    await _pump(tester, _dayOn(1, hasEntries: false));

    expect(find.byKey(DiaryWeekCardKeys.emptyTrack), findsOneWidget);
    expect(find.byKey(DiaryWeekCardKeys.eatenPart), findsNothing);
    expect(find.byKey(DiaryWeekCardKeys.overPart), findsNothing);
    expect(_fills(tester), isNot(contains(_error(tester))));
  });

  group('K21: the pieces of the carryover', () {
    testWidgets('less budget: a dark piece at the front as long as the '
        'carryover, red from the budget of the day on', (tester) async {
      // A day with −125: budget 2.075, and 2.275 eaten.
      await _pump(
        tester,
        _dayOn(1, eaten: 2275, carryover: -125),
        mode: WeekBalanceMode.carryover,
      );

      final debt = find.byKey(DiaryWeekCardKeys.debtPiece);
      expect(debt, findsOneWidget);
      final field = tester.getRect(find.byKey(_barKey));
      expect(tester.getRect(debt).left, closeTo(field.left, 0.5));
      // The field spans 125 + 2.275 = 2.400 kcal.
      expect(
        _widthOf(tester, DiaryWeekCardKeys.debtPiece),
        closeTo(_width * 125 / 2400, 0.5),
      );
      final over = find.byKey(DiaryWeekCardKeys.overPart);
      expect(
        tester.getRect(over).left - field.left,
        closeTo(_width * (125 + 2075) / 2400, 0.5),
      );
      expect(
        _widthOf(tester, DiaryWeekCardKeys.overPart),
        closeTo(_width * 200 / 2400, 0.5),
      );
    });

    testWidgets('more budget: a dashed piece at the end as long as the '
        'carryover', (tester) async {
      await _pump(
        tester,
        _dayOn(1, eaten: 1900, carryover: 350),
        mode: WeekBalanceMode.carryover,
      );

      final extra = find.byKey(DiaryWeekCardKeys.extraPiece);
      expect(extra, findsOneWidget);
      final field = tester.getRect(find.byKey(_barKey));
      expect(tester.getRect(extra).right, closeTo(field.right, 0.5));
      expect(
        _widthOf(tester, DiaryWeekCardKeys.extraPiece),
        closeTo(_width * 350 / 2550, 0.5),
      );
      expect(find.byKey(DiaryWeekCardKeys.debtPiece), findsNothing);
    });

    testWidgets('today and coming days show their piece too', (tester) async {
      await _pump(
        tester,
        _dayOn(3, eaten: 900, carryover: -125),
        mode: WeekBalanceMode.carryover,
      );
      expect(find.byKey(DiaryWeekCardKeys.debtPiece), findsOneWidget);

      await _pump(
        tester,
        _dayOn(5, hasEntries: false, carryover: 350),
        mode: WeekBalanceMode.carryover,
      );
      expect(find.byKey(DiaryWeekCardKeys.extraPiece), findsOneWidget);
    });

    testWidgets('without a carryover there is no piece', (tester) async {
      await _pump(tester, _dayOn(1, eaten: 3000));

      expect(find.byKey(DiaryWeekCardKeys.debtPiece), findsNothing);
      expect(find.byKey(DiaryWeekCardKeys.extraPiece), findsNothing);
    });
  });

  group('K23: weight goal "Zunehmen"', () {
    testWidgets('over is not red', (tester) async {
      await _pump(
        tester,
        _dayOn(1, eaten: 3000),
        weightGoal: CalorieGoalMode.gain,
      );

      final overBox = tester.widget<DecoratedBox>(
        find.byKey(DiaryWeekCardKeys.overPart),
      );
      expect(
        (overBox.decoration as BoxDecoration).color,
        isNot(_error(tester)),
      );
    });

    testWidgets('a finished day short of its budget is red', (tester) async {
      await _pump(
        tester,
        _dayOn(1, eaten: 1900),
        weightGoal: CalorieGoalMode.gain,
      );

      expect(_fills(tester), contains(_error(tester)));
    });

    testWidgets('today is never red for being under', (tester) async {
      await _pump(
        tester,
        _dayOn(3, eaten: 900),
        weightGoal: CalorieGoalMode.gain,
      );

      expect(_fills(tester), isNot(contains(_error(tester))));
    });
  });

  testWidgets('K15: the shown day has a frame, others none', (tester) async {
    await _pump(tester, _dayOn(1, eaten: 2200), isShown: true);
    expect(find.byKey(DiaryWeekCardKeys.frame), findsOneWidget);

    await _pump(tester, _dayOn(1, eaten: 2200));
    expect(find.byKey(DiaryWeekCardKeys.frame), findsNothing);
  });

  group('small pieces stay visible in a narrow field', () {
    // About the width of one of seven fields on a phone.
    const narrow = 40.0;

    testWidgets('an over part of 113 kcal at a budget of 2.099 is at least '
        'the least piece width', (tester) async {
      await _pump(tester, _dayOn(1, goal: 2099, eaten: 2212), width: narrow);

      expect(
        _widthOf(tester, DiaryWeekCardKeys.overPart),
        greaterThanOrEqualTo(AppWeekCard.minPieceWidth),
      );
    });

    testWidgets('a debt of −19 kcal is at least the least piece width', (
      tester,
    ) async {
      await _pump(
        tester,
        _dayOn(1, eaten: 1900, carryover: -19),
        mode: WeekBalanceMode.carryover,
        width: narrow,
      );

      expect(
        _widthOf(tester, DiaryWeekCardKeys.debtPiece),
        greaterThanOrEqualTo(AppWeekCard.minPieceWidth),
      );
    });

    testWidgets('an extra of 1 kcal is at least the least piece width', (
      tester,
    ) async {
      await _pump(
        tester,
        _dayOn(1, eaten: 1900, carryover: 1),
        mode: WeekBalanceMode.carryover,
        width: narrow,
      );

      final extra = find.byKey(DiaryWeekCardKeys.extraPiece);
      expect(extra, findsOneWidget);
      expect(
        _widthOf(tester, DiaryWeekCardKeys.extraPiece),
        greaterThanOrEqualTo(AppWeekCard.minPieceWidth),
      );
      expect(
        tester.getRect(extra).right,
        lessThanOrEqualTo(tester.getRect(find.byKey(_barKey)).right + 0.01),
      );
    });

    testWidgets('eaten, debt and over together fit into the field', (
      tester,
    ) async {
      // Budget 2.181 (2.200 − 19), 2.294 eaten: 113 over.
      await _pump(
        tester,
        _dayOn(1, eaten: 2294, carryover: -19),
        mode: WeekBalanceMode.carryover,
        width: narrow,
      );

      final field = tester.getRect(find.byKey(_barKey));
      final debt = tester.getRect(find.byKey(DiaryWeekCardKeys.debtPiece));
      final eaten = tester.getRect(find.byKey(DiaryWeekCardKeys.eatenPart));
      final over = tester.getRect(find.byKey(DiaryWeekCardKeys.overPart));
      expect(debt.width, greaterThanOrEqualTo(AppWeekCard.minPieceWidth));
      expect(over.width, greaterThanOrEqualTo(AppWeekCard.minPieceWidth));
      expect(
        debt.width + eaten.width + over.width,
        lessThanOrEqualTo(field.width + 0.01),
      );
      expect(over.right, lessThanOrEqualTo(field.right + 0.01));
      expect(eaten.right, lessThanOrEqualTo(over.left + 0.01));
    });
  });

  testWidgets('K15: the frame does not cover the parts; the framed field is '
      'as wide as an unframed one', (tester) async {
    final day = _dayOn(1, eaten: 2294, carryover: -19);
    await _pump(tester, day, mode: WeekBalanceMode.carryover);
    final unshownWidth = tester.getSize(find.byKey(_barKey)).width;

    await _pump(tester, day, mode: WeekBalanceMode.carryover, isShown: true);

    expect(find.byKey(DiaryWeekCardKeys.frame), findsOneWidget);
    final field = tester.getRect(find.byKey(_barKey));
    expect(field.width, unshownWidth);
    final inner = field.deflate(AppWeekCard.frameWidth);
    for (final key in [
      DiaryWeekCardKeys.overPart,
      DiaryWeekCardKeys.eatenPart,
      DiaryWeekCardKeys.debtPiece,
    ]) {
      final part = tester.getRect(find.byKey(key));
      expect(
        part.left,
        greaterThanOrEqualTo(inner.left - 0.01),
        reason: '$key',
      );
      expect(part.top, greaterThanOrEqualTo(inner.top - 0.01), reason: '$key');
      expect(part.right, lessThanOrEqualTo(inner.right + 0.01), reason: '$key');
      expect(
        part.bottom,
        lessThanOrEqualTo(inner.bottom + 0.01),
        reason: '$key',
      );
    }
  });
}
