import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/kochmodus/application/cook_run_shopping_service.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/recipes_exceptions.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_names_service.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../../shoppinglist/support/fake_shopping_list_repository.dart';
import '../kochmodus_fixtures.dart';
import 'cook_services_harness.dart';

void main() {
  late CookHarness harness;
  late FakeShoppingListRepository list;
  late CookRunShoppingService service;

  setUp(() async {
    harness = await CookHarness.open();
    list = FakeShoppingListRepository();
    addTearDown(list.dispose);
    service = CookRunShoppingService(
      runs: harness.runs,
      shopping: ShoppingListNamesService(list),
      parser: const TemplateIngredientParser(),
    );
  });

  CookRun run() => buildCookRun(
    lines: [
      textLine('line-0', '200 g Reis', settlement: const LineShopping()),
      textLine('line-1', 'Salz'),
      textLine('line-2', 'Zwiebeln', settlement: const LineShopping()),
      textLine('line-3', 'Pfeffer', settlement: const LineIgnored()),
    ],
  );

  test('puts the shopping lines on the list, then pauses the run', () async {
    await harness.start(run());

    await service.pause('recipe-t1');
    await harness.settle();

    final names = (await list.readAll()).map(_shown).toList();
    expect(names, hasLength(2));
    expect(names.join(' '), allOf(contains('Reis'), contains('Zwiebeln')));
    expect(names.join(' '), isNot(contains('Salz')));
    expect(names.join(' '), isNot(contains('Pfeffer')));
    expect((await harness.storedRun('recipe-t1'))!.step, CookRunStep.paused);
  });

  test('lists what this cooking needs: scaled, or the own amount', () async {
    await harness.start(
      buildCookRun(
        portions: 8,
        lines: [
          textLine('line-0', '200 g Sahne', settlement: const LineShopping()),
          textLine(
            'line-1',
            '100 g Butter',
            amount: 500,
            amountPortions: 8,
            settlement: const LineShopping(),
          ),
          textLine('line-2', 'Zwiebeln', settlement: const LineShopping()),
        ],
      ),
    );

    await service.pause('recipe-t1');
    await harness.settle();

    final names = (await list.readAll()).map(_shown).join('|');
    expect(names, contains('400 g Sahne'));
    expect(names, contains('500 g Butter'));
    expect(names, contains('Zwiebeln'));
    expect(names, isNot(contains('200 g')));
  });

  test('an own amount for other portions is scaled on the list', () async {
    await harness.start(
      buildCookRun(
        portions: 6,
        lines: [
          textLine(
            'line-0',
            '100 g Butter',
            amount: 100,
            amountPortions: 3,
            settlement: const LineShopping(),
          ),
        ],
      ),
    );

    await service.pause('recipe-t1');
    await harness.settle();

    final names = (await list.readAll()).map(_shown).join('|');
    expect(names, contains('200 g Butter'));
    expect(names, isNot(contains('100 g')));
  });

  test('a line reads on the list as it does on the page', () async {
    await harness.start(
      buildCookRun(
        lines: [
          textLine('line-0', '2 Zwiebeln', settlement: const LineShopping()),
          textLine('line-1', '2 EL Öl', settlement: const LineShopping()),
          textLine('line-2', '1/2 Zitrone', settlement: const LineShopping()),
          textLine('line-3', 'eine Paprika', settlement: const LineShopping()),
          textLine(
            'line-4',
            '2 Dosen Tomaten (à 400 g)',
            settlement: const LineShopping(),
          ),
        ],
      ),
    );

    await service.pause('recipe-t1');
    await harness.settle();

    final names = (await list.readAll()).map(_shown).toSet();
    expect(names, {
      '2 Zwiebeln',
      '2 EL Öl',
      '1/2 Zitrone',
      'Paprika',
      '800 g Tomaten',
    });
  });

  test('the pieces the cook typed stay pieces on the list', () async {
    await harness.start(
      buildCookRun(
        lines: [
          textLine(
            'line-0',
            'Eier',
            amount: 3,
            amountUnit: TemplateIngredientUnit.piece,
            settlement: const LineShopping(),
          ),
        ],
      ),
    );

    await service.pause('recipe-t1');
    await harness.settle();

    final names = (await list.readAll()).map(_shown).toList();
    expect(names, ['3 Eier']);
  });

  test('a line the cook typed goes on the list as typed', () async {
    await harness.start(
      buildCookRun(
        portions: 8,
        lines: [
          textLine(
            'line-0',
            '100 g Feta',
            origin: CookLineOrigin.added,
            settlement: const LineShopping(),
          ),
        ],
      ),
    );

    await service.pause('recipe-t1');
    await harness.settle();

    final names = (await list.readAll()).map(_shown).toList();
    expect(names, ['100 g Feta']);
  });

  test('keeps the lines of the run as they were', () async {
    await harness.start(run());

    await service.pause('recipe-t1');
    await harness.settle();

    expect((await harness.storedRun('recipe-t1'))!.lines, run().lines);
  });

  test('a failed list write leaves the run open and rethrows', () async {
    await harness.start(run());
    list.saveAllShouldThrow = true;

    await expectLater(service.pause('recipe-t1'), throwsStateError);
    await harness.settle();

    expect((await harness.storedRun('recipe-t1'))!.step, CookRunStep.assign);
  });

  test('a list that is not saved leaves the run open and throws', () async {
    await harness.start(run());
    list.saveAllShouldFail = true;

    await expectLater(service.pause('recipe-t1'), throwsStateError);
    await harness.settle();

    expect((await harness.storedRun('recipe-t1'))!.step, CookRunStep.assign);
  });

  test('without a shopping line it only pauses, the list stays', () async {
    await harness.start(buildCookRun(lines: [textLine('line-0', 'Salz')]));

    await service.pause('recipe-t1');
    await harness.settle();

    expect(list.savedItems, isEmpty);
    expect((await harness.storedRun('recipe-t1'))!.step, CookRunStep.paused);
  });

  test('waits for the writes of the run that are still queued', () async {
    await harness.start(run());
    // Not awaited: pause must see the line this change settles.
    final change = harness.runs.mutate(
      'recipe-t1',
      (run) => run.copyWith(
        lines: [
          for (final line in run.lines)
            if (line.id == 'line-1')
              line.copyWith(settlement: const LineShopping())
            else
              line,
        ],
      ),
    );

    await service.pause('recipe-t1');
    await change;

    final names = (await list.readAll()).map(_shown).join(' ');
    expect(names, contains('Salz'));
  });

  test('a run that is gone throws and writes no list', () async {
    await expectLater(
      service.pause('recipe-t1'),
      throwsA(isA<CookRunGoneException>()),
    );

    expect(list.savedItems, isEmpty);
  });
}

// An entry as the list shows it: the amount note or the count in front of
// the product.
String _shown(ShoppingListItem item) => [
  ?item.note,
  if (item.note == null && item.quantity > 1) '${item.quantity}',
  item.name,
].join(' ');
