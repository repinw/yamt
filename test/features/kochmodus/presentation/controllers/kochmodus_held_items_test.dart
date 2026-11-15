import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_picker_offers.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';

import '../../../recipes/cook_run_fixtures.dart';
import '../../kochmodus_fixtures.dart';

KochmodusView _view(
  CookRun run,
  List<InventoryItem> items, {
  Map<String, int> others = const {},
}) => buildKochmodusView(
  run: run,
  saved: true,
  ended: false,
  busy: false,
  reopened: false,
  finished: null,
  tab: null,
  items: items,
  otherReservations: others,
  utensils: const [],
  parser: const TemplateIngredientParser(),
);

InventoryItem _rice(String id, int amount) =>
    stockItem(id, amount).copyWith(name: 'Reis');

InventoryItem _pepper(String id, int amount) =>
    stockItem(id, amount).copyWith(name: 'Pfeffer');

void main() {
  final run = buildCookRun(lines: [textLine('a', '300 g Reis')]);

  group('kochmodusHeldItemIds', () {
    test('an item that another cooking holds completely is held', () {
      final view = _view(
        run,
        [_rice('i1', 500), _rice('i2', 500)],
        others: const {'i1': 500},
      );

      expect(kochmodusHeldItemIds(view, 'a'), {'i1'});
    });

    test('an item with something left for the line is not held', () {
      final view = _view(run, [_rice('i1', 500)], others: const {'i1': 200});

      expect(kochmodusHeldItemIds(view, 'a'), isEmpty);
    });

    test('an item that another line of this run takes is held', () {
      final twoLines = buildCookRun(
        lines: [
          textLine('a', '300 g Reis'),
          textLine(
            'b',
            '500 g Reis',
            amount: 500,
            settlement: assigned({'i1': 500}),
          ),
        ],
      );
      final view = _view(twoLines, [_rice('i1', 500)]);

      expect(kochmodusHeldItemIds(view, 'a'), {'i1'});
    });

    test('a line without a need holds nothing back, whatever is taken', () {
      final spice = buildCookRun(lines: [textLine('a', 'Pfeffer')]);
      final view = _view(
        spice,
        [_pepper('i1', 100)],
        others: const {'i1': 100},
      );

      expect(kochmodusHeldItemIds(view, 'a'), isEmpty);
      expect(kochmodusOffers(view, 'a').single.held, isFalse);
    });

    test('a line that is gone holds nothing', () {
      final view = _view(run, [_rice('i1', 500)], others: const {'i1': 500});

      expect(kochmodusHeldItemIds(view, 'nope'), isEmpty);
    });
  });

  group('kochmodusItemHolders', () {
    CookRun holder(String id, String name, Map<String, int> takes) {
      final base = buildCookRun(
        id: id,
        lines: [
          textLine(
            'x',
            '1 Zeile',
            amount: 1,
            settlement: takes.isEmpty ? const LineOpen() : assigned(takes),
          ),
        ],
      );
      return CookRun(
        id: base.id,
        kind: base.kind,
        step: base.step,
        recipeId: base.recipeId,
        name: name,
        imageAssetId: null,
        imageUrl: null,
        basePortions: base.basePortions,
        portions: base.portions,
        steps: base.steps,
        startedBy: base.startedBy,
        startedByName: base.startedByName,
        startedAt: base.startedAt,
        lines: base.lines,
        pots: null,
        withGuide: false,
        guideStep: 0,
        timers: const [],
        meals: const [],
        toCookbook: false,
        droppedItemIds: const [],
      );
    }

    test('names the other cooking that takes each item', () {
      final holders = kochmodusItemHolders([
        holder('r1', 'Pfannkuchen', {'i1': 200}),
        holder('r2', 'Suppe', {'i2': 100}),
      ], 'r2');

      expect(holders, {'i1': 'Pfannkuchen'});
    });

    test('names the first cooking when two take the same item', () {
      final holders = kochmodusItemHolders([
        holder('r1', 'Pfannkuchen', {'i1': 200}),
        holder('r2', 'Suppe', {'i1': 100}),
        holder('r3', 'Auflauf', {}),
      ], 'r3');

      expect(holders, {'i1': 'Pfannkuchen'});
    });

    test('skips a cooking with a blank name', () {
      final holders = kochmodusItemHolders([
        holder('r1', '  ', {'i1': 200}),
        holder('r2', 'Suppe', {'i1': 100}),
      ], 'r3');

      expect(holders, {'i1': 'Suppe'});
    });

    test('has no holder when the only cooking has a blank name', () {
      final holders = kochmodusItemHolders([
        holder('r1', '', {'i1': 200}),
      ], 'r3');

      expect(holders, isEmpty);
    });

    test('skips an item the other cooking takes none of', () {
      final holders = kochmodusItemHolders([
        holder('r1', 'Pfannkuchen', {'i1': 0}),
      ], 'r2');

      expect(holders, isEmpty);
    });
  });
}
