import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/ingredient_stock_match.dart';
import 'package:yamt/features/inventory/domain/ingredient_compound_head.dart';
import 'package:yamt/features/inventory/domain/ingredient_match_lexicon.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

InventoryItem _item({required String id, required String name}) =>
    InventoryItem.create(
      id: id,
      name: name,
      entryDate: DateTime.utc(2026, 10),
      storeName: 'Store',
      quantity: 1,
    );

void main() {
  test('a food only at the start of a compound matches weakly (#842)', () {
    bool weak(String ingredient, String name) => isWeakIngredientMatch(
      ingredient: ingredient,
      item: _item(id: name, name: name),
    );

    // The item names another food after it, or the line after the item.
    expect(weak('100 g Reis', 'Reiswaffeln'), isTrue);
    expect(weak('100 g Reis', 'Reis-Waffeln'), isTrue);
    expect(weak('2 Eier', 'Eiernudeln'), isTrue);
    expect(weak('1 Ei', 'Eiernudeln'), isTrue);
    expect(weak('300 ml Milch', 'Milchschokolade'), isTrue);
    expect(weak('200 g Milchreis', 'Milch'), isTrue);
    expect(weak('500 g Kartoffeln', 'Kartoffelpüree'), isTrue);
    expect(weak('100 g Mais', 'Maisöl'), isTrue);
    // A cut is weak too: the cook picks it once.
    expect(weak('200 g Hering', 'Heringsfilet'), isTrue);
    expect(weak('50 g Hafer', 'Haferflocken'), isTrue);
    expect(weak('200 g Hähnchen', 'Hähnchenbrust'), isTrue);
    // The food as the last part, an ending, an amount word, a number, or
    // several words are not.
    expect(weak('2 Knoblauchzehen', 'Knoblauch'), isFalse);
    expect(weak('1 Knoblauch', 'Knoblauchzehen'), isFalse);
    expect(weak('400 g Tomaten', 'Tomatenstücke'), isFalse);
    expect(weak('2 EL Reis', 'Reiswaffeln'), isTrue);
    expect(weak('200 g Milchreis', 'Bio Milch'), isTrue);
    expect(weak('100 g Reis', 'Basmatireis'), isFalse);
    expect(weak('300 ml Milch', 'Milch3,5%'), isFalse);
    expect(weak('2 Karotte', 'Karotten'), isFalse);
    expect(weak('100 g Reis', 'Reis'), isFalse);
    expect(weak('100 g Test Reis', 'Testreis'), isFalse);
    // Known limit (#891): the last part fits, so these are no weak match.
    expect(weak('300 ml Milch', 'Buttermilch'), isFalse);
    expect(weak('100 g Reis', 'Milchreis'), isFalse);
  });

  test('a compound spelled as two words in the Vorrat keeps its match', () {
    bool weak(String ingredient, String name) => isWeakIngredientMatch(
      ingredient: ingredient,
      item: _item(id: name, name: name),
    );

    expect(weak('Mandelmus', 'Mandel Mus'), isFalse);
    expect(weak('Apfelmus', 'Apfel Mus'), isFalse);
    expect(weak('Vollkornmehl', 'Vollkorn Weizenmehl'), isFalse);
    expect(weak('Dinkelmehl', 'Dinkel Vollkornmehl'), isFalse);
    expect(weak('Mandel Mus', 'Mandelmus'), isFalse);
  });

  test('a word that starts another food is still a weak match', () {
    bool weak(String ingredient, String name) => isWeakIngredientMatch(
      ingredient: ingredient,
      item: _item(id: name, name: name),
    );

    expect(weak('Hafermilch', 'Hafer Drink'), isTrue);
    expect(weak('Sojamilch', 'Soja Drink'), isTrue);
    expect(weak('Tomatensauce', 'Pastasauce Tomate'), isTrue);
    expect(weak('Paprikapulver', 'Paprika edelsüß'), isTrue);
    expect(weak('Vollkornmehl', 'Weizenmehl Vollkorn'), isTrue);
  });

  test('known limit: a head spelled as two words stays weak', () {
    bool weak(String ingredient, String name) => isWeakIngredientMatch(
      ingredient: ingredient,
      item: _item(id: name, name: name),
    );

    expect(weak('Rinderhack', 'Rind Hackfleisch'), isTrue);
    expect(weak('200 g Hähnchenbrust', 'Hähnchen Brustfilet'), isTrue);
  });

  test('a food that shares only a kind word is a weak match', () {
    bool weak(String ingredient, String name) => isWeakIngredientMatch(
      ingredient: ingredient,
      item: _item(id: name, name: name),
    );

    expect(weak('1 TL Schwarzer Pfeffer', 'Schwarzer Tee'), isTrue);
    expect(weak('1/2 TL Schwarzer Pfeffer', 'Schwarzer Tee'), isTrue);
    expect(weak('200 g rote Linsen', 'Rote Bete'), isTrue);
    // The food itself, also from a shorter line or with a compound head.
    expect(weak('1 TL Schwarzer Pfeffer', 'Schwarzer Pfeffer'), isFalse);
    expect(weak('1 TL Pfeffer', 'Schwarzer Pfeffer'), isFalse);
    expect(weak('1 TL Schwarzer Pfeffer', 'Pfeffer'), isFalse);
    expect(weak('200 g rote Linsen', 'Rote Linsen'), isFalse);
    expect(weak('1 TL Pfeffer', 'Cayennepfeffer'), isFalse);
  });

  group('a shared noun makes a normal match (R5)', () {
    const notWeak = <(String, String)>[
      ('2 Zwiebeln, fein gewürfelt', 'Zwiebeln rot'),
      ('2 Zwiebeln, fein gewürfelt', 'Zwiebel gelb'),
      ('100 g Butter, weich', 'Butter Almhof'),
      ('2 Zehen Knoblauch, gepresst', 'Knoblauch weiß'),
      ('250 ml Milch, lauwarm', 'Milch Almhof'),
      ('4 Eier (Größe M)', 'Eier Freiland'),
      ('4 Eier Größe M', 'Eier Freiland'),
      ('4 Eier, Größe M', 'Eier Freiland'),
      ('Eier Größe M', 'Eier Freiland'),
      ('1 Dose Tomaten (400 g)', 'Tomaten stückig'),
      ('Salz, nach Geschmack', 'Salz fein'),
      ('1 EL Olivenöl zum Braten', 'Olivenöl nativ'),
      ('Penne Rigate', 'Penne 500 g'),
      ('Penne Rigate', 'Penne Almhof'),
      ('Weizenmehl Type 405', 'Weizenmehl Type 550'),
      ('Mehl Type 405', 'Mehl 550'),
      ('Rote Beete', 'Rote Bete'),
      ('Tomaten aus der Dose', 'Tomaten stückig'),
      ('Kokosmilch ungesüßt', 'Kokosmilch Almhof'),
      ('Tomaten gehackt', 'Tomaten passiert'),
      ('Hackfleisch gemischt', 'Hackfleisch Rind'),
      ('Olivenöl extra', 'Olivenöl nativ'),
      ('Joghurt mild', 'Joghurt cremig'),
      ('2 tbsp olive oil, divided', 'Olive Oil Almhof'),
      ('1 onion, diced', 'Onion yellow'),
      ('2 cloves garlic, minced', 'Garlic Bulb'),
      ('1 cup chicken broth', 'Chicken Stock'),
      ('Chicken thighs', 'Chicken Breast'),
      ('Pfeffer', 'Schwarzer Pfeffer'),
      ('Tomaten', 'Gehackte Tomaten'),
      ('Gehackte Tomaten', 'Tomaten'),
      ('Rote Zwiebel', 'Zwiebeln rot'),
      ('Olivenöl', 'Natives Olivenöl extra'),
      ('Milch', 'Fettarme Milch 1,5 %'),
      ('Reis', 'Basmati Reis'),
      ('1 TL schwarzer Pfeffer', 'Schwarzer Pfeffer'),
      ('1 TL Pfeffer', 'Cayennepfeffer'),
      ('200 g rote Linsen', 'Rote Linsen'),
    ];
    for (final (line, name) in notWeak) {
      test('"$line" is no weak match for "$name"', () {
        expect(
          isWeakIngredientMatch(
            ingredient: line,
            item: _item(id: name, name: name),
          ),
          isFalse,
        );
      });
    }

    const weak = <(String, String)>[
      ('Schwarzer Pfeffer', 'Schwarzer Tee'),
      ('1/2 TL Schwarzer Pfeffer', 'Schwarzer Tee'),
      ('1 TL schwarzer Pfeffer', 'Schwarzer Tee'),
      ('Rote Linsen', 'Rote Bete'),
      ('200 g rote Linsen', 'Rote Bete'),
      ('Rote Linsen', 'Rote Kidneybohnen'),
      ('Grüne Bohnen', 'Grüne Linsen'),
      ('black pepper', 'Black Tea'),
      ('1 tsp ground black pepper', 'Black Tea'),
      ('100 g Reis', 'Reiswaffeln'),
    ];
    for (final (line, name) in weak) {
      test('"$line" is a weak match for "$name"', () {
        expect(
          isWeakIngredientMatch(
            ingredient: line,
            item: _item(id: name, name: name),
          ),
          isTrue,
        );
      });
    }
  });

  group("a name of several words with the line's compound start", () {
    const weak = <(String, String)>[
      ('250 g Milchreis', 'Fettarme H-Milch'),
      ('250 g Milchreis', 'Milch Almhof'),
      ('250 g Milchreis', 'Milch 1,5 %'),
      ('1 l Milch', 'Milchreis Almhof'),
      ('Milch', 'Milchreis Almhof'),
      ('1 l Milch', 'Milchreis klassisch'),
      ('Milch', 'Milchreis klassisch'),
      ('Reis', 'Reiswaffeln natur'),
      ('Tomaten', 'Tomatenmark dreifach konzentriert'),
      ('200 g Tomatenmark', 'Tomaten stückig'),
      ('Butter', 'Butterkekse Almhof'),
      ('Kartoffeln', 'Kartoffelpüree Almhof'),
      ('Apfel', 'Apfelsaft naturtrüb'),
      ('2 Eier', 'Eiernudeln breit'),
      ('Reis', 'Reis-Waffeln'),
    ];
    for (final (line, name) in weak) {
      test('"$line" is a weak match for "$name"', () {
        expect(
          isWeakIngredientMatch(
            ingredient: line,
            item: _item(id: name, name: name),
          ),
          isTrue,
        );
      });
    }

    const notWeak = <(String, String)>[
      ('Milch', 'Fettarme H-Milch'),
      ('1 l Milch', 'Fettarme H-Milch'),
      ('250 g Milchreis', 'Milchreis Almhof'),
      ('Zwiebel', 'Zwiebeln rot'),
      ('Knoblauch', 'Knoblauchzehen frisch'),
      ('Reis', 'Basmatireis lose'),
      ('2 Tomaten', 'Tomaten stückig'),
      ('Vollmilch', 'Frische Vollmilch 3,5 %'),
      // They share the whole word "rice".
      ('rice', 'Rice Cakes Almhof'),
    ];
    for (final (line, name) in notWeak) {
      test('"$line" is no weak match for "$name"', () {
        expect(
          isWeakIngredientMatch(
            ingredient: line,
            item: _item(id: name, name: name),
          ),
          isFalse,
        );
      });
    }
  });

  test('isIngredientKindWord knows the kind words, not the foods', () {
    const lexicon = fallbackIngredientMatchLexicon;
    for (final word in ['schwarzer', 'rote', 'dunkle', 'saure']) {
      expect(isIngredientKindWord(word, lexicon), isTrue, reason: word);
    }
    for (final word in ['pfeffer', 'milch']) {
      expect(isIngredientKindWord(word, lexicon), isFalse, reason: word);
    }
  });

  group('where the cook sees it', () {
    InventoryItem stocked(String name) => InventoryItem.create(
      id: name,
      name: name,
      entryDate: DateTime.utc(2026, 10),
      storeName: 'Store',
      quantity: 6,
      initialQuantity: 6,
    );

    test('"Zwiebeln rot" is among the matches of the fine-diced line', () {
      final red = stocked('Zwiebeln rot');
      final found = ingredientStockCandidates(
        text: '2 Zwiebeln, fein gewürfelt',
        requirement: const TemplateIngredientParser().parseRequirement(
          ingredient: '2 Zwiebeln, fein gewürfelt',
          selectedPortions: 1,
          basePortions: 1,
        ),
        items: [red],
        localeCode: 'de',
      );
      expect(found.matches, [red]);
    });

    test('"Eier Freiland" in the Vorrat counts for "4 Eier (Größe M)"', () {
      expect(
        hasInventoryItemForIngredient(
          ingredient: '4 Eier (Größe M)',
          inventoryItems: [stocked('Eier Freiland')],
          localeCode: 'de',
        ),
        isTrue,
      );
    });
  });
}
