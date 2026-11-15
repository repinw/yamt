import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/recipes/domain/cook_line_text.dart';

void main() {
  group('normalizeCookLineText', () {
    final cases = {
      'eine Zwiebel': '1 Zwiebel',
      'Eine Zwiebel': '1 Zwiebel',
      'Ein Ei': '1 Ei',
      'zwölf Eier': '12 Eier',
      'fünf Eier': '5 Eier',
      'halbe Zitrone': '1/2 Zitrone',
      'halb Zitrone': '1/2 Zitrone',
      'eine halbe Zitrone': '1/2 Zitrone',
      'anderthalb Liter Milch': '1 1/2 l Milch',
      '½ Zwiebel': '1/2 Zwiebel',
      '1½ Zwiebeln': '1 1/2 Zwiebeln',
      '1 ½ Zwiebeln': '1 1/2 Zwiebeln',
      'Milch ¼ l': 'Milch 1/4 l',
      '1 Kilo Mehl': '1 kg Mehl',
      '1 Kilos Mehl': '1 kg Mehl',
      '1kilo Mehl': '1 kg Mehl',
      '500 Milliliter Milch': '500 ml Milch',
      '1 Liter Milch': '1 l Milch',
      '1 Pfund Hack': '500 g Hack',
      '1 pfund Hack': '500 g Hack',
      '1 1/2 Pfund Hack': '750 g Hack',
      '1,250 kg Mehl': '1250 g Mehl',
      '0,250 kg Mehl': '250 g Mehl',
      '1.250 kg Mehl': '1250 g Mehl',
      '0,250 l Milch': '250 ml Milch',
      'Mehl 1,250 kg': 'Mehl 1250 g',
      '  eine Zwiebel ': '1 Zwiebel',
      'Öl, 30 g': 'Öl 30 g',
      'Öl, 30': 'Öl 30 g',
      'Öl, 2 EL': '2 EL Öl',
      'Mehl, 1,5 kg': 'Mehl 1,5 kg',
      'eine 400 g Dose Tomaten': '1 Dose Tomaten à 400 g',
      'Eine 400 g Dose Tomaten': '1 Dose Tomaten à 400 g',
      'zwei 200 g Becher Schmand': '2 Becher Schmand à 200 g',
      'eine 0,5 l Flasche Öl': '1 Flasche Öl à 0,5 l',
      'eine 400-g-Dose Tomaten': '1 Dose Tomaten à 400 g',
      'eine 400g-Dose Tomaten': '1 Dose Tomaten à 400 g',
      'zwei 400-g-Dosen Tomaten': '2 Dosen Tomaten à 400 g',
      'eine 1,250 kg Packung Mehl': '1 Packung Mehl à 1250 g',
      'ein 5 Kilo Sack Kartoffeln': '1 Sack Kartoffeln à 5 kg',
      'ein 1-Liter-Karton Milch': '1 Karton Milch à 1 l',
      'eine 1 Pfund Packung Hack': '1 Packung Hack à 500 g',
      'eine halbe 400 g Dose Tomaten': '1/2 Dose Tomaten à 400 g',
      'anderthalb 400 g Dosen Tomaten': '1 1/2 Dosen Tomaten à 400 g',
      'eine 1/2 l Flasche Öl': '1 Flasche Öl à 1/2 l',
      '2 200 g Becher Schmand': '2 Becher Schmand à 200 g',
      '1 400 g Dose Tomaten': '1 Dose Tomaten à 400 g',
      '2 400-g-Dosen Tomaten': '2 Dosen Tomaten à 400 g',
      '400-g-Dose Tomaten': '400 g Dose Tomaten',
    };
    for (final MapEntry(key: text, value: read) in cases.entries) {
      test('"$text" reads "$read"', () {
        expect(normalizeCookLineText(text), read);
      });
      test('"$text" reads the same a second time', () {
        expect(normalizeCookLineText(read), read);
      });
    }

    final same = [
      'Salz',
      'ein paar Tomaten',
      'Ein Paar Würstchen',
      'ein wenig Öl',
      'ein bisschen Salz',
      'ein kleines bisschen Salz',
      'etwas Öl',
      'Saft einer Zitrone',
      'nach Geschmack',
      'Einkorn Mehl',
      'Halbfettmargarine',
      'Pfund',
      'ein',
      'halb',
      '1 Literflasche Wasser',
      '2 Kilowatt',
      '1,250 g Mehl',
      '1,5 kg Mehl',
      '1,25 kg Mehl',
      'Tomaten, gewürfelt',
      '2 Eier, 3',
      '1 400 g Mehl',
      '1 000 g Mehl',
      '1 1/2 l Milch',
      '1 1/2 l Flasche Wasser',
      '2 Dosen Tomaten (à 400 g)',
    ];
    for (final text in same) {
      test('"$text" stays', () {
        expect(normalizeCookLineText(text), text);
      });
    }
  });

  group('cookTextIsPinch', () {
    for (final text in [
      '1 Prise Salz',
      '2 Prisen Salz',
      'eine Prise Salz',
      '1 Messerspitze Zimt',
      '2 Messerspitzen Zimt',
      '1 Msp Zimt',
      '1 Msp. Zimt',
      '1/2 Msp Zimt',
      '2 Spritzer Zitrone',
      '1 Schuss Milch',
      '3 Tropfen Öl',
      'ein guter Schuss Öl',
      'eine große Prise Zucker',
      '1 kräftige Prise Salz',
      '1 Schuß Milch',
      'ein ordentlicher Schuss Sahne',
      'eine kleine Prise Salz',
      '1 ganz kleiner Spritzer Zitrone',
    ]) {
      test('"$text" is one', () => expect(cookTextIsPinch(text), isTrue));
    }
    for (final text in [
      'Salz',
      'Prise Salz',
      '2 Tassen Reis',
      '2 Schussfeste Gläser',
      '200 g Salz',
      '1 großes Ei',
      '2 Zwiebeln in Schuss',
      '2 Eier Schuss Milch',
    ]) {
      test('"$text" is none', () => expect(cookTextIsPinch(text), isFalse));
    }
  });

  group('cookTextStartsWithCount', () {
    for (final text in [
      '2 Tassen Reis',
      '1 Becher Sahne',
      'eine Tasse Reis',
      '½ Zwiebel',
      'halbe Zwiebel',
    ]) {
      test('"$text" does', () {
        expect(cookTextStartsWithCount(text), isTrue);
      });
    }
    for (final text in [
      '1 Prise Salz',
      'Salz',
      'etwas Öl',
      'Saft einer Zitrone',
      'Saft von 2 Zitronen',
      'nach Geschmack',
      'ein paar Tomaten',
    ]) {
      test('"$text" does not', () {
        expect(cookTextStartsWithCount(text), isFalse);
      });
    }
  });

  group('cookTextScoop', () {
    final scoops = {
      'Tassen Reis': ('Tassen', 'Reis'),
      'Tasse Reis': ('Tasse', 'Reis'),
      'Kaffeetassen Mehl': ('Kaffeetassen', 'Mehl'),
      'Löffel Öl': ('Löffel', 'Öl'),
      'Eßlöffel Zucker': ('Eßlöffel', 'Zucker'),
      'Handvoll Nüsse': ('Handvoll', 'Nüsse'),
      'Hand voll Nüsse': ('Hand voll', 'Nüsse'),
      'Schöpfkelle Brühe': ('Schöpfkelle', 'Brühe'),
      'große Tasse Reis': ('große Tasse', 'Reis'),
      'gehäufte EL Mehl': ('gehäufte EL', 'Mehl'),
      'gestrichener TL Salz': ('gestrichener TL', 'Salz'),
    };
    for (final MapEntry(key: name, value: (measure, food)) in scoops.entries) {
      test('"$name" is one', () {
        expect(cookTextScoop(name), (measure: measure, food: food));
      });
    }

    for (final name in [
      'Zwiebeln',
      'Tomaten',
      'Löffelbiskuits',
      'Tassen',
      'Dose Tomaten',
      'Becher Sahne',
      'Glas Gurken',
      'Zehen Knoblauch',
      'Scheiben Brot',
      'große Zwiebel',
      'Zwiebeln in Tassen geschnitten',
    ]) {
      test('"$name" is none', () => expect(cookTextScoop(name), isNull));
    }
  });

  group('cookTextForMatch', () {
    test('a pinch looks for its food alone', () {
      expect(cookTextForMatch('1 Prise Salz'), 'Salz');
      expect(cookTextForMatch('eine Prise Salz'), 'Salz');
    });

    test('a pinch with a word between looks for its food alone', () {
      expect(cookTextForMatch('ein guter Schuss Öl'), 'Öl');
      expect(cookTextForMatch('1 Schuß Milch'), 'Milch');
    });

    test('any other line keeps its amount in digits', () {
      expect(cookTextForMatch('eine Zwiebel'), '1 Zwiebel');
      expect(cookTextForMatch('Salz'), 'Salz');
    });
  });
}
