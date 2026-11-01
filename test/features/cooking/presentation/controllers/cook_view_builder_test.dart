import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/cooking/presentation/controllers/cook_session_controller.dart';
import 'package:yamt/features/cooking/presentation/controllers/cook_view_builder.dart';
import 'package:yamt/features/cooking/presentation/models/cook_view.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/fake_inventory_item_repository.dart';
import '../../../../helpers/fake_prepared_meal_template_repository.dart';

InventoryItem _grams(String id, String name, int amount) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: DateTime.utc(2026, 10),
      storeName: 'Store',
      quantity: 1,
      initialAmount: amount,
      currentAmount: amount,
      amountUnit: InventoryAmountUnit.gram,
    );

InventoryItem _pieces(String id, String name, int pieces) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: DateTime.utc(2026, 10),
      storeName: 'Store',
      quantity: 1,
      initialAmount: pieces * inventoryPieceAmountScale,
      currentAmount: pieces * inventoryPieceAmountScale,
      amountScale: inventoryPieceAmountScale,
      amountUnit: InventoryAmountUnit.piece,
    );

PreparedMeal _template(List<String> lines, {int portions = 2}) => PreparedMeal(
  id: 'stew',
  name: 'Eintopf',
  totalPortions: portions,
  remainingPortions: portions,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: DateTime.utc(2026, 10, 9),
  updatedAt: DateTime.utc(2026, 10, 9),
  components: const [],
  recipeIngredients: lines,
  recipeInstructions: const ['Kochen.'],
);

CookView _view(
  List<String> lines,
  List<InventoryItem> items, {
  CookSession session = const CookSession(),
}) => buildCookView(
  template: _template(lines),
  items: items,
  session: session,
  parser: const TemplateIngredientParser(),
  localeCode: 'de',
  l10n: lookupAppLocalizations(const Locale('de')),
);

