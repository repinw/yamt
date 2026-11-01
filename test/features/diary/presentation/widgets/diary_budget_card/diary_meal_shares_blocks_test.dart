import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_meal_shares_blocks.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _blocksKey = ValueKey<String>('blocks');

/// What the blocks tell their parent, and the shares the parent holds.
class _Parent {
  new(this.shares);

  DiaryMealShares shares;
  final changed = <String>[];
  final ended = <String>[];
}

/// The blocks inside a parent that, like the editor, takes the shares it
/// is told of and builds again with them. As in the menu sheet, a vertical
/// drag (the sheet's own, to close it) competes with the blocks' horizontal
/// one, so a tap does not win the arena by default.
Future<_Parent> _pump(
  WidgetTester tester, {
  DiaryMealShares shares = DiaryMealShares.standard,
}) async {
  final parent = _Parent(shares);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: GestureDetector(
          onVerticalDragUpdate: (_) {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setState) => DiaryMealSharesBlocks(
                key: _blocksKey,
                shares: parent.shares,
                onChanged: (shares) {
                  parent.changed.add(shares.encode());
                  setState(() => parent.shares = shares);
                },
                onChangeEnd: (shares) {
                  parent.ended.add(shares.encode());
                  setState(() => parent.shares = shares);
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return parent;
}

/// Where [percent] of the day sits on the blocks.
Offset _at(WidgetTester tester, int percent) {
  final rect = tester.getRect(find.byKey(_blocksKey));
  const inset = AppBudgetCard.mealSharesHandle / 2;
  return Offset(
    rect.left + inset + percent / 100 * (rect.width - 2 * inset),
    rect.center.dy,
  );
}

SemanticsNode _border(String before, String after) => find.semantics
    .byLabel('Border between $before and $after')
    .evaluate()
    .single;

void main() {
  group('geometry', () {
    testWidgets('is as high as a tap target, with the blocks in its middle', (
      tester,
    ) async {
      await _pump(tester);

      expect(
        tester.getSize(find.byKey(_blocksKey)).height,
        AppSizes.minTapTarget,
      );
    });

    testWidgets('a tap changes nothing', (tester) async {
      final parent = await _pump(tester);

      await tester.tapAt(_at(tester, 25));
      await tester.pumpAndSettle();

      expect(parent.changed, isEmpty);
      expect(parent.ended, isEmpty);
    });
  });

  group('drag', () {
    testWidgets('moves the border as it is dragged and reports where it was '
        'let go', (tester) async {
      final parent = await _pump(tester);

      await tester.dragFrom(_at(tester, 25), _at(tester, 40) - _at(tester, 25));
      await tester.pumpAndSettle();

      expect(parent.changed.last, '40,20,30,10');
      expect(parent.ended, ['40,20,30,10']);
      expect(parent.shares.encode(), '40,20,30,10');
    });

    testWidgets('reports where it was let go when frames came between the '
        'moves, as in a slow drag', (tester) async {
      final parent = await _pump(tester);

      final gesture = await tester.startGesture(_at(tester, 25));
      for (final percent in [30, 35, 40]) {
        await gesture.moveTo(_at(tester, percent));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(parent.changed.last, '40,20,30,10');
      expect(parent.ended, ['40,20,30,10']);
    });

    testWidgets('reports where it was let go when it is let go in the frame '
        'of its last move, as in a quick flick', (tester) async {
      final parent = await _pump(tester);

      // No frame is built between the events of the gesture, so the parent
      // has not built the blocks again with the last move when it is let go.
      final gesture = await tester.startGesture(_at(tester, 25));
      await gesture.moveTo(_at(tester, 30));
      await gesture.moveTo(_at(tester, 45));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(parent.ended, ['45,15,30,10']);
      expect(parent.shares.encode(), '45,15,30,10');
    });

    testWidgets('a border pushed onto the next leaves the meal between at '
        '0', (tester) async {
      final parent = await _pump(tester);

      await tester.dragFrom(_at(tester, 60), _at(tester, 99) - _at(tester, 60));
      await tester.pumpAndSettle();

      expect(parent.ended, ['25,65,0,10']);
    });

    testWidgets('a drag from the edge brings back a meal at 0', (tester) async {
      final parent = await _pump(
        tester,
        shares: const DiaryMealShares([0, 60, 30, 10]),
      );

      await tester.dragFrom(_at(tester, 0), _at(tester, 20) - _at(tester, 0));
      await tester.pumpAndSettle();

      expect(parent.ended, ['20,40,30,10']);
    });

    for (final (direction, to, ended) in [
      ('left', 50, '25,25,10,40'),
      ('right', 70, '25,35,10,30'),
    ]) {
      testWidgets('a drag to the $direction takes the border of two on one '
          'spot that lies that way', (tester) async {
        final parent = await _pump(
          tester,
          shares: const DiaryMealShares([25, 35, 0, 40]),
        );

        await tester.dragFrom(
          _at(tester, 60),
          _at(tester, to) - _at(tester, 60),
        );
        await tester.pumpAndSettle();

        expect(parent.ended, [ended]);
      });
    }
  });

  group('for a screen reader', () {
    testWidgets('each border is a slider named for the meals it splits, '
        'with their shares as its value', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);

      final borders = find.semantics
          .byLabel(RegExp('^Border between'))
          .evaluate()
          .toList();
      expect(borders, hasLength(3));
      for (final border in borders) {
        expect(border.getSemanticsData().flagsCollection.isSlider, isTrue);
      }
      expect(_border('Breakfast', 'Lunch').value, '25 % / 35 %');
      expect(_border('Lunch', 'Dinner').value, '35 % / 30 %');
      expect(_border('Dinner', 'Snack').value, '30 % / 10 %');

      semantics.dispose();
    });

    testWidgets('says what a step up or down would make of the shares', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);

      final border = _border('Breakfast', 'Lunch');

      expect(border.increasedValue, '30 % / 30 %');
      expect(border.decreasedValue, '20 % / 40 %');

      semantics.dispose();
    });

    testWidgets('increasing a border moves it by 5 percent and saves it', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final parent = await _pump(tester);

      tester.semantics.increase(
        find.semantics.byLabel('Border between Breakfast and Lunch'),
      );
      await tester.pumpAndSettle();

      expect(parent.ended, ['30,30,30,10']);
      expect(_border('Breakfast', 'Lunch').value, '30 % / 30 %');

      tester.semantics.increase(
        find.semantics.byLabel('Border between Dinner and Snack'),
      );
      await tester.pumpAndSettle();

      expect(parent.ended, ['30,30,30,10', '30,30,35,5']);

      semantics.dispose();
    });

    testWidgets('decreasing a border moves it by 5 percent and saves it', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final parent = await _pump(tester);

      tester.semantics.decrease(
        find.semantics.byLabel('Border between Lunch and Dinner'),
      );
      await tester.pumpAndSettle();

      expect(parent.ended, ['25,30,35,10']);
      expect(_border('Lunch', 'Dinner').value, '30 % / 35 %');
      // The step reports no drag.
      expect(parent.changed, isEmpty);

      semantics.dispose();
    });

    testWidgets('a border at the edge of the day cannot step past it', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, shares: const DiaryMealShares([0, 60, 30, 10]));

      final first = _border('Breakfast', 'Lunch').getSemanticsData();
      expect(first.hasAction(SemanticsAction.decrease), isFalse);
      expect(first.hasAction(SemanticsAction.increase), isTrue);

      semantics.dispose();
    });

    testWidgets('a border at the end of the day cannot step past it', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, shares: const DiaryMealShares([25, 35, 40, 0]));

      final last = _border('Dinner', 'Snack').getSemanticsData();
      expect(last.hasAction(SemanticsAction.increase), isFalse);
      expect(last.hasAction(SemanticsAction.decrease), isTrue);

      semantics.dispose();
    });

    testWidgets('a border cannot step past the border of a meal that is '
        'off', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, shares: const DiaryMealShares([25, 35, 0, 40]));

      // Both borders of the dinner at 0 sit at 60 %: the first can only go
      // back, the second only forward.
      final before = _border('Lunch', 'Dinner').getSemanticsData();
      expect(before.hasAction(SemanticsAction.increase), isFalse);
      expect(before.hasAction(SemanticsAction.decrease), isTrue);
      final after = _border('Dinner', 'Snack').getSemanticsData();
      expect(after.hasAction(SemanticsAction.increase), isTrue);
      expect(after.hasAction(SemanticsAction.decrease), isFalse);

      semantics.dispose();
    });

    testWidgets('a step at a limit changes and saves nothing', (tester) async {
      final semantics = tester.ensureSemantics();
      final parent = await _pump(
        tester,
        shares: const DiaryMealShares([0, 60, 30, 10]),
      );

      expect(
        () => tester.semantics.decrease(
          find.semantics.byLabel('Border between Breakfast and Lunch'),
        ),
        throwsStateError,
      );
      expect(parent.ended, isEmpty);

      semantics.dispose();
    });

    testWidgets('names the borders in German', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DiaryMealSharesBlocks(
              shares: DiaryMealShares.standard,
              onChanged: (_) {},
              onChangeEnd: (_) {},
            ),
          ),
        ),
      );

      final border = find.semantics
          .byLabel('Grenze zwischen Frühstück und Mittagessen')
          .evaluate()
          .single;
      expect(border.value, '25 % / 35 %');

      semantics.dispose();
    });
  });
}
