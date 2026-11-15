import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/cook_line_food.dart';

void main() {
  group('cookLineFood', () {
    test('takes the capitalized words after amount and adjectives', () {
      expect(cookLineFood('1 mittlere Zwiebel'), 'Zwiebel');
      expect(cookLineFood('200 g Spaghetti Nudeln'), 'Spaghetti Nudeln');
      expect(cookLineFood('1,5 kg Kartoffeln'), 'Kartoffeln');
      expect(cookLineFood('frisch gemahlener Pfeffer'), 'Pfeffer');
    });

    test('keeps a name that starts with an adjective', () {
      expect(cookLineFood('1/2 TL Schwarzer Pfeffer'), 'Schwarzer Pfeffer');
    });

    test('stops at the first small word or comma', () {
      expect(cookLineFood('1 TL Oregano getrocknet'), 'Oregano');
      expect(cookLineFood('Butter zum Braten'), 'Butter');
      expect(cookLineFood('100 g Frischkäse, fettarm'), 'Frischkäse');
    });

    test('skips a measure word', () {
      expect(cookLineFood('1 Prise Salz'), 'Salz');
      expect(cookLineFood('2 EL Olivenöl'), 'Olivenöl');
      expect(cookLineFood('½ Bund Petersilie'), 'Petersilie');
      expect(cookLineFood('etwas Pfeffer'), 'Pfeffer');
      expect(cookLineFood('1 kleine Dose Tomaten'), 'Tomaten');
    });

    test('skips an amount in words', () {
      expect(cookLineFood('Zwei Eier'), 'Eier');
      expect(cookLineFood('Eine Zwiebel'), 'Zwiebel');
      expect(cookLineFood('1 Pfund Hack'), 'Hack');
      expect(cookLineFood('1 Kilo Mehl'), 'Mehl');
    });

    test('a lone word stays, even a measure word', () {
      expect(cookLineFood('Salz'), 'Salz');
      expect(cookLineFood('Prise'), 'Prise');
    });

    test('keeps the whole name when none of its words is capitalized', () {
      expect(cookLineFood('2 tbsp olive oil'), 'olive oil');
      expect(cookLineFood('200 g rote linsen'), 'rote linsen');
      expect(cookLineFood('salt'), 'salt');
    });

    test('keeps the text when only an amount is left', () {
      expect(cookLineFood(' 1 '), '1');
      expect(cookLineFood(''), '');
    });
  });

  group('cookLineFoodName', () {
    const names = {
      '1/2 TL Schwarzer Pfeffer': 'Schwarzer Pfeffer',
      '200 g Penne Rigate': 'Penne Rigate',
      '100 g Frischkäse (Doppelrahmstufe)': 'Frischkäse',
      '30 g Parmesan (gerieben)': 'Parmesan',
      '1 mittlere Zwiebel': 'Zwiebel',
      '2 Zehen Knoblauch': 'Knoblauch',
      '1 TL Oregano getrocknet': 'Oregano getrocknet',
      '1 Prise Salz': 'Salz',
      '200 g rote linsen': 'rote linsen',
      'black pepper': 'black pepper',
      'eine halbe Zitrone': 'Zitrone',
      '2 gehäufte EL Mehl': 'Mehl',
      '1 Dose gehackte Tomaten': 'Tomaten',
    };

    for (final MapEntry(key: line, value: name) in names.entries) {
      test('"$line" names "$name"', () {
        expect(cookLineFoodName(line), name);
      });
    }

    test('keeps the text when nothing is left', () {
      expect(cookLineFoodName(' 1 '), '1');
      expect(cookLineFoodName(''), '');
    });

    const cut = {
      'Öl, 30 g': 'Öl',
      'Öl, 30': 'Öl',
      'Mehl, 200 g': 'Mehl',
      'Zwiebel, fein gewürfelt': 'Zwiebel',
      'Parmesan, frisch gerieben': 'Parmesan',
      '400 g Tomaten, passiert': 'Tomaten',
      '200 g Hähnchenbrustfilet, in Streifen geschnitten': 'Hähnchenbrustfilet',
      'Öl zum Braten': 'Öl zum Braten',
      '1 cup of flour': 'flour',
      'a pinch of salt': 'salt',
      '200 g': '200 g',
      '1 Prise': '1 Prise',
      '1,5 kg Kartoffeln': 'Kartoffeln',
    };

    for (final MapEntry(key: line, value: name) in cut.entries) {
      test('ends before amount, comma and "of": "$line" names "$name"', () {
        expect(cookLineFoodName(line), name);
      });
    }

    const beforeAmount = {
      'Butter 100 g': 'Butter',
      'Butter 100g': 'Butter',
      'Mehl 200': 'Mehl',
      'eine 400 g Dose Tomaten': 'Tomaten',
      'Weizenmehl Type 405': 'Weizenmehl Type 405',
      'Wasser 1 l': 'Wasser',
    };

    for (final MapEntry(key: line, value: name) in beforeAmount.entries) {
      test('ends before a trailing amount: "$line" names "$name"', () {
        expect(cookLineFoodName(line), name);
      });
    }

    test('cookLineFood of a line with only a measure stays the line', () {
      expect(cookLineFood('1 Prise'), '1 Prise');
      expect(cookLineFood('200 g'), '200 g');
    });
  });

  group('cookLineFoodPhrase', () {
    const phrases = {
      '200 g rote Linsen, gewaschen': 'rote Linsen',
      '4 Eier (Größe M)': 'Eier',
      '1 EL Olivenöl zum Braten': 'Olivenöl zum Braten',
    };

    for (final MapEntry(key: line, value: phrase) in phrases.entries) {
      test('"$line" is "$phrase"', () {
        expect(cookLineFoodPhrase(line), phrase);
      });
    }
  });

  group('cookFoodBeforePhrase', () {
    const names = {
      'Olivenöl zum Braten': 'Olivenöl',
      'Salz und Pfeffer nach Belieben': 'Salz und Pfeffer',
      'salt to taste': 'salt',
      'Käse in Scheiben': 'Käse',
      'Zimt': 'Zimt',
      // "aus" and "from" do not cut the name.
      'Saft aus 1 Zitrone': 'Saft aus 1 Zitrone',
      'Tomaten aus der Dose': 'Tomaten aus der Dose',
      'tomatoes from a can': 'tomatoes from a can',
    };

    for (final MapEntry(key: name, value: food) in names.entries) {
      test('"$name" is "$food"', () {
        expect(cookFoodBeforePhrase(name), food);
      });
    }
  });
}
