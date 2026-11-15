import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_view_builder.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../../recipes/cook_run_fixtures.dart';
import '../../kochmodus_fixtures.dart';

const _steps = [
  'Milch mit Salz aufkochen.',
  'Milchreis dazugeben und 30 Minuten leise kochen.',
  'Mit Zucker, Zimt und Zitrone abschmecken.',
];

// The recipe of the walkthrough, written for the run's 4 base portions.
List<CookRunLine> _lines({
  LineSettlement salt = const LineOpen(),
  LineSettlement cinnamon = const LineOpen(),
}) => [
  textLine('milk', '1 l Milch'),
  textLine('rice', '250 g Milchreis'),
  textLine('sugar', '2 EL Zucker'),
  textLine('cinnamon', '1 TL Zimt', settlement: cinnamon),
  textLine('salt', '1 Prise Salz', settlement: salt),
  textLine('lemon', '1/2 Zitrone'),
];

KochmodusView _view(
  List<CookRunLine> lines, {
  int portions = 4,
  List<String> steps = _steps,
}) => buildKochmodusView(
  run: buildCookRun(
    pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
    steps: steps,
    lines: lines,
    portions: portions,
  ),
  saved: true,
  ended: false,
  busy: false,
  reopened: false,
  finished: null,
  tab: null,
  items: const <InventoryItem>[],
  otherReservations: const {},
  utensils: const [],
  parser: const TemplateIngredientParser(),
);

List<(String, String?, String)> _foods(KochmodusGuideLine line) => [
  for (final food in line.foods) (food.lineId, food.amount, food.food),
];

void main() {
  test('each step lists the lines it names with their amounts', () {
    final view = _view(_lines());

    expect(_foods(view.guide[0]), [
      ('milk', '1000 ml', 'Milch'),
      ('salt', '1 Prise', 'Salz'),
    ]);
    // "Milchreis", not "Milch".
    expect(_foods(view.guide[1]), [('rice', '250 g', 'Milchreis')]);
    expect(_foods(view.guide[2]), [
      ('sugar', '2 EL', 'Zucker'),
      ('cinnamon', '1 TL', 'Zimt'),
      ('lemon', '1/2', 'Zitrone'),
    ]);
  });

  test('a line the cook left out is skipped', () {
    final view = _view(_lines(cinnamon: const LineIgnored()));

    expect(view.guide[2].foods.map((food) => food.lineId), ['sugar', 'lemon']);
  });

  test('a line that does not count, such as salt, stays', () {
    final view = _view(_lines(salt: const LineIgnored()));

    expect(view.lines.firstWhere((line) => line.id == 'salt').notCounted, true);
    expect(view.guide[0].foods.map((food) => food.lineId), ['milk', 'salt']);
  });

  test('the amounts follow the portions of the run', () {
    final view = _view(_lines(), portions: 8);

    expect(_foods(view.guide[0]).first, ('milk', '2000 ml', 'Milch'));
    expect(_foods(view.guide[1]), [('rice', '500 g', 'Milchreis')]);
  });

  test('a step that names no line has no foods', () {
    final view = _view(_lines(), steps: const ['Alles gut umrühren.']);

    expect(view.guide.single.foods, isEmpty);
  });

  group('a line names its food, not the phrase behind it', () {
    List<String> foodsOf(String line, String step) => [
      for (final food in _view(
        [textLine('l', line)],
        steps: [step],
      ).guide.single.foods)
        food.lineId,
    ];

    test('"Olivenöl zum Braten" is no food of a frying step', () {
      expect(
        foodsOf(
          '1 EL Olivenöl zum Braten',
          'Das Hackfleisch in der Pfanne krümelig braten.',
        ),
        isEmpty,
      );
    });

    test(
      '"Olivenöl zum Braten" is the food of the step that heats the oil',
      () {
        expect(foodsOf('1 EL Olivenöl zum Braten', 'Das Olivenöl erhitzen.'), [
          'l',
        ]);
      },
    );
  });
}
