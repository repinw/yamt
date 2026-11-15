import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

import '../../kochmodus/kochmodus_fixtures.dart';
import '../cook_run_fixtures.dart';

Map<String, dynamic> _copy(Map<String, dynamic> json) => Map.of(json);

void main() {
  group('CookRun JSON', () {
    test('round trip keeps every field and the microseconds', () {
      final run = fullCookRun();

      final read = CookRun.fromJson(run.toJson());

      expect(read, run);
      expect(read.hashCode, run.hashCode);
      expect(read.startedAt, cookRunStart);
      expect(read.startedAt.microsecond, 456);
    });

    test('round trip of a run without pots and with a counted choice', () {
      final none = buildCookRun();
      final counted = buildCookRun(pots: const CookCounted());

      expect(CookRun.fromJson(none.toJson()), none);
      expect(CookRun.fromJson(counted.toJson()), counted);
    });

    test('a missing field throws, nullable ones too', () {
      for (final key in fullCookRun().toJson().keys) {
        final json = _copy(fullCookRun().toJson())..remove(key);
        expect(() => CookRun.fromJson(json), throwsA(anything), reason: key);
      }
    });

    test('an unknown key throws', () {
      final json = fullCookRun().toJson()..['extra'] = 1;

      expect(() => CookRun.fromJson(json), throwsA(anything));
    });

    test('stored portions below 1 throw', () {
      for (final key in ['portions', 'base_portions']) {
        final json = fullCookRun().toJson()..[key] = 0;
        expect(() => CookRun.fromJson(json), throwsArgumentError, reason: key);
      }
    });

    test('the cooking id tells two cookings of one recipe apart', () {
      final first = buildCookRun();
      final later = buildCookRun(
        startedAt: cookRunStart.add(const Duration(days: 1)),
      );

      expect(first.cookingId, startsWith('recipe-t1-'));
      expect(first.cookingId, CookRun.fromJson(first.toJson()).cookingId);
      expect(later.cookingId, isNot(first.cookingId));
    });

    test('an unknown enum value throws', () {
      final json = fullCookRun().toJson()..['step'] = 'sleeping';

      expect(() => CookRun.fromJson(json), throwsA(anything));
    });
  });

  group('CookRunLine JSON', () {
    test('a missing field and an unknown key throw', () {
      final line = fullCookRun().lines[1];
      for (final key in line.toJson().keys) {
        final json = Map<String, dynamic>.from(line.toJson())..remove(key);
        expect(
          () => CookRunLine.fromJson(json),
          throwsA(anything),
          reason: key,
        );
      }
      final extra = Map<String, dynamic>.from(line.toJson())..['x'] = 1;
      expect(() => CookRunLine.fromJson(extra), throwsA(anything));
    });

    test('the amount and its portions round trip', () {
      final line = cookLine('l', amount: 100, amountPortions: 3);
      final json = line.toJson();

      expect(json['amount_portions'], 3);
      expect(CookRunLine.fromJson(json), line);
      expect(cookLine('l').toJson()['amount_portions'], isNull);
    });

    test('the unit of the amount round trips and stays off without one', () {
      const line = CookRunLine(
        id: 'l',
        text: 'Eier',
        origin: CookLineOrigin.recipe,
        conversion: null,
        amount: 3,
        amountPortions: 4,
        amountUnit: TemplateIngredientUnit.piece,
        settlement: LineOpen(),
        weighed: null,
        potId: null,
        addedItemIds: [],
      );
      expect(line.toJson()['amount_unit'], 'pc');
      expect(CookRunLine.fromJson(line.toJson()), line);
      expect(cookLine('l').toJson().containsKey('amount_unit'), isFalse);
      expect(CookRunLine.fromJson(cookLine('l').toJson()).amountUnit, isNull);
    });

    test('a unit without an amount and an unknown unit throw', () {
      final json = cookLine('l').toJson();
      expect(
        () => CookRunLine.fromJson({...json, 'amount_unit': 'pc'}),
        throwsFormatException,
      );
      final amount = cookLine('l', amount: 3, amountPortions: 4).toJson();
      expect(
        () => CookRunLine.fromJson({...amount, 'amount_unit': 'kg'}),
        throwsA(anything),
      );
    });

    test('only one of amount and amount_portions throws', () {
      final line = cookLine('l', amount: 100, amountPortions: 3);
      final noPortions = Map<String, dynamic>.from(line.toJson())
        ..['amount_portions'] = null;
      final noAmount = Map<String, dynamic>.from(line.toJson())
        ..['amount'] = null;

      expect(() => CookRunLine.fromJson(noPortions), throwsFormatException);
      expect(() => CookRunLine.fromJson(noAmount), throwsFormatException);
    });

    test('amount_portions below 1 throws', () {
      for (final portions in [0, -2]) {
        final json = Map<String, dynamic>.from(
          cookLine('l', amount: 100, amountPortions: 3).toJson(),
        )..['amount_portions'] = portions;

        expect(
          () => CookRunLine.fromJson(json),
          throwsFormatException,
          reason: '$portions',
        );
      }
    });

    test('the rough weight round trips and stays off without one', () {
      final plain = textLine('a', 'Butter zum Braten');
      const rough = CookRoughWeight(
        amount: 20,
        unit: TemplateIngredientUnit.milliliter,
      );
      final line = textLine('a', 'Butter zum Braten', roughWeight: rough);

      expect(plain.toJson().containsKey('rough_weight'), isFalse);
      expect(line.toJson()['rough_weight'], {'amount': 20, 'unit': 'ml'});
      expect(CookRunLine.fromJson(line.toJson()), line);
      expect(CookRunLine.fromJson(line.toJson()).roughWeight, rough);
      expect(line, isNot(plain));
      expect(line.hashCode, isNot(plain.hashCode));
      // Changing the line keeps the recipe's rough weight.
      expect(line.copyWith(weighed: () => 5).roughWeight, rough);
    });

    test('a rough weight with a bad unit or an unknown key throws', () {
      final json = textLine('a', 'Butter').toJson();

      for (final bad in [
        {'amount': 20, 'unit': 'kg'},
        {'amount': 20, 'unit': 'g', 'extra': 1},
        {'unit': 'g'},
      ]) {
        expect(
          () => CookRunLine.fromJson({...json, 'rough_weight': bad}),
          throwsA(anything),
          reason: '$bad',
        );
      }
    });

    test('a rough weight in pieces throws', () {
      final json = textLine('a', 'Butter').toJson();

      expect(
        () => CookRunLine.fromJson({
          ...json,
          'rough_weight': const {'amount': 20, 'unit': 'pc'},
        }),
        throwsA(anything),
      );
    });

    test('conversion writes g, ml and pc and rejects another unit', () {
      for (final unit in TemplateIngredientUnit.values) {
        final conversion = CookLineConversion(amountPerPiece: 5, unit: unit);
        expect(conversion.toJson()['unit'], unit.code);
        expect(CookLineConversion.fromJson(conversion.toJson()), conversion);
      }
      expect(
        () => CookLineConversion.fromJson(const {
          'amount_per_piece': 1,
          'unit': 'kg',
        }),
        throwsFormatException,
      );
      expect(
        () => CookLineConversion.fromJson(const {'amount_per_piece': 1}),
        throwsA(anything),
      );
    });
  });

  group('LineSettlement JSON', () {
    test('every type round trips', () {
      final all = <LineSettlement>[
        const LineOpen(),
        LineAssigned(const [
          ItemTake(itemId: 'a', amount: 1),
          ItemTake(itemId: 'b', amount: 0),
        ]),
        const LineShopping(),
        const LineIgnored(),
      ];
      for (final settlement in all) {
        expect(LineSettlement.fromJson(settlement.toJson()), settlement);
      }
    });

    test('an unknown type throws', () {
      expect(
        () => LineSettlement.fromJson(const {'type': 'eaten'}),
        throwsFormatException,
      );
    });

    test('a field too many or too few throws', () {
      expect(
        () => LineSettlement.fromJson(const {'type': 'open', 'x': 1}),
        throwsFormatException,
      );
      expect(
        () => LineSettlement.fromJson(const {'type': 'assigned'}),
        throwsFormatException,
      );
      expect(
        () => LineSettlement.fromJson(const {
          'type': 'assigned',
          'takes': <dynamic>[],
          'x': 1,
        }),
        throwsFormatException,
      );
    });

    test('a take with a missing field or an unknown key throws', () {
      expect(
        () => LineSettlement.fromJson(const {
          'type': 'assigned',
          'takes': [
            {'item_id': 'a'},
          ],
        }),
        throwsA(anything),
      );
      expect(
        () => ItemTake.fromJson(const {'item_id': 'a', 'amount': 1, 'x': 1}),
        throwsA(anything),
      );
    });

    test('LineAssigned rejects no takes, a negative amount, a duplicate', () {
      expect(() => LineAssigned(const []), throwsArgumentError);
      expect(
        () => LineAssigned(const [ItemTake(itemId: 'a', amount: -1)]),
        throwsArgumentError,
      );
      expect(
        () => LineAssigned(const [
          ItemTake(itemId: 'a', amount: 1),
          ItemTake(itemId: 'a', amount: 2),
        ]),
        throwsArgumentError,
      );
      expect(
        () => LineSettlement.fromJson(const {
          'type': 'assigned',
          'takes': <dynamic>[],
        }),
        throwsArgumentError,
      );
    });
  });

  group('CookPotChoice JSON', () {
    test('both types round trip', () {
      final all = <CookPotChoice>[
        CookPotsChosen(pots: const [cookPotA, cookPotB], inCans: true),
        const CookCounted(),
      ];
      for (final choice in all) {
        expect(CookPotChoice.fromJson(choice.toJson()), choice);
      }
    });

    test('an unknown type, no pots or a wrong field count throws', () {
      expect(
        () => CookPotChoice.fromJson(const {'type': 'bowl'}),
        throwsFormatException,
      );
      expect(
        () => CookPotChoice.fromJson(const {
          'type': 'pots',
          'pots': <dynamic>[],
          'in_cans': false,
        }),
        throwsFormatException,
      );
      expect(
        () => CookPotChoice.fromJson(const {'type': 'counted', 'x': 1}),
        throwsFormatException,
      );
      expect(
        () => CookPotChoice.fromJson({
          'type': 'pots',
          'pots': [cookPotA.toJson()],
        }),
        throwsFormatException,
      );
    });

    test('CookPotsChosen rejects no pots', () {
      expect(
        () => CookPotsChosen(pots: const [], inCans: false),
        throwsArgumentError,
      );
    });

    test('a pot without an empty weight above 0 is refused', () {
      final json = CookPotsChosen(
        pots: const [cookPotA],
        inCans: false,
      ).toJson();
      (json['pots'] as List<dynamic>)[0] = {
        ...cookPotA.toJson(),
        'empty_weight': 0,
      };

      expect(() => CookPotChoice.fromJson(json), throwsArgumentError);
    });

    test('a pot with a missing field or an unknown key throws', () {
      for (final key in cookPotA.toJson().keys) {
        final json = Map<String, dynamic>.from(cookPotA.toJson())..remove(key);
        expect(() => CookPot.fromJson(json), throwsA(anything), reason: key);
      }
      final extra = Map<String, dynamic>.from(cookPotA.toJson())..['x'] = 1;
      expect(() => CookPot.fromJson(extra), throwsA(anything));
    });
  });

  group('CookTimer and CookMealDraft JSON', () {
    test('round trip and strictness', () {
      final timer = fullCookRun().timers.single;
      final meal = fullCookRun().meals.first;

      expect(CookTimer.fromJson(timer.toJson()), timer);
      expect(CookMealDraft.fromJson(meal.toJson()), meal);
      for (final key in timer.toJson().keys) {
        final json = Map<String, dynamic>.from(timer.toJson())..remove(key);
        expect(() => CookTimer.fromJson(json), throwsA(anything), reason: key);
      }
      for (final key in meal.toJson().keys) {
        final json = Map<String, dynamic>.from(meal.toJson())..remove(key);
        expect(
          () => CookMealDraft.fromJson(json),
          throwsA(anything),
          reason: key,
        );
      }
      expect(
        () => CookTimer.fromJson(Map.of(timer.toJson())..['x'] = 1),
        throwsA(anything),
      );
      expect(
        () => CookMealDraft.fromJson(Map.of(meal.toJson())..['x'] = 1),
        throwsA(anything),
      );
    });
  });
}
