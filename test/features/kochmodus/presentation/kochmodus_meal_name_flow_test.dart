import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_change_sheet.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_meal_box.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_lines.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_portion_step.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

import '../../recipes/cook_run_fixtures.dart';
import '../kochmodus_fixtures.dart';
import 'kochmodus_cooking_harness.dart';

const _potA = 'pot-a';

final InventoryItem _flour = stockItem('flour', 1000);

const _weighed = CookMealDraft(
  potId: _potA,
  name: 'Eintopf',
  count: 4,
  inPieces: false,
  grossWeight: 1200,
);

CookRun _recipeRun({
  List<CookMealDraft> meals = const [],
  CookPotChoice? pots,
}) => buildCookRun(
  step: CookRunStep.portion,
  pots: pots ?? CookPotsChosen(pots: const [cookPotA], inCans: false),
  steps: const [],
  meals: meals,
  lines: [
    textLine('l-flour', 'Mehl', settlement: assigned({'flour': 200})),
  ],
);

CookRun _freeRun() => freeRun(
  [
    textLine('l-flour', 'Mehl', settlement: assigned({'flour': 200})),
  ],
  pots: CookPotsChosen(pots: const [cookPotA], inCans: false),
).copyWith(step: CookRunStep.portion);

void main() {
  late KochmodusCookingHarness harness;

  setUp(() async => harness = await KochmodusCookingHarness.open());

  Future<void> open(WidgetTester tester, CookRun run) async {
    await harness.stock(tester, [_flour]);
    await harness.store(tester, run);
    await harness.pumpRun(tester, run.id);
  }

  Future<String> storedName(WidgetTester tester, String potId) async {
    final run = await harness.storedRun(tester, 'recipe-t1');
    return run.meals.singleWhere((meal) => meal.potId == potId).name;
  }

  TextField nameField(WidgetTester tester, String potId) =>
      tester.widget<TextField>(find.byKey(KochmodusMealBox.nameKey(potId)));

  group('typed name and "In Vorrat"', () {
    testWidgets('a name typed with the keyboard open lands in the Vorrat', (
      tester,
    ) async {
      await open(tester, _recipeRun(meals: const [_weighed]));

      await tester.enterText(
        find.byKey(KochmodusMealBox.nameKey(_potA)),
        'Gulasch',
      );
      // No "done" on the keyboard: the button alone ends the typing.
      await tester.tap(find.byKey(KochmodusPortionStep.toStockKey));
      await harness.idle(tester);

      final meal = await tester.runAsync(
        () => harness.cook.storedMeal('${buildCookRun().cookingId}-$_potA'),
      );
      expect(meal!.name, 'Gulasch');
      expect(await tester.runAsync(() => harness.cook.mealCount()), 1);
    });

    testWidgets('a counted meal with a typed name keeps it, not the default', (
      tester,
    ) async {
      await open(tester, _recipeRun(pots: const CookCounted()));

      await tester.enterText(
        find.byKey(KochmodusMealBox.nameKey(countedMealPotId)),
        'Frikadellen',
      );
      await tester.tap(find.byKey(KochmodusPortionStep.toStockKey));
      await harness.idle(tester);

      final meal = await tester.runAsync(
        () => harness.cook.storedMeal(
          '${buildCookRun().cookingId}-$countedMealPotId',
        ),
      );
      expect(meal!.name, 'Frikadellen');
      expect(await tester.runAsync(() => harness.cook.mealCount()), 1);
    });
  });

  group('empty name', () {
    testWidgets('free cooking: an emptied field goes back to the default', (
      tester,
    ) async {
      await open(tester, _freeRun());
      final field = find.byKey(KochmodusMealBox.nameKey(_potA));
      // The hint of the field is the default name.
      final fallback = nameField(tester, _potA).decoration!.hintText!;
      expect(fallback, isNotEmpty);

      await tester.enterText(field, 'Suppe');
      FocusManager.instance.primaryFocus?.unfocus();
      await harness.idle(tester);
      expect(await storedName(tester, _potA), 'Suppe');

      await tester.enterText(field, '   ');
      FocusManager.instance.primaryFocus?.unfocus();
      await harness.idle(tester);

      expect(nameField(tester, _potA).controller!.text, fallback);
      expect(await storedName(tester, _potA), fallback);
    });
  });

  group('line without a shopping list', () {
    testWidgets('a line that came in while cooking cannot go shopping', (
      tester,
    ) async {
      await open(
        tester,
        _recipeRun(meals: const [_weighed])
            .addLine(cookedLine('new-1', 'Reis')),
      );

      await tester.ensureVisible(find.byKey(KochmodusPortionLines.takeNewKey));
      await harness.idle(tester);
      await tester.tap(find.byKey(KochmodusPortionLines.takeNewKey));
      await harness.idle(tester);

      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.ignore)),
        findsOneWidget,
      );
      expect(
        find.byKey(KochmodusChangeSheet.answerKey(KochmodusChange.shop)),
        findsNothing,
      );
    });
  });
}