void main() {
  group('buildCookView', () {
    test('sizes each line label for the portions cooked', () {
      final view = _view(
        ['500 g Hackfleisch', 'Salz'],
        const [],
        session: const CookSession(portions: 4),
      );

      expect(view.portions, 4);
      expect(view.lines.map((line) => line.label), [
        '1000 g Hackfleisch',
        'Salz',
      ]);
    });

    test('counted foods show no unit, measures keep theirs', () {
      final view = _view([
        '2 Zwiebeln',
        '1 mittlere Zwiebel',
        '2 EL Olivenöl',
      ], const []);

      expect(view.lines.map((line) => line.label), [
        '2 Zwiebeln',
        '1 mittlere Zwiebel',
        '2 EL Olivenöl',
      ]);
    });

    test('names the food a line stands for', () {
      final view = _view([
        '1 mittlere Zwiebel',
        '1 Prise Salz',
        '200 g Spaghetti Nudeln',
      ], const []);

      expect(view.lines.map((line) => line.food), [
        'Zwiebel',
        'Salz',
        'Spaghetti',
      ]);
    });

    test('suggests the matching item and what it can give', () {
      final view = _view(
        ['500 g Hackfleisch'],
        [_grams('mince', 'Hackfleisch', 800), _grams('rice', 'Reis', 900)],
      );

      final line = view.lines.single;
      expect(line.clarification, isA<LineOpen>());
      expect(line.suggestion.single.item.id, 'mince');
      expect(line.suggestion.single.amount, 500);
      expect(line.takes.single.item.id, 'mince');
      expect(line.needed, 500);
      expect(line.unit, InventoryAmountUnit.gram);
      expect(line.missing, 0);
      expect(line.offers.single.available, 800);
      expect(line.offers.single.needed, 500);
      expect(line.moreOffers.map((offer) => offer.item.id), ['rice']);
    });

    test('a later line is not offered what an earlier one reserves', () {
      final view = _view(
        ['300 g Hackfleisch', '300 g Hackfleisch'],
        [_grams('mince', 'Hackfleisch', 400)],
      );

      expect(view.lines[0].suggestion.single.amount, 300);
      expect(view.lines[1].suggestion.single.amount, 100);
      expect(view.lines[1].missing, 200);
    });

    test('a settled line reserves its own takes for the later ones', () {
      final view = _view(
        ['300 g Hackfleisch', '300 g Hackfleisch'],
        [_grams('mince', 'Hackfleisch', 400)],
        session: const CookSession().withLine(
          'line-0',
          const LineAssigned([(itemId: 'mince', amount: 250)]),
        ),
      );

      expect(view.lines[0].takes.single.amount, 250);
      expect(view.lines[0].missing, 50);
      expect(view.lines[1].suggestion.single.amount, 150);
      expect(view.lines[1].offers.single.available, 150);
    });

    test('a line the Vorrat cannot supply is open without suggestion', () {
      final view = _view(['500 g Hackfleisch'], [_grams('rice', 'Reis', 900)]);

      final line = view.lines.single;
      expect(line.suggestion, isEmpty);
      expect(line.takes, isEmpty);
      expect(line.offers, isEmpty);
      expect(view.foundLines, isEmpty);
      expect(view.openLines, [line]);
      expect(view.isSettled, isFalse);
    });

    test('pieces from the Vorrat are suggested and labeled without a unit', () {
      final view = _view(['2 Zwiebeln'], [_pieces('onion', 'Zwiebeln', 5)]);

      final line = view.lines.single;
      expect(line.suggestion.single.item.id, 'onion');
      expect(line.label, '2 Zwiebeln');
    });

    test('sorts lines onto the two pages', () {
      final accepted = _view(
        ['500 g Hackfleisch', '100 g Reis', 'Salz'],
        [_grams('mince', 'Hackfleisch', 800)],
        session: const CookSession()
            .withLine('line-1', const LineRejected())
            .withLine('line-2', const LineOmitted(), onSecondPage: true),
      );

      expect(accepted.foundLines.map((line) => line.line.id), [
        'line-0',
        'line-1',
      ]);
      expect(accepted.openLines.map((line) => line.line.id), [
        'line-1',
        'line-2',
      ]);
    });

    test('is settled once every line is assigned or left out', () {
      final settled = _view(
        ['500 g Hackfleisch', 'Salz'],
        [_grams('mince', 'Hackfleisch', 800)],
        session: const CookSession()
            .withLine(
              'line-0',
              const LineAssigned([(itemId: 'mince', amount: 500)]),
            )
            .withLine('line-1', const LineOmitted(), onSecondPage: true),
      );

      expect(settled.isSettled, isTrue);
    });
  });

  group('cookViewProvider', () {
    test('loads with the recipe and the Vorrat, then holds the view', () async {
      final container = ProviderContainer(
        overrides: [
          preparedMealTemplateRepositoryProvider.overrideWithValue(
            FakePreparedMealTemplateRepository(
              templates: [
                _template(['500 g Hackfleisch']),
              ],
            ),
          ),
          inventoryItemRepositoryProvider.overrideWithValue(
            FakeInventoryItemRepository([_grams('mince', 'Hackfleisch', 800)]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final states = <AsyncValue<CookView?>>[];
      container.listen(
        cookViewProvider('stew', 'de'),
        (_, next) => states.add(next),
        fireImmediately: true,
      );

      await _until(() => states.any((state) => state.hasValue));

      expect(states.first, isA<AsyncLoading<CookView?>>());
      expect(states.last.requireValue!.lines.single.suggestion, isNotEmpty);
    });

    test('follows the session controller', () async {
      final container = ProviderContainer(
        overrides: [
          preparedMealTemplateRepositoryProvider.overrideWithValue(
            FakePreparedMealTemplateRepository(
              templates: [
                _template(['500 g Hackfleisch']),
              ],
            ),
          ),
          inventoryItemRepositoryProvider.overrideWithValue(
            FakeInventoryItemRepository([_grams('mince', 'Hackfleisch', 800)]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        cookViewProvider('stew', 'de'),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await _until(() => subscription.read().hasValue);

      container.read(cookSessionControllerProvider('stew').notifier)
        ..setPortions(4)
        ..goTo(CookStep.found);

      final view = subscription.read().requireValue!;
      expect(view.portions, 4);
      expect(view.session.step, CookStep.found);
      expect(view.lines.single.label, '1000 g Hackfleisch');
    });

    test('is null when the recipe is gone', () async {
      final container = ProviderContainer(
        overrides: [
          preparedMealTemplateRepositoryProvider.overrideWithValue(
            FakePreparedMealTemplateRepository(),
          ),
          inventoryItemRepositoryProvider.overrideWithValue(
            FakeInventoryItemRepository(const []),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        cookViewProvider('stew', 'de'),
        (_, _) {},
      );
      addTearDown(subscription.close);

      await _until(() => subscription.read().hasValue);

      expect(subscription.read().requireValue, isNull);
    });

    test('a Vorlage without ingredient lines is not a recipe', () async {
      final container = ProviderContainer(
        overrides: [
          preparedMealTemplateRepositoryProvider.overrideWithValue(
            FakePreparedMealTemplateRepository(templates: [_template([])]),
          ),
          inventoryItemRepositoryProvider.overrideWithValue(
            FakeInventoryItemRepository(const []),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        cookViewProvider('stew', 'de'),
        (_, _) {},
      );
      addTearDown(subscription.close);

      await _until(() => subscription.read().hasValue);

      expect(subscription.read().requireValue, isNull);
    });
  });
}

Future<void> _until(bool Function() done) async {
  for (var i = 0; i < 50 && !done(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(done(), isTrue);
}
