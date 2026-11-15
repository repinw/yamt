import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_finish_check.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';

const _potC = CookPot(
  id: 'pot-c',
  name: null,
  emptyWeight: 500,
  imageStoragePath: null,
);

CookPotChoice _pots(List<CookPot> pots) =>
    CookPotsChosen(pots: pots, inCans: false);

CookMealDraft _meal(String potId, int? gross) => CookMealDraft(
  potId: potId,
  name: 'Eintopf',
  count: 4,
  inPieces: false,
  grossWeight: gross,
);

CookRunLine _taking(String id, Map<String, int> takes, {String? potId}) =>
    cookLine(id, settlement: assigned(takes), potId: potId);

void main() {
  List<CookFinishBlock> blocks(
    List<CookRunLine> lines,
    List<InventoryItem> items, {
    CookPotChoice? pots,
    List<CookMealDraft> meals = const [],
  }) => cookFinishBlocks(
    buildCookRun(lines: lines, pots: pots, meals: meals),
    byId(items),
  );

  group('cookFinishBlocks', () {
    test('a run with enough stock and no open line has no block', () {
      expect(
        blocks(
          [
            _taking('a', {'i': 100}),
          ],
          [stockItem('i', 100)],
        ),
        isEmpty,
      );
    });

    test('a line with only a rough need and a take of 0 does not block', () {
      final run = buildCookRun(
        lines: [
          textLine(
            'a',
            'Butter zum Braten',
            settlement: assigned({'i': 0}),
            roughWeight: const CookRoughWeight(
              amount: 20,
              unit: TemplateIngredientUnit.gram,
            ),
          ),
        ],
      );

      expect(cookFinishBlocks(run, byId([stockItem('i', 100)])), isEmpty);
    });

    group('stock', () {
      test('a take above the stock is short, with what is left', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 150}),
            ],
            [stockItem('i', 100)],
          ),
          [const CookStockShort(lineId: 'a', itemId: 'i', available: 100)],
        );
      });

      test('lines sharing an item are both short when together too much', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 80}),
              _taking('b', {'i': 50}),
            ],
            [stockItem('i', 100)],
          ),
          [
            const CookStockShort(lineId: 'a', itemId: 'i', available: 50),
            const CookStockShort(lineId: 'b', itemId: 'i', available: 20),
          ],
        );
      });

      test('lines sharing an item that holds both are fine', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 60}),
              _taking('b', {'i': 40}),
            ],
            [stockItem('i', 100)],
          ),
          isEmpty,
        );
      });

      test('what is left never goes below 0', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 60}),
              _taking('b', {'i': 60}),
              _taking('c', {'i': 60}),
            ],
            [stockItem('i', 100)],
          ),
          [
            const CookStockShort(lineId: 'a', itemId: 'i', available: 0),
            const CookStockShort(lineId: 'b', itemId: 'i', available: 0),
            const CookStockShort(lineId: 'c', itemId: 'i', available: 0),
          ],
        );
      });

      test('a take above the whole stock blames only its own line', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 10}),
              _taking('b', {'i': 500}),
            ],
            [stockItem('i', 100)],
          ),
          [const CookStockShort(lineId: 'b', itemId: 'i', available: 90)],
        );
      });

      test('a weighed line short on several items names all they hold', () {
        expect(
          blocks(
            [
              cookLine(
                'a',
                settlement: assigned({'i': 200, 'j': 200}),
                weighed: 400,
              ),
            ],
            [stockItem('i', 200), stockItem('j', 100)],
          ),
          [const CookStockShort(lineId: 'a', itemId: 'j', available: 300)],
        );
      });

      test('an unweighed line short on several items names only that one', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 200, 'j': 200}),
            ],
            [stockItem('i', 200), stockItem('j', 100)],
          ),
          [const CookStockShort(lineId: 'a', itemId: 'j', available: 100)],
        );
      });

      test('a gone item is "Eintrag fehlt"', () {
        expect(
          blocks([
            _taking('a', {'gone': 10}),
          ], const []),
          [const CookEntryMissing(lineId: 'a', itemId: 'gone')],
        );
      });

      test('an item without nutrition is "Nährwerte fehlen"', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 10}),
            ],
            [stockItem('i', 100, nutrition: null)],
          ),
          [const CookNutritionMissing(lineId: 'a', itemId: 'i')],
        );
      });

      test('an item lacking one macro is "Nährwerte fehlen"', () {
        const partial = GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 100,
          per100Protein: 1,
          per100Carbs: 1,
        );

        expect(
          blocks(
            [
              _taking('a', {'i': 10}),
            ],
            [stockItem('i', 100, nutrition: partial)],
          ),
          [const CookNutritionMissing(lineId: 'a', itemId: 'i')],
        );
      });

      test('takes of 0 check nothing', () {
        expect(
          blocks(
            [
              _taking('a', {'gone': 0, 'i': 0}),
            ],
            [stockItem('i', 100, nutrition: null)],
          ),
          isEmpty,
        );
      });

      test('short and nutrition on one take both show', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 200}),
            ],
            [stockItem('i', 100, nutrition: null)],
          ),
          [
            const CookStockShort(lineId: 'a', itemId: 'i', available: 100),
            const CookNutritionMissing(lineId: 'a', itemId: 'i'),
          ],
        );
      });

      test('ignored and open lines check no stock', () {
        expect(
          blocks([cookLine('a', settlement: const LineIgnored())], const []),
          isEmpty,
        );
      });
    });

    group('lines open', () {
      test('open and shopping lines count, ignored and assigned do not', () {
        expect(
          blocks([
            cookLine('a'),
            cookLine('b', settlement: const LineShopping()),
            cookLine('c', settlement: const LineIgnored()),
          ], const []),
          [const CookLinesOpen(2)],
        );
      });
    });

    group('pots', () {
      final stock = [stockItem('i', 1000)];

      test('without chosen pots there are no pot blocks', () {
        expect(
          blocks([
            _taking('a', {'i': 10}),
          ], stock),
          isEmpty,
        );
      });

      test('a counted run with a typed-in meal needs no weighing', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 10}),
            ],
            stock,
            pots: const CookCounted(),
            meals: [_meal(countedMealPotId, null)],
          ),
          isEmpty,
        );
      });

      test('a pot or counted run without a typed-in meal is blocked', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 10}),
            ],
            stock,
            pots: _pots(const [cookPotA]),
          ),
          [const CookMealMissing('pot-a')],
        );
        expect(
          blocks(
            [
              _taking('a', {'i': 10}),
            ],
            stock,
            pots: const CookCounted(),
          ),
          [const CookMealMissing(countedMealPotId)],
        );
      });

      test('a meal without gross weight is unweighed', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 10}),
            ],
            stock,
            pots: _pots(const [cookPotA]),
            meals: [_meal('pot-a', null)],
          ),
          [const CookPotUnweighed('pot-a')],
        );
      });

      test('a gross weight at or below the empty weight is unweighed', () {
        for (final gross in [900, 500]) {
          expect(
            blocks(
              [
                _taking('a', {'i': 10}),
              ],
              stock,
              pots: _pots(const [cookPotA]),
              meals: [_meal('pot-a', gross)],
            ),
            [const CookPotUnweighed('pot-a')],
            reason: 'gross $gross',
          );
        }
      });

      test('a meal in pieces without a gross weight is not unweighed', () {
        for (final gross in [null, 500]) {
          expect(
            blocks(
              [
                _taking('a', {'i': 10}),
              ],
              stock,
              pots: _pots(const [cookPotA]),
              meals: [
                CookMealDraft(
                  potId: 'pot-a',
                  name: 'Kekse',
                  count: 12,
                  inPieces: true,
                  grossWeight: gross,
                ),
              ],
            ),
            isEmpty,
            reason: 'gross $gross',
          );
        }
      });

      test('the same meal by weight is unweighed', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 10}),
            ],
            stock,
            pots: _pots(const [cookPotA]),
            meals: [
              const CookMealDraft(
                potId: 'pot-a',
                name: 'Eintopf',
                count: 4,
                inPieces: false,
                grossWeight: null,
              ),
            ],
          ),
          [const CookPotUnweighed('pot-a')],
        );
      });

      test('a gross weight above the empty weight is fine', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 10}),
            ],
            stock,
            pots: _pots(const [cookPotA]),
            meals: [_meal('pot-a', 901)],
          ),
          isEmpty,
        );
      });

      test('a pot without lines is "Topf ohne Zutaten"', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 10}, potId: 'pot-a'),
            ],
            stock,
            pots: _pots(const [cookPotA, cookPotB]),
            meals: [_meal('pot-a', 2000)],
          ),
          [const CookPotEmpty('pot-b')],
        );
      });

      test('a pot whose takes are all 0 is empty', () {
        expect(
          blocks(
            [
              _taking('a', {'i': 10}, potId: 'pot-a'),
              _taking('b', {'i': 0}, potId: 'pot-b'),
            ],
            stock,
            pots: _pots(const [cookPotA, cookPotB]),
            meals: [_meal('pot-a', 2000), _meal('pot-b', 2000)],
          ),
          [const CookPotEmpty('pot-b')],
        );
      });

      test('a counted run without a take above 0 is empty', () {
        for (final line in [
          cookLine('a', settlement: const LineIgnored()),
          _taking('a', {'i': 0}),
        ]) {
          expect(
            blocks(
              [line],
              stock,
              pots: const CookCounted(),
              meals: [_meal(countedMealPotId, null)],
            ),
            [const CookPotEmpty(countedMealPotId)],
          );
        }
      });

      test('a pot of ignored lines only is empty', () {
        expect(
          blocks(
            [cookLine('a', settlement: const LineIgnored())],
            stock,
            pots: _pots(const [cookPotA]),
          ),
          [const CookPotEmpty('pot-a')],
        );
      });
    });

    test('names the reasons in a fixed order', () {
      final result = blocks(
        [
          cookLine('open'),
          _taking('nutrition', {'plain': 10}, potId: 'pot-a'),
          _taking('gone', {'missing': 10}, potId: 'pot-a'),
          _taking('short', {'low': 500}, potId: 'pot-a'),
          _taking('third', {'ok': 10}, potId: 'pot-c'),
        ],
        [
          stockItem('plain', 100, nutrition: null),
          stockItem('low', 100),
          stockItem('ok', 100),
        ],
        pots: _pots(const [cookPotA, cookPotB, _potC]),
        meals: [_meal('pot-a', null)],
      );

      expect(result, [
        const CookStockShort(lineId: 'short', itemId: 'low', available: 100),
        const CookEntryMissing(lineId: 'gone', itemId: 'missing'),
        const CookNutritionMissing(lineId: 'nutrition', itemId: 'plain'),
        const CookPotUnweighed('pot-a'),
        const CookPotEmpty('pot-b'),
        const CookMealMissing('pot-c'),
        const CookLinesOpen(1),
      ]);
    });
  });

  group('a line that names an amount but takes nothing', () {
    CookRunLine line(
      String text, {
      Map<String, int> takes = const {'g': 0},
      int? weighed,
      int? amount,
    }) => textLine(
      'a',
      text,
      settlement: assigned(takes),
      weighed: weighed,
      amount: amount,
    );

    test('a piece line on a gram item without piece weight blocks', () {
      expect(blocks([line('1 Möhre')], [stockItem('g', 500)]), [
        const CookLineWithoutTake('a', canWeigh: true),
      ]);
    });

    test('weighed, it takes something and does not block', () {
      expect(
        blocks(
          [
            line('1 Möhre', takes: const {'g': 60}, weighed: 60),
          ],
          [stockItem('g', 500)],
        ),
        isEmpty,
      );
    });

    test('a line without amount, such as Salz, does not block', () {
      expect(blocks([line('Salz')], [stockItem('g', 500)]), isEmpty);
    });

    test('the cook own amount of 0 does not block', () {
      expect(
        blocks([line('1 Möhre', amount: 0)], [stockItem('g', 500)]),
        isEmpty,
      );
    });

    test('stock that is gone blocks: the take is 0 although it is needed', () {
      expect(blocks([line('200 g Reis')], [stockItem('g', 0, initial: 500)]), [
        const CookLineWithoutTake('a', canWeigh: true),
      ]);
    });

    test('is named after the stock blocks', () {
      expect(
        blocks(
          [
            line('1 Möhre'),
            _taking('b', {'g': 900}),
          ],
          [stockItem('g', 500)],
        ),
        [
          const CookStockShort(lineId: 'b', itemId: 'g', available: 500),
          const CookLineWithoutTake('a', canWeigh: true),
        ],
      );
    });

    test('"1 EL Senf" on a whole pack cannot be helped by weighing', () {
      expect(
        blocks(
          [
            line('1 EL Senf', takes: const {'pack': 0}),
          ],
          [packItem('pack', 2)],
        ),
        [const CookLineWithoutTake('a', canWeigh: false)],
      );
    });

    test('"200 g Reis" on an item counted in pieces cannot either', () {
      expect(
        blocks(
          [
            line('200 g Reis', takes: const {'egg': 0}),
          ],
          [
            stockItem(
              'egg',
              3000,
              unit: InventoryAmountUnit.piece,
              scale: 1000,
            ),
          ],
        ),
        [const CookLineWithoutTake('a', canWeigh: false)],
      );
    });

    test('an open line is not a line without take', () {
      expect(blocks([textLine('a', '1 Möhre')], [stockItem('g', 500)]), [
        const CookLinesOpen(1),
      ]);
    });
  });
}
